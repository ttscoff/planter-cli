# frozen_string_literal: true

require 'spec_helper'

describe ::Hash do
  let(:hash) { { 'key1' => 'value1', 'key2' => 'value2' } }

  describe '.symbolize_keys' do
    it 'converts string keys to symbols' do
      string_hash = { 'key1' => 'value1', 'key2' => 'value2', 'key3' => ['value3'] }
      result = string_hash.symbolize_keys
      expect(result).to eq({ key1: 'value1', key2: 'value2', key3: ['value3'] })
    end

    it 'handles nested hashes' do
      nested_hash = { 'outer' => { 'inner' => 'value' } }
      result = nested_hash.symbolize_keys
      expect(result).to eq({ outer: { inner: 'value' } })
    end

    it 'handles empty hashes' do
      result = {}.symbolize_keys
      expect(result).to eq({})
    end
  end

  describe '.stringify_keys' do
    it 'converts symbol keys to strings' do
      symbol_hash = { key1: 'value1', key2: 'value2', key3: ['value3'] }
      result = symbol_hash.stringify_keys
      expect(result).to eq({ 'key1' => 'value1', 'key2' => 'value2', 'key3' => ['value3'] })
    end

    it 'handles nested hashes' do
      nested_hash = { outer: { inner: 'value' } }
      result = nested_hash.stringify_keys
      expect(result).to eq({ 'outer' => { 'inner' => 'value' } })
    end

    it 'handles empty hashes' do
      result = {}.stringify_keys
      expect(result).to eq({})
    end
  end

  describe '.deep_merge' do
    it 'merges two hashes deeply' do
      hash1 = { a: 1, b: { c: 2 }, f: [1, 2] }
      hash2 = { b: { d: 3 }, e: 4, f: [3, 4] }
      result = hash1.deep_merge(hash2)
      expect(result).to eq({ a: 1, b: { c: 2, d: 3 }, e: 4, f: [1, 2, 3, 4] })
    end

    it 'handles empty hashes' do
      result = {}.deep_merge({})
      expect(result).to eq({})
    end

    it 'does not modify the original hashes' do
      hash1 = { a: 1, b: { c: 2 }, f: 'test' }
      hash2 = { b: { d: 3 }, e: 4, f: nil }
      hash1.deep_merge(hash2)
      expect(hash1).to eq({ a: 1, b: { c: 2 }, f: 'test' })
      expect(hash2).to eq({ b: { d: 3 }, e: 4, f: nil })
    end
  end

  describe '.deep_freeze' do
    it 'freezes all nested hashes' do
      hash = { a: 1, b: { c: 2 } }.deep_freeze
      expect(hash).to be_frozen
      expect(hash[:b]).to be_frozen
    end
  end

  describe '.deep_thaw' do
    it 'thaws all nested hashes' do
      hash = { a: 1, b: { c: 2 } }.deep_freeze.deep_thaw
      expect(hash).not_to be_frozen
      expect(hash[:b]).not_to be_frozen
    end
  end
end
