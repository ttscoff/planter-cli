# frozen_string_literal: true

module Planter
  # A single file entry in a FileList
  class FileEntry < Hash
    # Operation to execute on the file
    attr_accessor :operation

    # File path
    attr_reader :file

    # Target path
    attr_reader :target

    # Tags
    attr_reader :tags

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
      return unless File.exist?(file)

      @file = file
      @target = target
      @operation = operation

      @tags = Tag.get(file)

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
    ## Determine operators based on configured filters,
    ## asking for input if necessary
    ##
    ## @return     [Symbol] Operator
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
    def inspect
      "<FileEntry: @file: #{@file}, @target: #{@target}, @operation: #{@operation}>"
    end

    ##
    ## Returns a string representation of the object contents.
    ##
    ## @return     [String] String representation of the object.
    ##
    def to_s
      File.binary?(@file) ? 'Binary file' : IO.read(@file).to_s
    end
  end
end
