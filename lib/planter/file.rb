# frozen_string_literal: true

# Main module
module Planter
  # File helpers
  class ::File
    #
    # Test if file is text
    #
    # @param name [String] file path
    #
    # @return [Boolean] File is text
    #
    def self.text?(name)
      !binary?(name)
    end

    #
    # Test if file is binary
    #
    # @param name [String] File path
    #
    # @return [Boolean] file is binary
    #
    def self.binary?(name)
      return true if name.nil? || name.empty? || !File.exist?(name)

      ascii = control = binary = 0

      bytes = File.open(name, 'rb') { |io| io.read(1024) }
      return true if bytes.nil? || bytes.empty?
      bytes.each_byte do |bt|
        case bt
        when 0...32
          control += 1
        when 32...128
          ascii += 1
        else
          binary += 1
        end
      end

      first_test = binary.to_f / ascii > 0.05

      first_test || second_test(name)
    end

    # Allowable text file types
    TEXT_TYPES = %w[text ansi xml json yaml csv empty].freeze

    #
    # Secondary test with file command
    #
    # @param name [String] file path
    #
    # @return [Boolean] file is binary according to file command
    #
    def self.second_test(name)
      if TTY::Which.exist?('file')
        file_type, status = Open3.capture2e('file', name)
        file_type = file_type.split(':')[1..-1].join(':').strip
        if file_type =~ /Apple binary property list/
          `plutil -convert xml1 "#{name}"`
          File.binary?(name)
        else
          status.success? && !text_type?(file_type)
        end
      else
        false
      end
    end

    #
    # Tertiary test for binary file
    #
    # @param name [String] file path
    #
    # @return [Boolean] file is binary according to mdls
    #
    def self.third_test(name)
      if TTY::Which.exist?('mdls')
        file_type, status = Open3.capture2e('mdls', '-name', 'kMDItemContentTypeTree', name)
        status.success? && !text_type?(file_type)
      else
        false
      end
    end

    def self.text_type?(name)
      TEXT_TYPES.any? { |type| name.downcase.include?(type) } || name.empty?
    end
  end
end
