# frozen_string_literal: true

# Main module
module Planter
  #
  # Tests if a file is binary
  #
  # @param filename [String] File path
  #
  # @return [Boolean] file is binary
  #
  # def File.binary?(filename)
  #   file_type, status = Open3.capture2e('file', filename)
  #   status.success? && file_type.split(':').last.include?('text') ? false : true
  # end

  # def File.binary?(name)
  #   IO.read(name) do |f|
  #     f.each_byte { |x| x.nonzero? or return true }
  #   end
  #   false
  # end
  #
  class ::File
    def self.binary?(name)
      ascii = control = binary = 0

      File.open(name, 'rb') { |io| io.read(1024) }.each_byte do |bt|
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

      if TTY::Which.exist?('file')
        file_type, status = Open3.capture2e('file', name)
        second_test = status.success? && !file_type.include?('text') && !file_type.include?('XML') && !file_type.include?('JSON')
      else
        second_test = false
      end

      first_test || second_test
    end
  end
end
