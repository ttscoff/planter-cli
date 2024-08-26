#!/usr/bin/env ruby
require 'tty-spinner'
require 'pastel'
require 'fileutils'

unless system('rake spec')
  puts "Tests failed, exiting"
  Process.exit 1
end

pastel = Pastel.new
format = "[#{pastel.yellow(':spinner')}] " + pastel.white("Release Gem")
spinners = TTY::Spinner::Multi.new(format, format: :dots, success_mark: pastel.green('✔'), error_mark: pastel.red('✖'))
sp_v = spinners.register "[#{pastel.cyan(':spinner')}] :msg"
sp_d = spinners.register "[#{pastel.cyan(':spinner')}] Generate docs"
spinners.auto_spin

$version = nil
sp_v.update(msg: 'Get version')

def get_version
  versions = `rake ver`.strip
  version = versions.match(/version\.rb: ([\d.]+(\w+\d*)?)/)[1]
  changelog_version = versions.match(/changelog: ([\d.]+(\w+\d*)?)/)[1]
  git_version = versions.match(/git tag: ([\d.]+(\w+\d*)?)/)[1]
  [version, git_version, changelog_version]
end

sp_v.run do |spinner|
  spinner.update(msg: 'Getting version')
  version, git_version, changelog_version = get_version

  if git_version == version
    `rake bump:patch &> results.log`
  end

  version, git_version, changelog_version = get_version

  unless version == changelog_version
    `changelog -u &> results.log`
  end

  version, git_version, changelog_version = get_version

  unless version == changelog_version
    spinner.update(msg: "Version mismatch, please correct")
    spinner.error
    spinner.stop
    Process.exit
  end

  $version = version

  spinner.update(msg: "Version #{version}")
  spinner.success
end

sp_d.auto_spin
`rake yard &> results.log`
sp_d.success

sp_r = spinners.register "[:spinner] Releasing gem :msg"

sp_r.run do |spinner|
  spinner.update(msg: '- Preparing git release')
  `git ar &> results.log`
  `git commit -a -m "#{$version} release prep" &> results.log`
  `git pull &> results.log`
  `FORCE_PUSH=true git push &> results.log`
  spinner.update(msg: '- Running rake release')

  status = `changelog > current_changes.md; echo $?`

  version, git_version, changelog_version = get_version

  if status.to_i == 0
    puts `gh release create #{version} -t "v#{version}" -F current_changes.md`
    `git pull`
  end

  # Push a gem
  `rake clobber build`
  `gem push pkg/planter-#{version}.gem`

  new_ver = `rake bump:patch`
  puts `git commit -a -m "Version bump #{new_ver}"`

  `git checkout main &> results.log`
  `git merge develop &> results.log`
  `rake release &> results.log`
  spinner.update(msg: '- Cleaning up')
  `git checkout develop &> results.log`
  `git rebase main &> results.log`
  sp_r.success
end

FileUtils.rm('results.log')
