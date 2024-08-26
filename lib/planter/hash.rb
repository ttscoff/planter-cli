# frozen_string_literal: true

# Hash helpers
class ::Hash
  ## Turn all keys into string
  ##
  ## @return     [Hash] copy of the hash where all its keys are strings
  ##
  def stringify_keys
    each_with_object({}) do |(k, v), hsh|
      hsh[k.to_s] = if v.is_a?(Hash)
                      v.stringify_keys
                    elsif v.is_a?(Array)
                      v.map(&:symbolize_keys)
                    else
                      v
                    end
    end
  end

  ##
  ## Turn all keys into symbols
  ##
  ## @return [Hash] hash with symbolized keys
  ##
  def symbolize_keys
    each_with_object({}) do |(k, v), hsh|
      hsh[k.to_sym] = if v.is_a?(Hash)
                        v.symbolize_keys
                      elsif v.is_a?(Array)
                        v.map(&:symbolize_keys)
                      else
                        v
                      end
    end
  end

  def deep_merge(second)
    merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    merge(second.to_h, &merger)
  end
end
