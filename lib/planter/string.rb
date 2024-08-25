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
      snake_case.to_sym
    end

    ##
    ## Convert a slug into a class name
    ##
    ## @example    "planter-string".to_class_name #=> PlanterString
    ##
    ## @return     Class name representation of the object.
    ##
    def to_class_name
      strip.no_ext.split(/[-_ ]/).map(&:capitalize).join('').gsub(/[^a-z0-9]/i, '')
    end

    ##
    ## Convert a class name to a file slug
    ##
    ## @example    "PlanterString".to_class_name #=> planter-string
    ##
    ## @return     Filename representation of the object.
    ##
    def to_slug
      strip.no_ext.split(/(?=[A-Z])/).map(&:downcase).join('-')
           .gsub(/[^a-z0-9_-]/i, '')
           .gsub(/-+/, '-')
           .gsub(/(^-|-$)/, '')
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
      strip.gsub(/\S[A-Z]/) { |pair| pair.split('').join('_') }
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
      strip.gsub(/[ _]+(\S)/) { Regexp.last_match(1).upcase }
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
      gsub(/\b(\w)/) { Regexp.last_match(1).upcase }
    end

    ##
    ## Apply key/value substitutions to a string. Variables are represented as
    ## %%key%%, and the hash passed to the function is { key: value }
    ##
    ## @param      last_only  [Boolean] Only replace the last instance of %%key%%
    ##
    ## @return     [String] string with variables substituted
    ##
    def apply_variables(last_only: false)
      content = dup.clean_encode
      mod_rx = '(?<mod>
                  (?::
                    (
                      l(?:ow(?:er)?)?)?|
                      u(?:p(?:per)?)?|
                      c(?:ap(?:ital(?:ize)?)?)?|
                      t(?:itle)?|
                      snake|camel|slug|
                      f(?:ile(?:name)?
                    )?
                  )*
                )'

      Planter.variables.each do |k, v|
        if last_only
          pattern = "%%#{k.to_var}"
          content = content.reverse.sub(/(?mix)%%(?:(?<mod>.*?):)*(?<key>#{pattern.reverse})/) do
            m = Regexp.last_match
            if m['mod']
              m['mod'].reverse.split(/:/).each do |mod|
                v = v.apply_mod(mod.normalize_mod)
              end
            end

            v.reverse
          end.reverse
        else
          rx = /(?mix)%%(?<key>#{k.to_var})#{mod_rx}%%/

          content.gsub!(rx) do
            m = Regexp.last_match

            mods = m['mod']&.split(/:/)
            mods&.each do |mod|
              v = v.apply_mod(mod.normalize_mod)
            end
            v
          end
        end
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
    def apply_variables!(last_only: false)
      replace apply_variables(last_only: last_only)
    end

    ##
    ## Remove any file extension
    ##
    ## @example    "planter-string.rb".no_ext #=> planter-string
    ##
    ## @return     [String] string with no extension
    ##
    def no_ext
      sub(/\.\w+$/, '')
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
      else
        self
      end
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
      when /^(f|slug)/
        :slug
      when /^cam/
        :camel_case
      when /^s/
        :snake_case
      when /^u/
        :uppercase
      when /^l/
        :lowercase
      when /^[ct]/
        :title_case
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
      when /^da/
        :date
      when /^i/
        :integer
      when /^[nf]/
        :float
      when /^c/
        :class
      when /^m/
        :module
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
      case type
      when :date
        Chronic.parse(self)
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

    ##
    ## Highlight characters in parenthesis, with special color for default if
    ## provided. Output is color templated string, unprocessed.
    ##
    ## @param      default  [String] The default
    ##
    def highlight_character(default: nil)
      if default
        gsub(/\((#{default})\)/, "{dw}({xbc}\\1{dw}){xw}").gsub(/\((.)\)/, "{dw}({xbw}\\1{dw}){xw}")
      else
        gsub(/\((.)\)/, "{dw}({xbw}\\1{dw}){xw}")
      end
    end
  end
end
