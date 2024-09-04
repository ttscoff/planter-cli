# frozen_string_literal: true

module Planter
  # Array helpers
  class ::Array
    ##
    ## Convert an array of "(c)hoices" to abbrevation. If a default character is
    ## provided it will be highlighted. Output is a color template, unprocessed.
    ##
    ## @example    ["(c)hoice", "(o)ther"].abbr_choices #=> "[c/o]"
    ##
    ## @param      default  [String] The (unprocessed) color templated output string
    ##
    def abbr_choices(default: nil)
      return default.nil? ? '' : "{xdw}[{xbc}#{default}{dw}]{x}" if all? { |c| c.to_i.positive? }

      chars = join(' ').scan(/\((?:(.)\.?)\)/).map { |c| c[0] }

      return default.nil? ? '' : "{xdw}[{xbc}#{default}{dw}]{x}" if chars.all? { |c| c.to_i.positive? }

      die('Array contains duplicates', :input) if chars.duplicates?

      out = String.new
      out << '{xdw}['
      out << chars.map do |c|
        if default && c.downcase == default.downcase
          "{xbc}#{c}"
        else
          "{xbw}#{c}"
        end
      end.join('{dw}/')
      out << '{dw}]{x}'
    end

    ## Convert an array of choices to a string with optional numbering
    ##
    ## @param      numeric  [Boolean] Include numbering
    ##
    ## @return     [Array] Array of choices
    ##
    def to_options(numeric)
      die('Array contains duplicates', :input) if duplicates?

      map.with_index do |c, i|
        # v = c.to_s.match(/\(?([a-z]|\d+\.?)\)?/)[1].strip
        if numeric
          "(#{i + 1}). #{c.to_s.sub(/^\(?\d+\.?\)? +/, '')}"
        else
          c
        end
      end
    end

    ## test if array has duplicates
    def duplicates?
      uniq.size != size
    end

    ## Find the index of a choice in an array of choices
    ##
    ## @param      choice  [String] The choice to find
    ##
    ## @return     [Integer] Index of the choice
    ##
    def option_index(choice)
      index = find_index { |c| c.to_s.match(/\((.+)\)/)[1].strip.sub(/\.$/, '') == choice }
      index || false
    end

    ## Convert an array of choices to a hash
    ##  - If the array contains hashes, they are converted to key/value pairs
    ##  - If the array contains strings, they are used as both key and value
    ##
    ## @return     [Hash] Hash of choices
    ##
    def choices_to_hash
      hash = {}
      each do |c|
        if c.is_a?(Hash)
          hash[c.keys.first.to_s] = c.values.first.to_s
        else
          hash[c.to_s] = c.to_s
        end
      end

      hash
    end

    ## Clean strings in an array by removing numbers and parentheses
    ##
    ## @return [Array] Array with cleaned strings
    ##
    def to_values
      map(&:clean_value)
    end

    ##
    ## Stringify keys in an array of hashes or arrays
    ##
    ## @return [Array] Array with nested hash keys stringified
    ##
    def stringify_keys
      each_with_object([]) do |v, arr|
        arr << if v.is_a?(Hash)
                 v.stringify_keys
               elsif v.is_a?(Array)
                 v.map { |x| x.is_a?(Hash) || x.is_a?(Array) ? x.stringify_keys : x }
               else
                 v
               end
      end
    end

    ##
    ## Symbolize keys in an array of hashes or arrays
    ##
    ## @return [Array] Array with nested hash keys symbolized
    ##
    def symbolize_keys
      each_with_object([]) do |v, arr|
        arr << if v.is_a?(Hash)
                 v.symbolize_keys
               elsif v.is_a?(Array)
                 v.map { |x| x.is_a?(Hash) || x.is_a?(Array) ? x.symbolize_keys : x }
               else
                 v
               end
      end
    end

    #
    # Destructive version of #symbolize_keys
    #
    # @return [Array] Array with symbolized keys
    #
    def symbolize_keys!
      replace deep_dup.symbolize_keys
    end

    ## Deep duplicate an array of hashes or arrays
    ##
    ## @return [Array] Deep duplicated array
    ##
    def deep_dup
      map { |v| v.is_a?(Hash) || v.is_a?(Array) ? v.deep_dup : v.dup }
    end
  end
end
