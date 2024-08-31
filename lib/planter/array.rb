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
    ## @param      default  [String] The color templated output string
    ##
    def abbr_choices(default: nil)
      chars = join(' ').scan(/\((.)\)/).map { |c| c[0] }
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
