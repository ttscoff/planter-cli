# frozen_string_literal: true

module Planter
  # A single file entry in a FileList
  class FileEntry < Hash
    # Operation to execute on the file
    attr_accessor :operation

    # File path and target path
    attr_reader :file, :target

    ##
    ## Initialize a FileEntry object
    ##
    ## @param      file       [String] The source file path
    ## @param      target     [String] The target path
    ## @param      operation  [Symbol] The operation to perform
    ##
    ## @return [FileEntry] a Hash of parameters
    ##
    def initialize(file, target, operation)
      @file = file
      @target = target
      @operation = operation

      super()
    end

    ##
    ## Test if file matches any pattern in config
    ##
    ## @return     [Boolean] file matches pattern
    ##
    def matches_pattern?
      Planter.patterns.filter { |pattern, _| @file =~ pattern }.count.positive?
    end

    ##
    ## Determine operators based on configured filters
    ##
    def test_operator
      operator = Planter.overwrite ? :overwrite : :copy
      Planter.patterns.each do |pattern, op|
        next unless @file =~ pattern

        operator = op == :ask && !Planter.overwrite ? ask_operation : op
        break
      end
      operator
    end

    ##
    ## Prompt for file handling. If File exists, offer a merge/overwrite/ignore,
    ## otherwise simply ask whether or not to copy.
    ##
    def ask_operation
      if File.exist?(@target)
        Prompt.file_what?(self)
      else
        res = Prompt.yn("Copy #{File.basename(@file)} to #{File.basename(@target)}",
                        default_response: true)
        res ? :copy : :ignore
      end
    end

    ##
    ## Returns a string representation of the object.
    ##
    ## @return     [String] String representation of the object.
    ##
    def to_s
      "<FileEntry: @file: #{@file}, @target: #{@target}, @operation: #{@operation}>"
    end
  end
end
