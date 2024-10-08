### 3.0.6

2024-09-05 05:53

#### IMPROVED

- Code cleanup and documentation

### 3.0.5

2024-09-04 07:49

#### NEW

- Date_format setting for date types
- Allow `today '%Y'` inline date formatting
- If/then logic for file operators
- First_letter, first_word modifiers for variables
- Allow default/value variable configutations to include %%placeholders%% and modifiers

#### IMPROVED

- Code refactoring

#### FIXED

- Overwrite operation not overwriting

### 3.0.4

2024-09-02 08:43

#### FIXED

- Incorrect binary name in help banner

### 3.0.3

2024-09-02 08:02

#### CHANGED

- Multiline is now "paragraph"
- Module type now requires "mod" at minimum

#### NEW

- Multiple choice variable type (ch|mu)
- If/then logic in templates

### 3.0.2

2024-09-01 09:46

#### IMPROVED

- Add basic CLI tests
- Better debug output and output of info messages above spinner
- Handle Bash-style globs in file: filenames

### 3.0.1

2024-08-31 14:19

### 3.0.0-alpha

2024-08-31 14:18

#### NEW

- Initial release
- Preserve Finder tags when planting (config option `preserve_tags: true`)

#### IMPROVED

- More tests

#### FIXED

- Code refactoring

### 0.0.3

2024-08-28 09:46

#### CHANGED

- Change template config from _config.yml to _planter.yml

#### NEW

- Replacements key in config for a dictionary of regex patterns and replacements
- Add repo key to config, pull a git repo
- Allow `value:` to be specified for any key. If the value contains %%vars%% or matches regexes, it will be updated and included without prompting.
- Add multiline type allowing for paragraph(s)

#### IMPROVED

- Adding tests
- Better error reporting
- More custom error handling
- Rubocop warnings
- Better Docker config for testing

#### FIXED

- Merge wasn't populating template placeholders
- Remove flags from hashbang for wider compatibility
- Place main config in ~/.config/planter and not in planter/templates

### 0.0.2

2024-08-26 10:25

#### NEW:

- Add repo key to config, pull a git rep
- replacements key in config for a dictionary of regex patterns and replacements

#### IMPROVED

- Better error reporting

#### FIXED

- Merge wasn't populating template placeholders
