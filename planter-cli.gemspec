lib = File.expand_path(File.join('..', 'lib'), __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'planter/version'

Gem::Specification.new do |spec|
  spec.name          = 'planter-cli'
  spec.version       = Planter::VERSION
  spec.authors       = ['Brett Terpstra']
  spec.email         = ['me@brettterpstra.com']
  spec.description   = 'Plant a file and directory structure'
  spec.summary       = 'Plant files and directories using templates'
  spec.homepage      = 'https://github.com/ttscoff/planter-cli'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(features|spec|test)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.1'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 11.2'
  spec.add_development_dependency 'bump', '~> 0.5'

  spec.add_development_dependency 'guard', '~> 2.11'
  spec.add_development_dependency 'guard-yard', '~> 2.1'
  spec.add_development_dependency 'guard-rubocop', '~> 1.2'
  spec.add_development_dependency 'guard-rspec', '~> 4.5'

  spec.add_development_dependency 'rubocop', '~> 0.28'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'simplecov', '~> 0.9'
  spec.add_development_dependency 'codecov', '~> 0.1'
  spec.add_development_dependency 'fuubar', '~> 2.0'

  spec.add_development_dependency 'yard', '~> 0.9.5'
  spec.add_development_dependency 'redcarpet', '~> 3.2'
  spec.add_development_dependency 'github-markup', '~> 1.3'
end
