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
