# frozen_string_literal: true

module Planter
  module Errors
    ## Git error class
    class GitPullError < StandardError
      def initialize(msg = nil)
        msg = msg ? "Git pull: #{msg}" : 'Git pull error'
        # Planter.notify(msg, :error, exit_code: 129)

        super(msg)
      end
    end
  end
end
