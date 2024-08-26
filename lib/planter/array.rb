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
  end
end
