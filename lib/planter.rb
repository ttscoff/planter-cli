# frozen_string_literal: true

require 'time'
require 'shellwords'
require 'json'
require 'yaml'
require 'fileutils'
require 'open3'
require 'plist'

require 'chronic'
require 'tty-reader'
require 'tty-screen'
require 'tty-spinner'
require 'tty-which'

require_relative 'planter/version'
require_relative 'planter/hash'
require_relative 'planter/array'
require_relative 'planter/symbol'
require_relative 'planter/file'
require_relative 'planter/tag'
require_relative 'planter/color'
require_relative 'planter/errors'
require_relative 'planter/prompt'
require_relative 'planter/string'
require_relative 'planter/filelist'
require_relative 'planter/fileentry'
require_relative 'planter/script'
require_relative 'planter/plant'

# Main Journal module
module Planter
  # Base directory for templates
  class << self
    include Color
    include Prompt

    ## Base directory for templates
    attr_writer :base_dir

    ## Debug mode
    attr_accessor :debug

    ## Target
    attr_accessor :target

    ## Overwrite files
    attr_accessor :overwrite

    ## Current date
    attr_accessor :date

    ## Template name
    attr_accessor :template

    ## Config Hash
    attr_reader :config

    ## Variable key/values
    attr_accessor :variables

    ## Filter patterns
    attr_writer :patterns

    ## Accept all defaults
    attr_accessor :accept_defaults

    ##
    ## Print a message on the command line
    ##
    ## @param      string             [String] The message string
    ## @param      notification_type  [Symbol] The notification type (:debug, :error, :warn, :info)
    ## @param      exit_code          [Integer] If provided, exit with code after delivering message
    ##
    def notify(string, notification_type = :info, exit_code: nil)
      case notification_type
      when :debug
        return false unless @debug

        warn "\n{dw}#{string}{x}".x
      when :error
        warn "{br}#{string}{x}".x
      when :warn
        warn "{by}#{string}{x}".x
      else
        warn "{bw}#{string}{x}".x
      end

      Process.exit exit_code unless exit_code.nil?

      true
    end

    ##
    ## Global progress indicator reader, will init if nil
    ##
    ## @return     [TTY::Spinner] Spinner object
    ##
    def spinner
      @spinner ||= TTY::Spinner.new('{bw}[{by}:spinner{bw}] {w}:title'.x,
                                    hide_cursor: true,
                                    format: :dots,
                                    success_mark: '{bg}✔{x}'.x,
                                    error_mark: '{br}✖{x}'.x)
    end

    def base_dir
      @base_dir ||= ENV['PLANTER_BASE_DIR'] || File.join(Dir.home, '.config', 'planter')
    end

    ##
    ## Build a configuration from template name
    ##
    ## @param      template  [String] The template name
    ##
    ## @return     [Hash] Configuration object
    ##
    def config=(template)
      @template = template
      Planter.variables ||= {}
      FileUtils.mkdir_p(Planter.base_dir) unless File.directory?(Planter.base_dir)
      base_config = File.join(Planter.base_dir, 'planter.yml')

      if File.exist?(base_config)
        @config = YAML.load(IO.read(base_config)).symbolize_keys
      else
        default_base_config = {
          defaults: false,
          git_init: false,
          files: { '_planter.yml' => 'ignore' },
          color: true,
          preserve_tags: true
        }
        begin
          File.open(base_config, 'w') { |f| f.puts(YAML.dump(default_base_config.stringify_keys)) }
        rescue Errno::ENOENT
          Planter.notify("Unable to create #{base_config}", :error)
        end
        @config = default_base_config.symbolize_keys
        Planter.notify("New configuration written to #{base_config}, edit as needed.", :warn)
      end

      base_dir = File.join(Planter.base_dir, 'templates', @template)
      unless File.directory?(base_dir)
        notify("Template #{@template} does not exist", :error)
        res = Prompt.yn('Create template directory', default_response: false)

        raise Errors::InputError.new('Canceled') unless res

        FileUtils.mkdir_p(base_dir)
      end

      load_template_config

      config_array_to_hash(:files) if @config[:files].is_a?(Array)
      config_array_to_hash(:replacements) if @config[:replacements].is_a?(Array)
    rescue Psych::SyntaxError => e
      raise Errors::ConfigError.new "Parse error in configuration file:\n#{e.message}"
    end

    ##
    ## Execute a shell command and return a Boolean success response
    ##
    ## @param      cmd   [String] The shell command
    ##
    def pass_fail(cmd)
      _, status = Open3.capture2("#{cmd} &> /dev/null")
      status.exitstatus.zero?
    end

    ##
    ## Patterns reader, file handling config
    ##
    ## @return     [Hash] hash of file patterns
    ##
    def patterns
      @patterns ||= process_patterns
    end

    private

    ##
    ## Load a template-specific configuration
    ##
    ## @return     [Hash] updated config object
    ##
    ## @api private
    ##
    def load_template_config
      base_dir = File.join(Planter.base_dir, 'templates', @template)
      config = File.join(base_dir, '_planter.yml')

      unless File.exist?(config)
        default_config = {
          variables: [
            key: 'var_key',
            prompt: 'CLI Prompt',
            type: '[string, float, integer, number, date]',
            value: '(optional, for date type can be today, time, now, etc., empty to prompt)',
            default: '(optional default value, leave empty or remove key for no default)',
            min: '(optional, for number type set a minimum value)',
            max: '(optional, for number type set a maximum value)'
          ],
          git_init: false,
          files: { '*.tmp' => 'ignore' }
        }
        FileUtils.mkdir_p(base_dir)
        File.open(config, 'w') { |f| f.puts(YAML.dump(default_config.stringify_keys)) }
        notify("New configuration written to #{config}, please edit.", :warn)
        Process.exit 0
      end
      @config = @config.deep_merge(YAML.load(IO.read(config)).symbolize_keys)
    end

    ##
    ## Convert an errant array to a hash
    ##
    ## @param      key   [Symbol] The key in @config to convert
    ##
    ## @api private
    ##
    def config_array_to_hash(key)
      files = {}
      @config[key].each do |k, v|
        files[k] = v
      end
      @config[key] = files
    end

    ##
    ## Process :files in config into regex pattern/operator pairs
    ##
    ## @return     [Hash] { regex => operator } hash
    ##
    ## @api private
    ##
    def process_patterns
      patterns = {}
      @config[:files].each do |file, oper|
        pattern = Regexp.new(".*?/#{file.to_s.sub(%r{^/}, '').gsub(/\./, '\.').gsub(/\*/, '.*?').gsub(/\?/, '.')}$")
        operator = oper.normalize_operator
        patterns[pattern] = operator
      end
      patterns
    end
  end
end
