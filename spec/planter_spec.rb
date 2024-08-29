# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Planter" do
  describe '.notify' do
    it 'prints a warning message stderr' do
      expect(Planter.notify('hello world', :warn)).to be true
    end

    it 'prints an info message stderr' do
      expect(Planter.notify('hello world', :info)).to be true
    end

    it 'prints a debug message to stderr' do
      Planter.debug = true
      expect(Planter.notify('hello world', :debug)).to be true
    end

    it 'does not print a debug message to stderr' do
      Planter.debug = false
      expect(Planter.notify('hello world', :debug)).to be false
    end

    it 'prints an error message and exits' do
      expect do
        Planter.notify('Error', :error, exit_code: 10)
      end.to raise_error(SystemExit)
    end
  end

  describe '.config=' do
    #   it 'sets the config' do
    #     path = File.expand_path('spec/noop')
    #     FileUtils.mkdir_p(path)
    #     Planter.base_dir = File.expand_path('spec/noop')
    #     allow(File).to receive(:open).with(File.join(Planter.base_dir, "config.yml"), 'w')
    #     allow(File).to receive(:open).with(File.join(Planter.base_dir, 'templates', 'test', '_planter.yml'),
    #                                        'w')
    #     Planter.config = 'test'
    #     expect(File.exist?('spec/noop/config.yml')).to be true
    #     FileUtils.remove_entry_secure(path)
    #   end
    #
    # it 'creates a new configuration file if it does not exist' do
    #   path = File.expand_path('spec/noop')
    #   FileUtils.mkdir_p(path)
    #   Planter.base_dir = File.expand_path('spec/noop')
    #   allow(File).to receive(:exist?).with(File.join(Planter.base_dir, 'config.yml')).and_return(false)
    #   expect(File).to receive(:open).with(File.join(Planter.base_dir, 'config.yml'), 'w')
    #   Planter.config = 'test'
    #   FileUtils.remove_entry_secure(path)
    # end

    # it 'creates a new template directory if it does not exist' do
    #   path = File.expand_path('spec/noop')
    #   FileUtils.mkdir_p(path)
    #   Planter.base_dir = File.expand_path('spec/noop')
    #   allow(File).to receive(:exist?).with(File.join(Planter.base_dir, 'templates', 'test',
    #                                                  '_planter.yml')).and_return(false)
    #   allow(File).to receive(:directory?).with(File.join(Planter.base_dir, 'templates', 'test')).and_return(false)
    #   expect(FileUtils).to receive(:mkdir_p).with(File.join(Planter.base_dir, 'templates', 'test'))
    #   Planter.config = 'test'
    #   FileUtils.remove_entry_secure(path)
    # end
  end
end
