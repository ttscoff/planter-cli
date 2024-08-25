# frozen_string_literal: true

module Planter
  def File.binary?(name)
    open name do |f|
      f.each_byte { |x| x.nonzero? or return true }
    end
    false
  end
end
