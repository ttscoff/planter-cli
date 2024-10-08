# frozen_string_literal: true

module Planter
  ## Error handlers
  module Errors
    ## Exit codes
    EXIT_CODES = {
      argument: 12,
      canceled: 1,
      script: 10,
      config: 127,
      git: 129
    }.deep_freeze

    ## Argument error class
    class InputError < StandardError
      def initialize(msg = nil)
        msg = msg ? "Input: #{msg}" : 'Canceled'

        Planter.notify(msg, :error, exit_code: EXIT_CODES[:canceled])

        super(msg)
      end
    end

    ## Argument error class
    class ArgumentError < StandardError
      def initialize(msg = nil)
        msg = msg ? "Argument error: #{msg}" : 'Argument error'

        Planter.notify(msg, :error, exit_code: EXIT_CODES[:argument])

        super(msg)
      end
    end

    ## Git error class
    class GitError < StandardError
      def initialize(msg = nil)
        msg = msg ? "Git: #{msg}" : 'Git error'

        Planter.spinner.error('(Error)')
        Planter.notify(msg, :error, exit_code: EXIT_CODES[:git])

        super(msg)
      end
    end

    # Configuration error class
    class ConfigError < StandardError
      def initialize(msg = nil)
        msg = msg ? "Config: #{msg}" : 'Configuration error'
        Planter.spinner.error('(Error)')
        Planter.notify(msg, :error, exit_code: EXIT_CODES[:config])

        super(msg)
      end
    end

    #
    # Script error
    #
    class ScriptError < StandardError
      def initialize(msg = nil)
        msg = msg ? "Script: #{msg}" : 'Script error'
        Planter.spinner.error('(Error)')
        Planter.notify(msg, :error, exit_code: EXIT_CODES[:script])

        super(msg)
      end
    end
  end
end
