# frozen_string_literal: true

module Planter
  # File listing class
  class FileList
    attr_reader :files

    ##
    ## Initialize a new FileList object
    ##
    ## @param      path  [String] The base path for template
    ##
    def initialize(path = Planter.base_dir)
      @basedir = File.realdirpath(path)

      search_path = File.join(@basedir, '**/*')
      files = Dir.glob(search_path, File::FNM_DOTMATCH).reject do |file|
        file =~ %r{/(_scripts|\.git|_config\.yml$|\.{1,2}$)}
      end

      files.sort_by!(&:length)

      @files = files.map do |file|
        new_file = "#{Planter.target}#{file.sub(/^#{@basedir}/, '').apply_variables.apply_regexes}"
        operation = Planter.overwrite ? :overwrite : :copy
        FileEntry.new(file, new_file, operation)
      end

      prepare_copy
    end

    ##
    ## Public method for copying @files to target based on their operator
    ##
    ## @return     [Boolean] success or failure
    ##
    def copy
      @files.each do |file|
        handle_operator(file)
      end
    rescue StandardError => e
      Planter.notify("#{e}\n#{e.backtrace}", :debug)
      Planter.notify('Error copying files/directories', :error, exit_code: 128)
    end

    private

    ##
    ## Perform operations
    ##
    ## @param      entry  [FileEntry] The file entry
    ##
    def handle_operator(entry)
      case entry.operation
      when :ignore
        false
      when :overwrite
        copy_file(entry, overwrite: true)
      when :merge
        File.exist?(entry.target) ? merge(entry) : copy_file(entry)
      else
        copy_file(entry)
      end
    end

    ##
    ## Copy template files to new directory
    ##
    ## @return     [Boolean] success
    ##
    def prepare_copy
      @files.each do |entry|
        if entry.matches_pattern?
          entry.operation = entry.test_operator
          propogate_operation(entry)
        end
      end
    end

    ##
    ## Apply a parent operation to children
    ##
    ## @param      entry  [FileEntry] The file entry
    ##
    def propogate_operation(entry)
      @files.each do |file|
        file.operation = entry.operation if file.file =~ /^#{entry.file}/
      end
    end

    ##
    ## Copy tagged merge sections from source to target. If merge tags do not exist in the file, append the entire file contents to the target.
    ##
    ## @param      entry  [FileEntry] The file entry
    ##
    ## @return     [Boolean] success
    ##
    def merge(entry)
      return copy_file(entry) if File.directory?(entry.file)

      # Get the file type
      type = `file #{entry.file}`
      case type.sub(/^#{Regexp.escape(entry.file)}: /, '').split(/:/).first
      when /Apple binary property list/
        # Convert to XML1 format
        `plutil -convert xml1 #{entry.file}`
        `plutil -convert xml1 #{entry.target}`
        content = IO.read(entry.file)
      when /data/
        # Simply copy the file
        return copy_file(entry)
      else
        # Copy the file if it is binary
        return copy_file(entry) if File.binary?(entry.file)

        # Read the file content
        content = IO.read(entry.file)
      end

      # Get the merge sections from the file, delimited by merge and /merge
      merges = content.scan(%r{(?<=\A|\n).{,4}merge *\n(.*?)\n.{,4}/merge}m)
                      &.map { |m| m[0].strip.apply_variables.apply_regexes }
      # If no merge sections are found, use the entire file
      merges = [content] if !merges || merges.empty?

      # Get the existing content of the target file
      target_content = IO.read(entry.target)

      # Remove any merges that already exist in the target file
      merges.delete_if { |m| target_content =~ /#{Regexp.escape(m)}/ }

      # If there are any merge sections left, merge them with the target file
      if merges.count.positive?
        File.open(entry.target, 'w') { |f| f.puts "#{target_content.chomp}\n\n#{merges.join("\n\n")}" }
        Planter.notify("Merged #{entry.file} => #{entry.target} (#{merges.count} merges)", :debug)
      else
        # If there are no merge sections left, copy the file instead
        copy_file(entry)
      end
    end

    ##
    ## Perform file copy based on operator
    ##
    ## @param      file       [FileEntry] The file entry
    ## @param      overwrite  [Boolean] Force overwrite
    ##
    ## @return     [Boolean] success
    ##
    def copy_file(file, overwrite: false)
      # Check if the target file already exists
      # If it does and overwrite is true, or Planter.overwrite is true,
      # or if the file doesn't exist, then copy the file
      if !File.exist?(file.target) || overwrite || Planter.overwrite
        # Make sure the target directory exists
        FileUtils.mkdir_p(File.dirname(file.target))
        # Copy the file if it isn't a directory
        FileUtils.cp(file.file, file.target) unless File.directory?(file.file)
        # Log a message to the console
        Planter.notify("Copied #{file.file} => #{file.target}", :debug)
        # Return true to indicate success
        true
      else
        # Log a message to the console
        Planter.notify("Skipped #{file.file} => #{file.target}", :debug)
        # Return false to indicate that the copy was skipped
        false
      end
    end
  end
end
