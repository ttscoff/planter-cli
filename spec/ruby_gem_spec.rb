require 'spec_helper'

describe Planter::Plant do
  subject(:ruby_gem) { Planter::Plant.new }

  describe ".new" do
    it "makes a new instance" do
      expect(ruby_gem).to be_a Planter::Plant
    end
  end
end
