# frozen_string_literal: true

module Planter
  module Errors
    EXIT_CODES = {
      config: 127,
      git: 129
    }.deep_freeze

    ## Git error class
    class GitPullError < StandardError
      def initialize(msg = nil)
        msg = msg ? "Git pull: #{msg}" : 'Git pull error'
        Planter.notify(msg, :error, exit_code: 129)

        # super(msg)
      end
    end

    class ConfigError < StandardError
      def initialize(msg = nil)
        msg = msg ? "Config: #{msg}" : 'Configuration error'
        Planter.notify(msg, :error, exit_code: EXIT_CODES[:git])
      end
    end
  end
end
