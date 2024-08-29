# frozen_string_literal: true

require 'spec_helper'

describe Planter::Plant do
  Planter.accept_defaults = true
  Planter.base_dir = File.expand_path('spec')
  subject(:ruby_gem) { Planter::Plant.new('test', { project: 'Untitled', script: 'Script', title: 'Title' }) }

  describe '.new' do
    it 'makes a new instance' do
      expect(ruby_gem).to be_a described_class
    end
  end
end
