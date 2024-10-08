# Planter

[![Gem](https://img.shields.io/gem/v/planter-cli.svg)](https://rubygems.org/gems/planter-cli)
[![GitHub license](https://img.shields.io/github/license/ttscoff/planter-cli.svg)](./LICENSE.txt)

<!--README-->

Plant a directory structure and files using templates.

<!--GITHUB-->
- [Planter](#planter)
  - [Installation](#installation)
  - [Configuration](#configuration)
    - [Scripts](#scripts)
    - [Templates](#templates)
      - [Multiple choice type](#multiple-choice-type)
    - [File-specific handling](#file-specific-handling)
      - [If/then logic for file handling](#ifthen-logic-for-file-handling)
    - [Regex replacements](#regex-replacements)
    - [Finder Tags](#finder-tags)
    - [Placeholders](#placeholders)
      - [Default values in template strings](#default-values-in-template-strings)
      - [Modifiers](#modifiers)
      - [If/then logic](#ifthen-logic)
  - [Usage](#usage)
  - [Documentation](#documentation)
  - [Development and Testing](#development-and-testing)
    - [Source Code](#source-code)
    - [Requirements](#requirements)
    - [Rake](#rake)
    - [Guard](#guard)
  - [Contributing](#contributing)
  - [License](#license)
  - [Warranty](#warranty)
<!--END GITHUB-->

## Installation

    gem install planter-cli

If you run into errors, try `gem install --user-install planter-cli`, or as a last ditch effort, `sudo gem install planter-cli`.

## Configuration

Planter's base configuration is in `~/.config/planter/planter.yml`. This file can contain any of the keys used in templates (see below) and will serve as a base configuration for all templates. Any key defined in this file will be overridden if it exists in a template.

Example config (written on first run):

```yaml
files:
  .DS_Store: ignore
  "*.tmp": ignore
  "*.bak": ignore
git_init: false
preserve_tags: true
```

### Scripts

Scripts for execution after planting can be stored in `~/.config/planter/scripts` and referenced by filename only. Alternatively, scripts may be stored within a template in a `_scripts` subfolder.

Scripts can be executable files in any language, and receive the template directory and the planted directory as arguments $1 and $2.

### Templates

Templates are directories found in `~/.config/planter/templates/[TEMPLATE_NAME]`. All files and directories inside of these template directories are copied when that template is called. Filenames, directory names, and file contents can all use template placeholders.

Template placeholders are defined with `%%KEY%%`, where key is the key defined in the `variables` section of the configuration. `%%KEY%%` placeholders can be used in directory/file names, and in the file contents. These work in any plain text or RTF format document, including XML, so they can be used in things like Scrivener templates and MindNode files as well. See the subsections for info on default values and modifiers for template placeholders.

Each template contains a `_planter.yml` file that defines variables and other configuration options. The file format for all configuration files is [YAML](https://yaml.org/spec/1.2.2/).

First, there's a `variables` section that defines variables used in the template. It's an array of dictionaries, each dictionary defining one variable. The required fields are `key` (the key used to insert the variable) and `prompt` (the text provided on the command line when asking for the variable). The rest are optional:

```yaml
variables:
  - key: var_key
    prompt: Prompt text
    type: string # [string,paragraph,float,integer,number,date,choice] defaults to string
    value: # (force value, string can include %%variables%% and regexes will be replaced. For date type can be today, time, now, etc.)
    default: Untitled
    min: 1
    max: 5
    date_format: "%Y-%m-%d" # can be any strftime format, will be applied to any date type
```

For the date type, value can be `today`, `now`, `tomorrow`, `last thursday`, etc. and natural language will be converted to a time. The formatting will be determined automatically based on the type of the value, e.g. "now" gets a time string, but "today" just gets a YYYY-mm-dd string. This can be modified using the `date_format` key, which accepts any [strftime](https://www.fabriziomusacchio.com/blog/2021-08-15-strftime_Cheat_Sheet/) value. You can also include a date format string in single parenthesis after a natural language date value, e.g. `value: "now 'This year: %Y'"`.

A configuration can include additional keys:

```yaml
script: # array of scripts, args passed as [script and args] TEMPLATE_DIR PWD
  - process.py
git_init: false # if true, initialize a git repository in the newly-planted directory
files: # Dictionary for file handling (see [File-specific handling](#file-specific-handling))
replacements: # Dictionary of pattern/replacments for regex substitution, see [Regex replacements](#regex-replacements)
repo: # If a repository URL is provided, it will be pulled and duplicated instead of copying an existing file structure
```


#### Multiple choice type

If the `type` is set to `choice`, then the key `choices` can contain a hash or array of choices. The key that accepts the choice should be surrounded with parenthesis (required for each choice).

If a Hash/Dictionary is defined, each choice can have a result string:

```yaml
variables:
  - key: shebang
    prompt: Shebang line
    type: choice
    default: r
    choices:
      (r)uby: "#! /usr/bin/env ruby"
      (j)avascript: "#! /usr/bin/env node"
      (p)ython: "#! /usr/bin/env python"
      (b)ash: "#! /bin/bash"
      (z)sh: "#! /bin/zsh"
```

When a choice is selected from a dictionary, the result string will be inserted instead of the choice title.

If an array is defined, the string of the choice will also be its result (minus any parenthesis):

```yaml
variables:
  - key: language
    prompt: Programming language
    type: choice
    default: 1
    choices:
      - 1. ruby
      - 1. javascript
      - 1. python
      - 1. bash
      - 1. zsh
```

If the choice starts with a number (as above), then a numeric list will be generated and typing the associated index number will accept that choice. Numeric lists are automatically numbered, so the preceding digit doesn't matter, as long as it's a digit, and only the first item needs a digit to trigger numbering. In this case a default can be defined with an integer (in the `defaults:` key) for its placement in the list (starting with 1), and parenthesis aren't required.

`value:` and `default:` can include previous variables, with modifiers:

```yaml
- variables:
  - key: language
    prompt: Programming language
    type: choice
    default: 2
    choices:
      - 1. ruby
      - javascript
      - python
      - bash
      - zsh
  - key: shebang
    prompt: Shebang line
    type: choice
    default: "%%language:first_letter:lowercase%%"
    choices:
      (r)uby: "#! /usr/bin/env ruby"
      (j)avascript: "#! /usr/bin/env node"
      (p)ython: "#! /usr/bin/env python"
      (b)ash: "#! /bin/bash"
      (z)sh: "#! /bin/zsh"
```

The above would define the `language` variable first, accepting `javascript` as default, then when displaying the menu for `shebang`, the language variable would have its first letter lowercased and set as the default option for the menu.

### File-specific handling

A `files` dictionary can specify how to handle specific files. Options are `copy`, `overwrite`, `merge`, or `ask`. The key for each entry is a filename or glob that matches the source filename (accounting for template variables if applicable):

```yaml
files:
  "*.py": merge
  "%%title%%.md": overwrite
```

Filenames can include wildcards (`*`, `?`), and Bash-ish globbing (`[0-9]`, `[a-z]`, `{one,two,three}`).

If `merge` is specified, then the source file is scanned for merge comments and those are merged if they don't exist in the copied/existing file. If no merge comments are defined, then the entire contents of the source file are appended to the destination file (unless the file already matches the source). Merge comments start with `merge` and end with `/merge` and can have any comment syntax preceding them, for example:

```
// merge
Merged content
// /merge
```

Or

```
# merge
Merged content
# /merge
```

By default files that already exist in the destination directory are not overwritten, and merging allows you to add missing parts to a Rakefile or Makefile, for example.

If `ask` is specified, a menu will be provided on the command line asking how to handle a file. If the file doesn't already exist, you will be asked only whether to copy the file or not. If it does exist, `overwrite` and `merge` options will be added.

#### If/then logic for file handling

The operation for a file match can be an if/then statement. There are two formats for this.

First, you can simply write `OPERATION if VARIABLE COMP VALUE`, e.g. `copy if language == ruby`. This can have an `else` statement: `overwrite if language == ruby else copy`.

You can also format it as `if VARIABLE COMP VALUE: OPERATION; else: OPERATION`. This format allows `else if` statements, e.g. `if language == perl: copy;else if language == ruby: overwrite; else: ignore`.

Planter's if/then parsing does not handle parenthetical or boolean operations.

### Regex replacements

In addition to manually-placed template variables, you can also specify regular expressions for replacement. The `replacements` dictionary is a set of key/value pairs with the regex pattern as the key, and the replacement as the value. Both should be quoted in almost all circumstances.

```yaml
replacements:
  "Planter": "%%title:cap%%"
  "(main|app)\.js": "%%script:lower%%.js"
```

Replacements are performed on both file/directory names and file contents. This is especially handy when the source of the plant is a Git repo, allowing the replacement of elements without having to create %%templated%% filenames and contents.

### Finder Tags

If `preserve_tags` is set to `true` in the config (either base or template), then existing Finder tags on the file or folder will be copied to the new file when a template is planted.

### Placeholders

Placeholders are `%%VARIABLE%%` strings used in filenames and within the content of the files. At their most basic, this would just look like `%%project_name%%`. But you can supply default values, string modifiers, and even if/then logic.

#### Default values in template strings

In a template you can add a default value for a placholder by adding `%default value` to it. For example, `%%project%Default Project%%` will set the placeholder to `Default Project` if the variable value matches the default value in the configuration (or doesn't exist). This allows you to accept the default on the command line but have a different value inserted in the template. To use another variable in its place, use `$KEY` in the placeholder, e.g. `%%project%$title%%` will replace the `project` key with the value of `title` if the default is selected. Modifiers can be used on either side of the `%`, e.g. `%%project%$title:snake%%`.

#### Modifiers

A `%%variable%%` in a template can include modifiers that affect the output of the variable. These are added as `%%variable:MODIFIER%%` and multiple modifiers can be strung together, e.g. `%%language:lowercase:first_letter%%`. The available modifiers are (listed with available abbreviations):

- `snake` (`s`): snake_case the value
- `camel` (`cam`): camelCase the value
- `upper` (`u`): UPPERCASE the value
- `lower` (`l`, `d`): lowercase the value
- `title` (`t`): Title Case The Value
- `slug` or `file` (`sl`): slug-format-the-value
- `first_letter` (`fl`): Extract the first letter from the value
- `first_word` (`fw`): Extract the first word from the value

#### If/then logic

A template can use if/then logic, which is useful with multiple choice types. It can be applied to any type, though.

The format for if/then logic is:

```
%%if KEY OPERATOR VALUE%%
content
%%else if KEY OPERATOR VALUE2%%
content 2
%%else%%
content 3
%%endif%%
```

There should be no spaces around the comparison, e.g. `%% if language == javascript %%` won't work. The block must start with an `if` statement and end with `%%endif%%` or `%%end%%`. The `%%else%%` statement is optional -- if it doesn't exist then the entire block will be removed if no conditions are met.

The key should be an existing key defined in `variables`. The operator can be any of:

- `==` or `=` (equals)
- `=~` (matches regex)
- `*=` (contains)
- `^=` (starts with)
- `$=` (ends with)
- `>` (greater than)
- `>=` (greater than or equal)
- `<` (less than)
- `<=` (less than or equal)

Any of these operators can be inverted (negated) by preceding with an exclamation point, e.g. `!=` means `not equal` and `!*=` means `does not contain`.

The value after the operator doesn't need to be quoted, anything after the operator will be compared to the value of the key.

Logic can be used on multiple lines like the example above, or on a single line (useful for filenames):


    %%project%%.%%if language == javascript%%js%%else if language == ruby%%rb%%else%%sh%%endif%%


Content within if/else blocks can contain variables. Planter's if/then parsing does not handle parenthetical or boolean operations.

## Usage

The executable for Planter is `plant`. You can run `plant TEMPLATE` in any directory and TEMPLATE will be planted in the current directory. You can also use `--in PATH` to plant in another directory.

```
Usage: plant [options] TEMPLATE
    --defaults                       Accept default values for all variables
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

Variables can be passed on the command line with `--var KEY:VALUE`. This flag can contain a comma-separated list, e.g. `--var KEY:VALUE,KEY:VALUE` or be used multiple times in the same command. Variables passed on the command line will not be prompted for when processing variables.

<!--GITHUB-->

## Documentation

- [YARD documentation][RubyDoc] is hosted by RubyDoc.info.

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
