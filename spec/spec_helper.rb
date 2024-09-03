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

require 'open3'
require 'time'

module PlanterHelpers
  PLANTER_EXEC = File.join(File.dirname(__FILE__), '..', 'bin', 'plant')

  def planter_with_env(env, *args, stdin: nil)
    pread(env, 'bundle', 'exec', PLANTER_EXEC, "--base-dir=#{File.dirname(__FILE__)}", "--defaults", *args,
          stdin: stdin)
  end

  def pread(env, *cmd, stdin: nil)
    out, err, status = Open3.capture3(env, *cmd, stdin_data: stdin)
    unless status.success?
      raise [
        "Error (#{status}): #{cmd.inspect} failed", "STDOUT:", out.inspect, "STDERR:", err.inspect
      ].join("\n")
    end

    [out, err, status]
  end

  def planter(*args, stdin: nil)
    planter_with_env({}, *args, stdin: stdin)
  end
end
