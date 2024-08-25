# frozen_string_literal: true

# Symbol helpers
class ::Symbol
  # Handle calling to_var on a Symbol
  #
  # @return     [Symbol] same symbol, normalized if needed
  #
  def to_var
    to_s.to_var
  end

  # Handle calling normalize_operator on a Symbol
  #
  # @return     [Symbol] same symbol, normalized if needed
  #
  def normalize_operator
    to_s.normalize_operator
  end
end
