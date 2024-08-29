# frozen_string_literal: true

require 'spec_helper'

describe Planter::FileList do
  describe '#initialize' do
    it 'initializes with an empty list' do
      Planter.base_dir = File.expand_path('spec')
      Planter.variables = { project: 'Untitled', script: 'Script', title: 'Title' }
      Planter.config = 'test'
      filelist = Planter::FileList.new
      expect(filelist.files).not_to eq([])
    end
  end
end
