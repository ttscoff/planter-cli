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

  ##
  ## Deep merge a hash
  ##
  ## @param      second  [Hash] The hash to merge into self
  ##
  def deep_merge(second)
    merger = proc do |_, v1, v2|
      if v1.is_a?(Hash) && v2.is_a?(Hash)
        v1.merge(v2, &merger)
      elsif v1.is_a?(Array) && v2.is_a?(Array)
        v1 | v2
      elsif [:undefined, nil, :nil].include?(v2)
        v1
      else
        v2
      end
    end
    merge(second.to_h, &merger)
  end

  ##
  ## Freeze all values in a hash
  ##
  ## @return     [Hash] Hash with all values frozen
  ##
  def deep_freeze
    chilled = {}
    each do |k, v|
      chilled[k] = v.is_a?(Hash) ? v.deep_freeze : v.freeze
    end

    chilled.freeze
  end

  ##
  ## Destructive version of #deep_freeze
  ##
  ## @return     [Hash] Hash with all values frozen
  ##
  def deep_freeze!
    replace deep_thaw.deep_freeze
  end

  ##
  ## Unfreeze a hash and all nested values
  ##
  ## @return     [Hash] unfrozen hash
  ##
  def deep_thaw
    chilled = {}
    each do |k, v|
      chilled[k] = v.is_a?(Hash) ? v.deep_thaw : v.dup
    end

    chilled.dup
  end

  ##
  ## Destructive version of #deep_thaw
  ##
  ## @return     [Hash] unfrozen hash
  ##
  def deep_thaw!
    replace deep_thaw
  end
end
