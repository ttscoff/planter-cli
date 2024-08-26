# frozen_string_literal: true

# Main module
module Planter
  def File.binary?(name)
    IO.read(name) do |f|
      f.each_byte { |x| x.nonzero? or return true }
    end
    false
  end
end
