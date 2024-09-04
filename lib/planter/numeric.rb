# frozen_string_literal: true

module Planter
  class ::Integer
    def clean_value
      self
    end

    def has_selector?
      true
    end

    def highlight_character(default: nil)
      "(#{self})".highlight_character(default: default)
    end
  end

  class ::Float
    def clean_value
      self
    end

    def has_selector?
      true
    end

    def highlight_character(default: nil)
      "(#{self})".highlight_character(default: default)
    end
  end
end
