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
    expect(output).not_to be_empty
  end

  it 'plants a new project' do
    output, stderr, status = planter('--defaults', "--in=#{TEST_DIR}", 'test')
    expect(File.exist?(File.join(TEST_DIR, 'bollocks_and_beans.rtf'))).to be true
  end
end
