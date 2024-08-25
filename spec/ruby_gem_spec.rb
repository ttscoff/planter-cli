require 'spec_helper'

describe Planter::Plant do
  subject(:ruby_gem) { Planter::Plant.new('test', { project: "Untitled", script: "Script", title: "Title" }) }

  describe ".new" do
    it "makes a new instance" do
      expect(ruby_gem).to be_a Planter::Plant
    end
  end
end
