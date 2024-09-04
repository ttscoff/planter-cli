# frozen_string_literal: true

module Planter
  ## String helpers
  class ::String
    ##
    ## Convert string to snake-cased variable name
    ##
    ## @example    "Planter String" #=> planter_string
    ## @example    "Planter-String" #=> planter_string
    ##
    ## @return     [Symbol] string as variable key
    ##
    def to_var
      strip_quotes.snake_case.to_sym
    end

    ## Strip quotes from a string
    ##
    ## @return [String] string with quotes stripped
    ##
    def strip_quotes
      sub(/^(["'])(.*)\1$/, '\2')
    end

    ## Destructive version of #strip_quotes
    def strip_quotes!
      replace strip_quotes
    end

    #
    # Convert {a,b,c} to (?:a|b|c)
    #
    # @return [String] Converted string
    #
    def glob_to_rx
      gsub(/\\?\{(.*?)\\?\}/) do
        m = Regexp.last_match
        "(?:#{m[1].split(/,/).map { |c| Regexp.escape(c) }.join('|')})"
      end
    end

    #
    # Convert a string to a regular expression by escaping special
    # characters and converting wildcards (*,?) to regex wildcards
    #
    # @return [String] String with wildcards converted (not Regexp)
    #
    def to_rx
      gsub(/([.()])/, '\\\\\1').gsub(/\?/, '.').gsub(/\*/, '.*?').glob_to_rx
    end

    ##
    ## Convert a slug into a class name
    ##
    ## @example    "planter-string".to_class_name #=> PlanterString
    ##
    ## @return     Class name representation of the object.
    ##
    def to_class_name
      strip.no_ext.title_case.gsub(/[^a-z0-9]/i, '').sub(/^\S/, &:upcase)
    end

    ##
    ## Convert a class name to a file slug
    ##
    ## @example    "PlanterString".to_class_name #=> planter-string
    ##
    ## @return     Filename representation of the object.
    ##
    def to_slug
      strip.split(/(?=[A-Z ])/).map(&:downcase).join('-')
           .gsub(/[^a-z0-9_-]/i, &:slugify)
           .gsub(/-+/, '-')
           .gsub(/(^-|-$)/, '')
    end

    ## Convert some characters to text
    ##
    ## @return [String] slugified character or empty string
    ##
    def slugify
      char = to_s
      slug_version = {
        '.' => 'dot',
        '/' => 'slash',
        ':' => 'colon',
        ',' => 'comma',
        '!' => 'bang',
        '#' => 'hash'
      }
      slug_version[char] ? "-#{slug_version[char]}-" : ''
    end

    ##
    ## Convert a string to snake case, handling spaces or CamelCasing
    ##
    ## @example    "ClassName".snake_case #=> class-name
    ## @example    "A title string".snake_case #=> a-title-string
    ##
    ## @return     [String] Snake-cased version of string
    ##
    def snake_case
      strip.gsub(/\S(?=[A-Z])/, '\0_')
           .gsub(/[ -]+/, '_')
           .gsub(/[^a-z0-9_]+/i, '')
           .gsub(/_+/, '_')
           .gsub(/(^_|_$)/, '').downcase
    end

    ##
    ## Convert a string to camel case, handling spaces or snake_casing
    ##
    ## @example    "class_name".camel_case #=> className
    ## @example    "A title string".camel_case #=> aTitleString
    ##
    ## @return     [String] Snake-cased version of string
    ##
    def camel_case
      strip.gsub(/(?<=[^a-z0-9])(\S)/) { Regexp.last_match(1).upcase }
           .gsub(/[^a-z0-9]+/i, '')
           .sub(/^(\w)/) { Regexp.last_match(1).downcase }
    end

    ##
    ## Capitalize the first character after a word border. Prevents downcasing
    ## intercaps.
    ##
    ## @example    "a title string".title_case #=> A Title String
    ##
    ## @return     [String] title cased string
    ##
    def title_case
      split(/\b(\w+)/).map(&:capitalize).join('')
    end

    # @return [String] Regular expression for matching variable modifiers
    MOD_RX = '(?<mod>
                  (?::
                    (
                      l(?:ow(?:er(case)?)?)?)?|
                      d(?:own(?:case)?)?|
                      u(?:p(?:per(case)?)?)?|upcase|
                      c(?:ap(?:ital(?:ize)?)?)?|
                      t(?:itle)?|
                      snake|camel|slug|
                      fl|first_letter|
                      fw|first_word|
                      f(?:ile(?:name)?
                    )?
                  )*
                )'
    # @return [String] regular expression string for default values
    DEFAULT_RX = '(?:%(?<default>[^%]+))?'

    #
    # Apply default values to a string
    #
    # Default values are applied to variables that are not present in the variables hash,
    # or whose value matches the default value
    #
    # @param variables [Hash] Hash of variable values
    #
    # @return [String] string with default values applied
    #
    def apply_defaults(variables)
      # Perform an in-place substitution on the content string for default values
      gsub(/%%(?<varname>[^%:]+)(?<mods>(?::[^%]+)*)%(?<default>[^%]+)%%/) do
        # Capture the last match object
        m = Regexp.last_match

        # Check if the variable is not present in the variables hash
        if !variables.key?(m['varname'].to_var)
          # If the variable is not present, use the default value from the match
          m['default'].apply_var_names
        else
          # Retrieve the default value for the variable from the configuration
          vars = Planter.config.variables.filter { |v| v[:key] == m['varname'] }
          default = vars.first[:default] if vars.count.positive?
          if default.nil?
            m[0]
          elsif variables[m['varname'].to_var] == default
            # If the variable's value matches the default value, use the default value from the match
            m['default'].apply_var_names
          else
            m[0]
          end
        end
      end
    end

    #
    # Destructive version of #apply_defaults
    #
    # @param variables [Hash] hash of variables to apply
    #
    # @return [String] string with defaults applied
    #
    def apply_defaults!(variables)
      replace apply_defaults(variables)
    end

    ## Apply logic to a string
    ##
    ## @param variables [Hash] Hash of variables to apply
    ##
    def apply_logic(variables = nil)
      variables = variables.nil? ? Planter.variables : variables

      gsub(/%%if .*?%%.*?%%end( ?if)?%%/mi) do |construct|
        # Get the condition and the content
        output = construct.match(/%%else%%(.*?)%%end/m) ? Regexp.last_match(1) : ''

        conditions = construct.to_enum(:scan,
                                       /%%(?<statement>(?:els(?:e )?)?if) (?<condition>.*?)%%(?<content>.*?)(?=%%)/mi).map do
          Regexp.last_match
        end

        apply_conditions(conditions, variables, output)
      end
    end

    ## Destructive version of #apply_logic
    def apply_logic!(variables)
      replace apply_logic(variables)
    end

    ##
    ## Apply operator logic to a string. Operators are defined as
    ## :copy, :overwrite, :ignore, or :merge. Logic can be if/else
    ## constructs or inline operators.
    ##
    ## @example    "var = 1; if var == 1:copy; else: ignore" #=> :copy
    ## @example    "var = 2; copy if var == 1 else ignore" #=> :ignore
    ##
    ## @param variables [Hash] Hash of variables (default: Planter.variables)
    ##
    def apply_operator_logic(variables = nil)
      variables = variables.nil? ? Planter.variables : variables
      op_rx = ' *(?<content>c(?:opy)?|o(?:ver(?:write)?)?|i(?:gnore)?|m(?:erge)?)? *'

      strip.gsub(/^if .*?(?:end(?: ?if)?|$)/mi) do |construct|
        # Get the condition and the content
        output = construct.match(/else:#{op_rx}/m) ? Regexp.last_match(1) : ''

        conditions = construct.to_enum(:scan,
                                       /(?<statement>(?:els(?:e )?)?if) +(?<condition>.*?):#{op_rx}(?=;|$)/mi).map do
          Regexp.last_match
        end

        apply_conditions(conditions, variables, output)
      end.gsub(/^#{op_rx} +if .*?(end( ?if)?|$)/mi) do |construct|
        # Get the condition and the content
        output = construct.match(/else[; ]+(#{op_rx})/m) ? Regexp.last_match(1) : :ignore
        condition = construct.match(/^#{op_rx}(?<statement>if) +(?<condition>.*?)(?=;|$)/mi)

        apply_conditions([condition], variables, output)
      end.normalize_operator
    end

    ##
    ## Apply conditions
    ##
    ## @param conditions [Array<MatchData>] Array of conditions ['statement', 'condition', 'content']
    ## @param variables [Hash] Hash of variables
    ## @param output [String] Output string
    ##
    ## @return [String] Output string
    ##
    def apply_conditions(conditions, variables, output)
      res = false
      conditions.each do |condition|
        variable, operator, value = condition['condition'].split(/ +/, 3)
        value.strip_quotes!
        variable = variable.to_var
        negate = false
        if operator =~ /^!/
          operator = operator[1..-1]
          negate = true
        end
        operator = case operator
                   when /^={1,2}/
                     :equal
                   when /^=~/
                     :matches_regex
                   when /\*=/
                     :contains
                   when /\^=/
                     :starts_with
                   when /\$=/
                     :ends_with
                   when />/
                     :greater_than
                   when /</
                     :less_than
                   when />=/
                     :greater_than_or_equal
                   when /<=/
                     :less_than_or_equal
                   else
                     :equal
                   end

        comp = variables[variable.to_var].to_s

        res = case operator
              when :equal
                comp =~ /^#{value}$/i
              when :matches_regex
                comp =~ Regexp.new(value.gsub(%r{^/|/$}, ''))
              when :contains
                comp =~ /#{value}/i
              when :starts_with
                comp =~ /^#{value}/i
              when :ends_with
                comp =~ /#{value}$/i
              when :greater_than
                comp > value.to_f
              when :less_than
                comp < value.to_f
              when :greater_than_or_equal
                comp >= value.to_f
              when :less_than_or_equal
                comp <= value.to_f
              else
                false
              end
        res = res ? true : false
        res = !res if negate

        next unless res

        Planter.notify("Condition matched: #{comp} #{negate ? 'not ' : ''}#{operator} #{value}", :debug)
        output = condition['content']
        break
      end
      output
    end

    ##
    ## Apply key/value substitutions to a string. Variables are represented as
    ## %%key%%, and the hash passed to the function is { key: value }
    ##
    ## @param      last_only  [Boolean] Only replace the last instance of %%key%%
    ##
    ## @return     [String] string with variables substituted
    ##
    def apply_variables(variables: nil, last_only: false)
      variables = variables.nil? ? Planter.variables : variables

      content = dup.clean_encode

      content = content.apply_defaults(variables)

      content = content.apply_logic(variables)

      variables.each do |k, v|
        if last_only
          pattern = "%%#{k.to_var}"
          content = content.reverse.sub(/(?mix)%%(?:(?<mod>.*?):)*(?<key>#{pattern.reverse})/i) do
            m = Regexp.last_match
            if m['mod']
              m['mod'].reverse.split(/:/).each do |mod|
                v = v.apply_mod(mod.normalize_mod)
              end
            end

            v.reverse
          end.reverse
        else
          rx = /(?mix)%%(?<key>#{k.to_var})#{MOD_RX}#{DEFAULT_RX}%%/

          content.gsub!(rx) do
            m = Regexp.last_match

            if m['mod']
              mods = m['mod']&.split(/:/)
              mods&.each do |mod|
                next if mod.nil? || mod.empty?

                v = v.apply_mod(mod.normalize_mod)
              end
            end
            v
          end
        end
      end

      content
    end

    #
    # Handle $varname and ${varname} variable substitutions
    #
    # @return [String] String with variables substituted
    #
    def apply_var_names
      sub(/\$\{?(?<varname>\w+)(?<mods>(?::\w+)+)?\}?/) do
        m = Regexp.last_match
        if Planter.variables.key?(m['varname'].to_var)
          Planter.variables[m['varname'].to_var].apply_mods(m['mods'])
        else
          m
        end
      end
    end

    #
    # Apply modifiers to a string
    #
    # @param mods [String] Colon separated list of modifiers to apply
    #
    # @return [String] string with modifiers applied
    #
    def apply_mods(mods)
      content = dup
      mods.split(/:/).each do |mod|
        content.apply_mod!(mod.normalize_mod)
      end
      content
    end

    ##
    ## Apply all logic, variables, and regexes to a string
    ##
    def apply_all
      apply_logic.apply_variables.apply_regexes
    end

    ##
    ## Apply regex replacements from Planter.config[:replacements]
    ##
    ## @return     [String] string with regexes applied
    ##
    def apply_regexes(regexes = nil)
      content = dup.clean_encode
      regexes = regexes.nil? && Planter.config.key?(:replacements) ? Planter.config.replacements : regexes

      return self unless regexes

      regexes.stringify_keys.each do |pattern, replacement|
        pattern = Regexp.new(pattern) unless pattern.is_a?(Regexp)
        replacement = replacement.gsub(/\$(\d)/, '\\\1').apply_variables
        content.gsub!(pattern, replacement)
      end
      content
    end

    ##
    ## Destructive version of #apply_variables
    ##
    ## @param      last_only  [Boolean] Only replace the last instance of %%key%%
    ##
    ## @return     [String] string with variables substituted
    ##
    def apply_variables!(variables: nil, last_only: false)
      replace apply_variables(variables: variables, last_only: last_only)
    end

    ##
    ## Destructive version of #apply_regexes
    ##
    ## @return     [String] string with variables substituted
    ##
    def apply_regexes!(regexes = nil)
      replace apply_regexes(regexes)
    end

    ##
    ## Remove any file extension
    ##
    ## @example    "planter-string.rb".no_ext #=> planter-string
    ##
    ## @return     [String] string with no extension
    ##
    def no_ext
      sub(/\.\w{2,4}$/, '')
    end

    ##
    ## Add an extension to the string, replacing existing extension if needed
    ##
    ## @example    "planter-string".ext('rb') #=> planter-string.rb
    ##
    ## @example    "planter-string.rb".ext('erb') #=> planter-string.erb
    ##
    ## @param      extension  [String] The extension to add
    ##
    ## @return     [String] string with new extension
    ##
    def ext(extension)
      extension = extension.sub(/^\./, '')
      sub(/(\.\w+)?$/, ".#{extension}")
    end

    ##
    ## Apply a modification to string
    ##
    ## @param      mod   [Symbol] The modifier to apply
    ##
    ## @return     [String] modified string
    ##
    def apply_mod(mod)
      case mod
      when :slug
        to_slug
      when :title_case
        title_case
      when :lowercase
        downcase
      when :uppercase
        upcase
      when :snake_case
        snake_case
      when :camel_case
        camel_case
      when :first_letter
        split('')[0]
      when :first_word
        split(/[ !,?;:]+/)[0]
      else
        self
      end
    end

    #
    # Destructive version of #apply_mod
    #
    # @param mod [String] modified string
    #
    # @return [<Type>] <description>
    #
    def apply_mod!(mod)
      replace apply_mod(mod)
    end

    ##
    ## Convert mod string to symbol
    ##
    ## @example "snake" => :snake_case
    ## @example "cap" => :title_case
    ##
    ## @return     [Symbol] symbolized modifier
    ##
    def normalize_mod
      case self
      when /^(file|slug)/
        :slug
      when /^cam/
        :camel_case
      when /^s/
        :snake_case
      when /^u/
        :uppercase
      when /^[ld]/
        :lowercase
      when /^[ct]/
        :title_case
      when /^(fl|first_letter)/
        :first_letter
      when /^(fw|first_word)/
        :first_word
      end
    end

    ##
    ## Convert operator string to symbol
    ##
    ## @example "ignore" => :ignore
    ## @example "m" => :merge
    ##
    ## @return     [Symbol] symbolized operator
    ##
    def normalize_operator
      case self
      # merge or append
      when /^i/
        :ignore
      when /^(m|ap)/
        :merge
      # ask or optional
      when /^(a|op)/
        :ask
      # overwrite
      when /^o/
        :overwrite
      else
        :copy
      end
    end

    ##
    ## Convert type string to symbol
    ##
    ## @example    "string".coerce #=> :string
    ## @example    "date".coerce #=> :date
    ## @example    "num".coerce #=> :number
    ##
    ## @return     [Symbol] type symbol
    ##
    def normalize_type
      case self
      # date
      when /^da/
        :date
      # integer
      when /^i/
        :integer
      # number or float
      when /^[nf]/
        :float
      # paragraph
      when /^p/
        :multiline
      # class
      when /^cl/
        :class
      # module
      when /^mod/
        :module
      # multiple choice
      when /^(ch|mu)/
        :choice
      # string
      else
        :string
      end
    end

    ##
    ## Coerce a variable to a type
    ##
    ## @param      type  [Symbol] The type
    ##
    ##
    def coerce(type)
      type = type.normalize_type

      case type
      when :date
        Chronic.parse(self).strftime('%Y-%m-%d %H:%M')
      when :integer || :number
        to_i
      when :float
        to_f
      when :class || :module
        to_class_name
      else
        to_s
      end
    end

    ##
    ## Get a clean UTF-8 string by forcing an ISO encoding and then re-encoding
    ##
    ## @return     [String] UTF-8 string
    ##
    def clean_encode
      force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
    end

    ##
    ## Destructive version of #clean_encode
    ##
    ## @return     [String] UTF-8 string, in place
    ##
    def clean_encode!
      replace clean_encode
    end

    ## Clean up a string by removing leading numbers and parentheticalse
    ##
    ## @return [String] cleaned string
    ##
    def clean_value
      sub(/^\(?\d+\.\)? +/, '').sub(/\((.*?)\)/, '\1')
    end

    ##
    ## Highlight characters in parenthesis, with special color for default if
    ## provided. Output is color templated string, unprocessed.
    ##
    ## @param      default  [String] The default
    ##
    def highlight_character(default: nil)
      if default
        gsub(/\((#{default})\)/, '{dw}({xbc}\1{dw}){xw}').gsub(/\((.)\)/, '{dw}({xbw}\1{dw}){xw}')
      else
        gsub(/\((.)\)/, '{dw}({xbw}\1{dw}){xw}')
      end
    end

    #
    # Test if a string has a parenthetical selector
    #
    # @return [Boolean] has selector
    #
    def has_selector?
      self =~ /\(.\)/ ? true : false
    end
  end
end
