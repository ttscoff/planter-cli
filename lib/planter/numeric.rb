# frozen_string_literal: true

module Planter
  # Integer extensions
  class ::Integer
    # Clean value (dummy method)
    def clean_value
      self
    end

    # Has selector (dummy method)
    def selector?
      true
    end

    # Highlight character
    def highlight_character(default: nil)
      "(#{self})".highlight_character(default: default)
    end
  end

  # Float extensions
  class ::Float
    # Clean value (dummy method)
    def clean_value
      self
    end

    # Has selector (dummy method)
    def selector?
      true
    end

    # Highlight character
    def highlight_character(default: nil)
      "(#{self})".highlight_character(default: default)
    end
  end
end
