# frozen_string_literal: true

require 'spec_helper'

describe Planter::FileEntry do
  subject do
    Planter::FileEntry.new(File.expand_path('spec/templates/test/test.rb'), File.expand_path('spec/test_out/test.rb'),
                           :ignore)
  end

  describe '#initialize' do
    it 'makes a new instance' do
      expect(subject).to be_a described_class
    end
  end

  describe '#to_s' do
    it 'returns the name of the file' do
      expect(subject.to_s).to be_a(String)
    end
  end

  describe '#inspect' do
    it 'returns a string representation of the file' do
      expect(subject.inspect).to be_a(String)
    end
  end

  describe '#ask_operation' do
    it 'returns :copy' do
      expect(subject.ask_operation).to eq(:copy)
    end

    it 'returns :ignore for existing file' do
      fileentry = Planter::FileEntry.new(File.expand_path('spec/templates/test/test.rb'), File.expand_path('spec/test_out/test2.rb'),
                                         :ignore)
      expect(fileentry.ask_operation).to eq(:ignore)
    end
  end
end
