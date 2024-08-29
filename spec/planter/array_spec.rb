# frozen_string_literal: true

require 'spec_helper'

describe ::Array do
  let(:array) { [1, 'value1', 'value2', { key1: 'value1', 'key2' => 'value2' }, %w[key1 key2]] }

  describe '.stringify_keys' do
    it 'converts string keys to strings' do
      result = array.stringify_keys
      expect(result).to eq([1, 'value1', 'value2', { 'key1' => 'value1', 'key2' => 'value2' }, %w[key1 key2]])
    end
  end

  describe '.abbr_choices' do
    it 'abbreviates the choices' do
      arr = ['(o)ption 1', '(s)econd option', '(t)hird option']
      result = arr.abbr_choices
      expect(result).to match(%r{{xdw}\[{xbw}o{dw}/{xbw}s{dw}/{xbw}t{dw}\]{x}})
    end

    it 'handles a default' do
      arr = ['(o)ption 1', '(s)econd option', '(t)hird option']
      result = arr.abbr_choices(default: 'o')
      expect(result).to match(%r{{xdw}\[{xbc}o{dw}/{xbw}s{dw}/{xbw}t{dw}\]{x}})
    end
  end
end
