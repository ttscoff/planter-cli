# frozen_string_literal: true

require 'spec_helper'

describe Planter::Prompt::Question do
  let(:question) do
    question = {
      key: 'test',
      prompt: 'CLI Prompt',
      type: :string,
      default: 'default',
      value: nil
    }
  end

  before do
    Planter.accept_defaults = true
  end

  describe '#initialize' do
    it 'initializes a new question object' do
      q = described_class.new(question)
      expect(q).to be_a described_class
    end
  end

  describe '#ask' do
    it 'asks a question' do
      q = described_class.new(question)
      expect(q.ask).to eq('default')
    end
  end

  describe "#ask with date type" do
    it 'asks a date question' do
      question[:type] = :date
      question[:value] = 'today'
      q = described_class.new(question)
      expect(q.ask).to eq(Date.today.strftime('%Y-%m-%d'))
    end
  end

  describe "#ask with date type and inline date format" do
    it 'asks a date question' do
      question[:type] = :date
      question[:value] = "today '%Y'"
      q = described_class.new(question)
      expect(q.ask).to eq(Date.today.strftime('%Y'))
    end
  end

  describe "#ask with date type and date format config" do
    it 'asks a date question' do
      question[:type] = :date
      question[:date_format] = '%Y'
      question[:value] = "today"
      q = described_class.new(question)
      expect(q.ask).to eq(Date.today.strftime('%Y'))
    end
  end

  describe "#ask with choices" do
    it 'asks a question with choices' do
      question[:type] = :string
      question[:choices] = %w[(o)ne (t)wo t(h)ree]
      question[:default] = 'one'
      q = described_class.new(question)
      expect(q.ask).to eq('one')
    end
  end
end
