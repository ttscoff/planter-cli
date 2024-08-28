# Planter

[![Gem](https://img.shields.io/gem/v/planter-cli.svg)](https://rubygems.org/gems/planter-cli)
[![GitHub license](https://img.shields.io/github/license/ttscoff/planter-cli.svg)](./LICENSE.txt)

<!--README-->

Plant a directory structure and files using templates.

## Installation

    gem install planter-cli

If you run into errors, try `gem install --user-install planter-cli`, or as a last ditch effort, `sudo gem install planter-cli`.

### Optional

If [Gum](https://github.com/charmbracelet/gum) is available it will be used for command line input.

## Configuration

Planter's base configuration is in `~/.config/planter/config.yml`. This file can contain any of the keys used in templates (see below) and will serve as a base configuration for all templates. Any key defined in this file will be overridden if it exists in a template.

### Scripts.

Scripts for execution after planting can be stored in `~/.config/planter/scripts` and referenced by filename only. Alternatively, scripts may be stored within a template in a `_scritps` subfolder.

Scripts can be executable files in any language, and receive the template directory and the planted directory as arguments $1 and $2.

### Templates

Templates are directories found in `~/.config/planter/templates/[TEMPLATE_NAME]`. All files and directories inside of these template directories are copied when that template is called. Filenames, directory names, and file contents can all use template placeholders.

Template placeholders are defined with `%%KEY%%`, where key is the key defined in the `variables` section of the configuration. %%KEY%% placeholders can be used in directory/file names, and in the file contents. These work in any plain text or RTF format document, including XML, so they can be used in things like Scrivener templates and MindNode files as well.

Each template contains a `_planter.yml` file that defines variables and other configuration options. The file format for all configuration files is [YAML](https://yaml.org/spec/1.2.2/).

First, there's a `variables` section that defines variables used in the template. It's an array of dictionaries, each dictionary defining one variable. The required fields are `key` (the key used to insert the variable) and `prompt` (the text provided on the command line when asking for the variable). The rest are optional:

```yaml
variables:
  - key: var_key
    prompt: Prompt text
    type: string # [string,float,integer,number,date]
    value: (for date type can be today, time, now, etc.)
    default: Untitled
    min: 1
    max: 5
script: # array of scripts, args passed TEMPLATE_DIR PWD
  - process.py
git_init: false # if true, initialize a git repository in the newly-planted directory
files: # Dictionary for file handling (see documentation)
replacements: # Dictionary of pattern/replacments for regex substitution
repo: # If a repository URL is provided, it will be pulled and duplicated instead of copying a file structure
```

### File-specific handling

A `files` dictionary can specify how to handle specific files. Options are `copy`, `overwrite`, `merge`, or `ask`. The key for each entry is a filename or glob that matches the source filename (accounting for template variables if applicable):

```yaml
files:
  "*.py": merge
  "%%title%%.md": overwrite
```

If `merge` is specified, then the source file is scanned for merge comments and those are merged if they don't exist in the copied/existing file. If no merge comments are defined, then the entire contents of the source file are appended to the destination file (unless the file already matches the source). Merge comments start with `merge` and end with `/merge` and can have any comment syntax preceding them, for example:

```
// merge
Merged content
// /merge
```

By default files that already exist in the destination directory are not overwritten, and merging allows you to add missing parts to a Rakefile or Makefile, for example.

If `ask` is specified, a memu will be provided on the command line asking how to handle a file. If the file doesn't already exist, you will be asked only whether to copy the file or not. If it does exist, `overwrite` and `merge` options will be added.

### Regex replacements

In addition to manually-placed template variables, you can also specify regular expressions for replacement. The `replacements` dictionary is a set of key/value pairs with the regex pattern as the key, and the replacement as the value. Both should be quoted in almost all circumstances.

```yaml
replacements:
  "Planter": "%%title:cap%%"
  "(main|app)\.js": "%%script:lower%%.js"
```

Replacements are performed on both file/directory names and file contents.

## Usage

The executable for Planter is `plant`. You can run `plant TEMPLATE` in any directory and TEMPLATE will be planted in the current directory. You can also use `--in PATH` to plant in another directory.

```
Usage: planter [options] TEMPLATE
    --defaults                   Accept default values for all variables
    -i, --in TARGET                  Plant in TARGET instead of current directory
    -o, --overwrite                  Overwrite existing files
    -k, --var=KEY:VALUE,KEY:VALUE... Pass a variable on the command line as KEY:VALUE pairs. Can be used multiple times.
    -d, --debug                      Display version number
    -h, --help                       Display this screen, or list variables for template argument
    -v, --version                    Display version number
```

Files will be copied, but existing files will not be overwritten unless otherwise noted in the `files` configuration for the template.

Some directories like `.git` and files like `_planter.yml` are automatically ignored. If you want to create a git repository, include the `git_init: true` key in config.

When `plant` is run, any defined variables will be requested on the command line using the defined prompt. If a `default` key is specified, hitting return at the prompt will accept the default value.

Variables can be passed on the command line with `--var KEY:VALUE`. This flag can contain a comma-separated list, e.g. `--var KEY:VALUE,KEY:VALUE` or used multiple times in the same command. Variables passed on the command line will not be prompted for when processing variables.

<!--GITHUB-->

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
rake build                              # Build planter-cli-0.0.3.gem into the...
rake build:checksum                     # Generate SHA512 checksum of planter-...
rake bump:current[no_args]              # Show current gem version
rake bump:file[no_args]                 # Show version file path
rake bump:major[no_args]                # Bump major part of gem version
rake bump:minor[no_args]                # Bump minor part of gem version
rake bump:patch[no_args]                # Bump patch part of gem version
rake bump:pre[no_args]                  # Bump pre part of gem version
rake bump:set                           # Sets the version number using the VE...
rake bump:show-next[no_args]            # Show next major|minor|patch|pre version
rake clean                              # Remove any temporary products
rake clobber                            # Remove any generated files / Clobber...
rake clobber_packages                   # Remove packages
rake cver                               # Changelog version check
rake dockertest[version,login,attempt]  # Run tests in Docker
rake install                            # Build and install planter-cli-0.0.3....
rake install:local                      # Build and install planter-cli-0.0.3....
rake package                            # alias for build
rake release[remote]                    # Create tag v0.0.3 and build and push...
rake rubocop                            # Run RuboCop
rake rubocop:autocorrect                # Autocorrect RuboCop offenses (only w...
rake rubocop:autocorrect_all            # Autocorrect RuboCop offenses (safe a...
rake spec                               # Run RSpec code examples
rake test                               # Run test suite
rake ver                                # Development version check
rake yard                               # Generate YARD Documentation
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

<!--END GITHUB-->
<!--END README-->
