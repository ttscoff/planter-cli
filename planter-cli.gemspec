# frozen_string_literal: true

lib = File.expand_path(File.join('..', 'lib'), __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'planter/version'

Gem::Specification.new do |spec|
  spec.name = 'planter-cli'
  spec.version = Planter::VERSION
  spec.authors = ['Brett Terpstra']
  spec.email = ['me@brettterpstra.com']
  spec.description = 'Plant a file and directory structure'
  spec.summary = 'Plant files and directories using templates'
  spec.homepage = 'https://github.com/ttscoff/planter-cli'
  spec.license = 'MIT'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_dependency 'chronic', '~> 0.10'
  spec.add_dependency 'plist', '~> 3.7.1'
  spec.add_dependency 'psych', '~> 5.2.1'
  spec.add_dependency 'stringio', '~> 3.1.2'
  spec.add_dependency 'tty-reader', '~> 0.9'
  spec.add_dependency 'tty-screen', '~> 0.8'
  spec.add_dependency 'tty-spinner', '~> 0.9'
  spec.add_dependency 'tty-which', '~> 0.5'
end
