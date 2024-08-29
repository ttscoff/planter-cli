# frozen_string_literal: true

require 'spec_helper'

describe ::File do
  describe '.binary?' do
    it 'detects a non-binary text file' do
      expect(File.binary?('spec/test_out/test2.rb')).to be(false)
    end

    it 'detects a binary image' do
      expect(File.binary?('spec/test_out/image.png')).to be(true)
    end

    it 'recognizes json as text' do
      expect(File.binary?('spec/test_out/doing.sublime-project')).to be(false)
    end
  end
end
