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
    def initialize(path)
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
    ## Public method for copying files based on their operator
    ##
    ## @return     [Boolean] success
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
    ## Copy tagged merge sections from source to target
    ##
    ## @param      entry  [FileEntry] The file entry
    ##
    def merge(entry)
      return copy_file(entry) if File.directory?(entry.file)

      type = `file #{entry.file}`
      case type.sub(/^#{Regexp.escape(entry.file)}: /, '').split(/:/).first
      when /Apple binary property list/
        `plutil -convert xml1 #{entry.file}`
        `plutil -convert xml1 #{entry.target}`
        content = IO.read(entry.file)
      when /data/
        return copy_file(entry)
      else
        return copy_file(entry) if File.binary?(entry.file)

        content = IO.read(entry.file)
      end

      merges = content.scan(%r{(?<=\A|\n).{,4}merge *\n(.*?)\n.{,4}/merge}m)
                      &.map { |m| m[0].strip.apply_variables.apply_regexes }
      merges = [content] if !merges || merges.empty?
      new_content = IO.read(entry.target)
      merges.delete_if { |m| new_content =~ /#{Regexp.escape(m)}/ }
      if merges.count.positive?
        File.open(entry.target, 'w') { |f| f.puts "#{new_content.chomp}\n\n#{merges.join("\n\n")}" }
        Planter.notify("Merged #{entry.file} => #{entry.target} (#{merges.count} merges)", :debug)
      else
        copy_file(entry)
      end
    end

    ##
    ## Perform file copy based on operator
    ##
    ## @param      file       [FileEntry] The file entry
    ## @param      overwrite  [Boolean] Force overwrite
    ##
    def copy_file(file, overwrite: false)
      if !File.exist?(file.target) || overwrite || Planter.overwrite
        FileUtils.mkdir_p(File.dirname(file.target))
        FileUtils.cp(file.file, file.target) unless File.directory?(file.file)
        Planter.notify("Copied #{file.file} => #{file.target}", :debug)
        true
      else
        Planter.notify("Skipped #{file.file} => #{file.target}", :debug)
        false
      end
    end
  end
end
