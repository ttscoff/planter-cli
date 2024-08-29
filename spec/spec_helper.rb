require 'simplecov'
require 'cli-test'
require 'fileutils'

SimpleCov.start

if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
else
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
end

require 'planter'

RSpec.configure do |c|
  c.expect_with(:rspec) { |e| e.syntax = :expect }
  c.before do
    ENV["RUBYOPT"] = '-W1'
    ENV['PLANTER_DEBUG'] = 'true'
    Planter.base_dir = File.expand_path('spec')
    allow(FileUtils).to receive(:remove_entry_secure).with(anything)
    allow(FileUtils).to receive(:mkdir_p).with(anything)
  end
  c.add_formatter 'd'
end
