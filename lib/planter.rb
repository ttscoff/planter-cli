# frozen_string_literal: true

require 'time'
require 'shellwords'
require 'json'
require 'yaml'
require 'chronic'
require 'fileutils'
require 'open3'
require 'english'

require 'tty-which'
require 'tty-reader'
require 'tty-screen'
require 'tty-spinner'

require_relative 'planter/version'
require_relative 'planter/hash'
require_relative 'planter/array'
require_relative 'planter/symbol'
require_relative 'planter/file'
require_relative 'planter/color'
require_relative 'planter/errors'
require_relative 'planter/prompt'
require_relative 'planter/string'
require_relative 'planter/filelist'
require_relative 'planter/fileentry'
require_relative 'planter/plant'

# Main Journal module
module Planter
  # Base directory for templates
  BASE_DIR = File.expand_path('~/.config/planter/templates/')

  class << self
    include Color
    include Prompt

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
        warn "\n{dw}#{string}{x}".x if @debug
      when :error
        warn "{br}#{string}{x}".x
      when :warn
        warn "{by}#{string}{x}".x
      else
        warn "{bw}#{string}{x}".x
      end

      Process.exit exit_code unless exit_code.nil?
    end

    def spinner
      @spinner ||= TTY::Spinner.new('{bw}[{by}:spinner{bw}] {w}:title'.x,
                                    hide_cursor: true,
                                    format: :dots,
                                    success_mark: '{bg}✔{x}'.x,
                                    error_mark: '{br}✖{x}'.x)
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
      base_config = File.join(BASE_DIR, 'config.yml')

      unless File.exist?(base_config)
        default_base_config = {
          defaults: false,
          git_init: false,
          files: { '_config.yml' => 'ignore' },
          color: true
        }
        File.open(base_config, 'w') { |f| f.puts(YAML.dump(default_base_config.stringify_keys)) }
        puts "New configuration written to #{config}, edit as needed."
      end

      @config = YAML.load(IO.read(base_config)).symbolize_keys

      base_dir = File.join(BASE_DIR, @template)
      unless File.directory?(base_dir)
        notify("Template #{@template} does not exist", :error)
        res = yn('Create template directory', default_response: false)

        Planter.notify('Cancelled', :error, exit_code: 13) unless res

        FileUtils.mkdir_p(base_dir)
      end

      load_template_config

      config_array_to_hash(:files) if @config[:files].is_a?(Array)
      config_array_to_hash(:replacements) if @config[:replacements].is_a?(Array)
    rescue Psych::SyntaxError => e
      raise Errors::ConfigError.new "Parse error in configuration file:\n#{e.message}"
    end

    def load_template_config
      base_dir = File.join(BASE_DIR, @template)
      config = File.join(base_dir, '_config.yml')

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
        File.open(config, 'w') { |f| f.puts(YAML.dump(default_config.stringify_keys)) }
        puts "New configuration written to #{config}, please edit."
        Process.exit 0
      end
      @config = @config.deep_merge(YAML.load(IO.read(config)).symbolize_keys)
    end

    def config_array_to_hash(key)
      files = {}
      @config[key].each do |k, v|
        files[k] = v
      end
      @config[key] = files
    end

    def patterns
      @patterns ||= process_patterns
    end

    ##
    ## Process :files in config into regex pattern/operator pairs
    ##
    ## @return     [Hash] { regex => operator } hash
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

    ##
    ## Execute a shell command and return a Boolean success response
    ##
    ## @param      cmd   [String] The shell command
    ##
    def pass_fail(cmd)
      _, status = Open3.capture2("#{cmd} &> /dev/null")
      status.exitstatus.zero?
    end
  end
end
