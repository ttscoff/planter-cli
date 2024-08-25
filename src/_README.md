# Planter

[![Gem](https://img.shields.io/gem/v/planter-cli.svg)](https://rubygems.org/gems/planter-cli)
[![GitHub license](https://img.shields.io/github/license/ttscoff/planter-cli.svg)](./LICENSE.txt)

<!--README-->

Plant a file and directory structure using templates.

## Installation

## Configuration

scripts in planter/scripts or in TEMPLATE_NAME/\_scripts

- variables used in templates
  # - key: var
  # prompt: Variable
  # type: [string,float,integer,number,date]
  # value: (for date type can be today, time, now, etc.)
  # default: Untitled
  # min: 1
  # max: 5
- scripts
- git

### Templates

Directories and files in ~/.config/planter/templates/TEMPLATE_NAME

Use %%key%% in filenames, path names, and in text. Works in text files, RTF files, and any document that stores its values in plain text (like source code or XML) or Apple Binary Plist (like MindNode).

## Usage

- run in any directory
- files will not be overwritten
- git initted only if .git doesn't exist
- pass variables on the command line

<!--END README-->

## Documentation

- [YARD documentation][RubyDoc] is hosted by RubyDoc.info.
- [Interactive documentation][Omniref] is hosted by Omniref.

[RubyDoc]: http://www.rubydoc.info/gems/planter-cli

## Development and Testing

### Source Code

The [planter-cli source] is hosted on GitHub.

Clone the project with

```
$ git clone https://github.com/ttscoff/planter-cli.git
```

[planter-cli source]: https://github.com/ttscoff/planter-cli

### Requirements

You will need [Ruby] with [Bundler].

Install the development dependencies with

```
$ bundle
```

[Bundler]: http://bundler.io/
[Ruby]: https://www.ruby-lang.org/

### Rake

Run `$ rake -T` to see all Rake tasks.

```
rake build                 # Build planter-cli-2.0.1.gem into the pkg directory
rake bump:current[tag]     # Show current gem version
rake bump:major[tag]       # Bump major part of gem version
rake bump:minor[tag]       # Bump minor part of gem version
rake bump:patch[tag]       # Bump patch part of gem version
rake bump:pre[tag]         # Bump pre part of gem version
rake bump:set              # Sets the version number using the VERSION environment variable
rake clean                 # Remove any temporary products
rake clobber               # Remove any generated files
rake install               # Build and install planter-cli-2.0.1.gem into system gems
rake install:local         # Build and install planter-cli-2.0.1.gem into system gems without network access
rake release[remote]       # Create tag v2.0.1 and build and push planter-cli-2.0.1.gem to Rubygems
rake rubocop               # Run RuboCop
rake rubocop:auto_correct  # Auto-correct RuboCop offenses
rake spec                  # Run RSpec code examples
rake test                  # Run test suite
rake yard                  # Generate YARD Documentation
```

### Guard

Guard tasks have been separated into the following groups:
`doc`, `lint`, and `unit`.
By default, `$ guard` will generate documentation, lint, and run unit tests.

## Contributing

Please submit and comment on bug reports and feature requests.

To submit a patch:

1. Fork it (https://github.com/ttscoff/planter-cli/fork).
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Make changes. Write and run tests.
4. Commit your changes (`git commit -am 'Add some feature'`).
5. Push to the branch (`git push origin my-new-feature`).
6. Create a new Pull Request.

## License

This Ruby gem is licensed under the MIT license.

## Warranty

This software is provided "as is" and without any express or
implied warranties, including, without limitation, the implied
warranties of merchantibility and fitness for a particular
purpose.
