require 'open3'
require 'spec_helper'

include PlanterHelpers

describe 'CLI' do
  TEST_DIR = File.join(File.dirname(__FILE__), 'test')

  before do
    FileUtils.rm_rf(TEST_DIR)
    FileUtils.mkdir_p(TEST_DIR)
  end

  after do
    FileUtils.rm_rf(TEST_DIR)
  end

  it 'displays help message' do
    output, stderr, status = planter('--help')
    expect(output).to match(/Usage: plant \[options\] TEMPLATE/)
  end

  it 'displays variables for a template' do
    output, stderr, status = planter('--help', 'test')
    expect(output).to match(/CLI Prompt/)
  end

  it 'plants a new project' do
    output, stderr, status = planter("--in=#{TEST_DIR}", 'test')
    expect(File.exist?(File.join(TEST_DIR, 'bollocks_and_beans.rtf'))).to be true
  end

  it 'plants a new file with a script' do
    output, stderr, status = planter("--in=#{TEST_DIR}", 'test')
    expect(File.exist?(File.join(TEST_DIR, 'planted_by_script.txt'))).to be true
  end
end
