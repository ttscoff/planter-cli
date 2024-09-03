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
# require 'tty-spinner'
require 'tty-which'

require_relative 'tty-spinner/lib/tty-spinner'
require_relative 'planter/config'
require_relative 'planter/version'
require_relative 'planter/hash'
require_relative 'planter/array'
require_relative 'planter/symbol'
require_relative 'planter/file'
require_relative 'planter/tag'
require_relative 'planter/color'
require_relative 'planter/prompt'
require_relative 'planter/string'
require_relative 'planter/filelist'
require_relative 'planter/fileentry'
require_relative 'planter/script'
require_relative 'planter/plant'

# @return [Integer] Exit codes
EXIT_CODES = {
  argument: 12,
  input: 13,
  canceled: 1,
  script: 10,
  config: 127,
  git: 129
}.deep_freeze

#
# Exit the program with a message
#
# @param msg [String] error message
# @param level [Symbol] notification level
# @param code [Integer] Exit code
#
def die(msg = 'Exited', code = :canceled)
  code = EXIT_CODES.key?(code) ? code : :canceled
  Planter.notify(msg, :error, above_spinner: false, exit_code: EXIT_CODES[code])
end

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
    # attr_reader :config

    ## Variable key/values
    attr_accessor :variables

    ## Filter patterns
    attr_writer :patterns

    ## Accept all defaults
    attr_accessor :accept_defaults

    def config
      @config ||= Config.new
    end

    ##
    ## Print a message on the command line
    ##
    ## @param      string             [String] The message string
    ## @param      notification_type  [Symbol] The notification type (:debug, :error, :warn, :info)
    ## @param      exit_code          [Integer] If provided, exit with code after delivering message
    ## @param      newline            [Boolean] If true, add a newline to the message
    ## @param      above_spinner      [Boolean] If true, print above the spinner
    ##
    ## @return     [Boolean] true if message was printed
    def notify(string, notification_type = :info, newline: true, above_spinner: false, exit_code: nil)
      color = case notification_type
              when :debug
                return false unless @debug

                '{dw}'
              when :error
                '{br}'

              when :warn
                '{by}'
              else
                '{bw}'
              end
      out = "#{color}#{string}{x}"
      out = out.gsub(/\[(.*?)\]/, "{by}\\1{x}#{color}")
      out = "\n#{out}" if newline

      spinner.update(title: 'ERROR') if exit_code
      spinner.error if notification_type == :error

      above_spinner ? spinner.log(out.x) : warn(out.x)

      exit(exit_code) if exit_code && !ENV['PLANTER_IRB']

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
    ## Process :files in config into regex pattern/operator pairs
    ##
    ## @return     [Hash] { regex => operator } hash
    ##
    ## @api private
    ##
    def process_patterns
      patterns = {}
      @config.files.each do |file, oper|
        pattern = Regexp.new(".*?/#{file.to_s.sub(%r{^/}, '').to_rx}$")
        operator = oper.normalize_operator
        patterns[pattern] = operator
      end
      patterns
    end
  end
end
