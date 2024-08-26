require 'spec_helper'

describe ::String do
  describe '.to_var' do
    it 'turns string into snake-cased symbol' do
      expect('This is a test string'.to_var).to be :this_is_a_test_string
    end
  end

  describe '.to_slug' do
    it 'slugifies a string' do
      expect('This is a test string'.to_slug).to match /this-is-a-test-string/
    end

    it 'slugifies bad characters' do
      expect('This: #is a test string!'.to_slug).to match /this-colon-hash-is-a-test-string-bang/
    end
  end

end
