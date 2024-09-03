# frozen_string_literal: true
IRB.conf[:AUTO_INDENT] = true

require "irb/completion"
require_relative "lib/planter"
ENV['RUBYOPT'] = "-W1"
ENV['PLANTER_IRB'] = "true"
# rubocop:disable Style/MixinUsage
include Planter # standard:disable all
# rubocop:enable Style/MixinUsage

require "awesome_print"
AwesomePrint.irb!
