# frozen_string_literal: true

class ::Symbol
  def to_var
    to_s.to_var
  end
end
