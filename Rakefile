# frozen_string_literal: true

require 'bump/tasks'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'
require 'tty-spinner'

## Docker error class
class DockerError < StandardError
  def initialize(msg = nil)
    msg = msg ? "Docker error: #{msg}" : 'Docker error'
    super(msg)
  end
end

task default: %i[test yard]

desc 'Run test suite'
task test: %i[rubocop spec]

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = '--format documentation'
end

RuboCop::RakeTask.new do |t|
  t.formatters = ['progress']
end

YARD::Rake::YardocTask.new

desc 'Remove packages'
task :clobber_packages do
  FileUtils.rm_f 'pkg/*'
end
# Make a prerequisite of the preexisting clobber task
desc 'Clobber files'
task clobber: :clobber_packages

desc 'Development version check'
task :ver do
  gver = `git ver`
  cver = IO.read(File.join(File.dirname(__FILE__), 'CHANGELOG.md')).match(/^#+ (\d+\.\d+\.\d+(\w+)?)/)[1]
  res = `grep VERSION lib/planter/version.rb`
  version = res.match(/VERSION *= *['"](\d+\.\d+\.\d+([-\w]+)?)/)[1]
  puts "git tag: #{gver}"
  puts "version.rb: #{version}"
  puts "changelog: #{cver}"
end

desc 'Get Script Version'
task :sver do
  res = `grep VERSION lib/planter/version.rb`
  version = res.match(/VERSION *= *['"](\d+\.\d+\.\d+(\w+)?)/)[1]
  print version
end

desc 'Changelog version check'
task :cver do
  puts IO.read(File.join(File.dirname(__FILE__), 'CHANGELOG.md')).match(/^#+ (\d+\.\d+\.\d+(\w+)?)/)[1]
end

desc 'Run tests in Docker'
task :dockertest, :version, :login, :attempt do |_, args|
  args.with_defaults(version: 'all', login: false, attempt: 1)
  `open -a Docker`

  Rake::Task['clobber'].reenable
  Rake::Task['clobber'].invoke
  Rake::Task['build'].reenable
  Rake::Task['build'].invoke

  case args[:version]
  when /^a/
    %w[6 7 3].each do |v|
      Rake::Task['dockertest'].reenable
      Rake::Task['dockertest'].invoke(v, false)
    end
    Process.exit 0
  when /^3/
    version = '3.0'
    img = 'plantertest3'
    file = 'docker/Dockerfile-3.0'
  when /6$/
    version = '2.6'
    img = 'plantertest26'
    file = 'docker/Dockerfile-2.6'
  when /(^2|7$)/
    version = '2.7'
    img = 'plantertest27'
    file = 'docker/Dockerfile-2.7'
  else
    version = '3.0.1'
    img = 'plantertest'
    file = 'docker/Dockerfile'
  end

  puts `docker build . --file #{file} -t #{img}`

  raise DockerError.new('Error building docker image') unless $?.success?

  dirs = {
    File.dirname(__FILE__) => '/planter',
    File.expand_path('~/.config') => '/root/.config'
  }
  dir_args = dirs.map { |s, d| " -v '#{s}:#{d}'" }.join(' ')
  exec "docker run #{dir_args} -it #{img} /bin/bash -l" if args[:login]

  spinner = TTY::Spinner.new("[:spinner] Running tests (#{version})...", hide_cursor: true)

  spinner.auto_spin
  `docker run --rm #{dir_args} -it #{img}`
  # raise DockerError.new('Error running docker image') unless $?.success?

  # commit = puts `bash -c "docker commit $(docker ps -a|grep #{img}|awk '{print $1}'|head -n 1) #{img}"`.strip
  $?.success? ? spinner.success : spinner.error
  spinner.stop

  # puts res
  # puts commit&.empty? ? "Error commiting Docker tag #{img}" : "Committed Docker tag #{img}"
rescue DockerError
  raise StandardError.new('Docker not responding') if args[:attempt] > 3

  `open -a Docker`
  sleep 3
  Rake::Task['dockertest'].reenable
  Rake::Task['dockertest'].invoke(args[:version], args[:login], args[:attempt] + 1)
end

desc 'alias for build'
task package: :build
