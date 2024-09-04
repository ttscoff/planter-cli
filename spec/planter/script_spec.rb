# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

describe Planter::Script do
  let(:template_dir) { File.expand_path('spec/templates/test') }
  let(:output_dir) { File.expand_path('spec/test_out') }
  let(:script_name) { 'test.sh' }
  let(:script_name_fail) { 'test_fail.sh' }
  let(:script_path) { File.join(template_dir, '_scripts', script_name) }
  let(:base_script_path) { File.join(Planter.base_dir, 'scripts', script_name) }

  before do
    ENV['PLANTER_RSPEC'] = 'true'
    Planter.base_dir = File.expand_path('spec')
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:exist?).with(script_path).and_return(true)
    allow(File).to receive(:exist?).with(base_script_path).and_return(false)
    allow(File).to receive(:directory?).with(output_dir).and_return(true)
  end

  describe '#initialize' do
    it 'initializes with valid script and directories' do
      script = Planter::Script.new(template_dir, output_dir, script_name)
      expect(script.script).to eq(script_path)
    end

    it 'raises an error if script is not found' do
      allow(File).to receive(:exist?).with(script_path).and_return(false)
      expect do
        Planter::Script.new(template_dir, output_dir, script_name)
      end.to raise_error(SystemExit)
    end

    it 'raises an error if output directory is not found' do
      allow(File).to receive(:directory?).with(output_dir).and_return(false)
      expect do
        Planter::Script.new(template_dir, output_dir, script_name)
      end.to raise_error(SystemExit)
    end
  end

  describe '#find_script' do
    it 'finds the script in the template directory' do
      script = Planter::Script.new(template_dir, output_dir, script_name)
      expect(script.find_script(template_dir, script_name)).to eq(script_path)
    end

    it 'finds the script in the base directory' do
      allow(File).to receive(:exist?).with(script_path).and_return(false)
      allow(File).to receive(:exist?).with(base_script_path).and_return(true)
      script = Planter::Script.new(template_dir, output_dir, script_name)
      expect(script.find_script(template_dir, script_name)).to eq(base_script_path)
    end

    it 'returns nil if script is not found' do
      allow(File).to receive(:exist?).with(script_path).and_return(false)
      allow(File).to receive(:exist?).with(base_script_path).and_return(false)
      expect do
        script = Planter::Script.new(template_dir, output_dir, script_name)
        script.find_script(template_dir, script_name)
      end.to raise_error(SystemExit)
    end
  end

  describe '#run' do
    it 'executes the script successfully' do
      script = Planter::Script.new(template_dir, output_dir, script_name)
      expect(script.run).to be true
    end

    it 'raises an error if script execution fails' do
      script = Planter::Script.new(template_dir, output_dir, script_name_fail)
      expect do
        script.run
      end.to raise_error(SystemExit)
    end
  end
end
