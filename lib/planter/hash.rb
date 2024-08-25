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
end
