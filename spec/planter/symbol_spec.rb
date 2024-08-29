# frozen_string_literal: true

require 'spec_helper'

describe ::Symbol do
  describe '.to_var' do
    it 'turns a symbol into a string with _ instead of :' do
      expect(:var_name.to_var).to eq :var_name
    end
  end

  describe '.normalize_type' do
    it 'normalizes a type symbol' do
      expect(:string.normalize_type).to eq :string
    end
  end

  describe '.normalize_operator' do
    it 'normalizes an operator symbol' do
      expect(:copy.normalize_operator).to eq :copy
    end
  end
end
