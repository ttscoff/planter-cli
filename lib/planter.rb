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
require_relative 'planter/color'
require_relative 'planter/hash'
require_relative 'planter/prompt'
require_relative 'planter/string'
require_relative 'planter/symbol'
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

    ## Accept defaults
    attr_accessor :defaults

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
        warn "{dw}#{string}{x}".x if @debug
      when :error
        warn "{br}#{string}{x}".x
      when :warn
        warn "{by}#{string}{x}".x
      else
        warn "{bw}#{string}{x}".x
      end

      Process.exit exit_code unless exit_code.nil?
    end

    ##
    ## Build a configuration from template name
    ##
    ## @param      template  [String] The template name
    ##
    ## @return     [Hash] Configuration object
    ##
    def config=(template)
      Planter.variables ||= {}
      base_dir = File.join(BASE_DIR, template)
      unless File.directory?(base_dir)
        notify("Template #{template} does not exist", :error)
        res = yn('Create template directory', default_response: false)

        Planter.notify('Cancelled', :error, exit_code: 13) unless res

        FileUtils.mkdir_p(base_dir)
      end

      @template = template

      config = File.join(base_dir, 'config.yml')

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
          git: false
        }
        File.open(config, 'w') { |f| f.puts(YAML.dump(default_config.stringify_keys)) }
        puts "New configuration written to #{config}, please edit."
        Process.exit 0
      end
      @config = YAML.load(IO.read(config)).symbolize_keys
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
