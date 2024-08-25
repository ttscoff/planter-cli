module Planter
  class ::Array
    def abbr_choices(default: nil)
      chars = join(' ').scan(/\((.)\)/).map { |c| c[0] }
      out = '{xdw}['
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
