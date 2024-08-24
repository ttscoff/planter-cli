module Planter
  # Primary class
  class Plant
    def initialize
      @basedir = File.join(Planter::BASE_DIR, Planter.template)
      @git = Planter.config[:git] || false
      @debug = Planter.debug

      Planter.config[:variables].each do |var|
        key = var[:key].to_var
        next if Planter.variables.keys.include?(key)

        q = Planter::Prompt::Question.new(
          key: key,
          prompt: var[:prompt] || var[:key],
          type: var[:type].normalize_type || :string,
          default: var[:default],
          value: var[:value],
          min: var[:min],
          max: var[:max]
        )
        answer = q.ask
        if answer.nil?
          Planter.notify("Missing value #{key}", :error, exit_code: 15) unless var[:default]

          answer = var[:default]
        end
        Planter.variables[key] = answer
      end
    end

    def plant
      title = "{bw}[{bg}:spinner{bw}] {w}Planting {bg}#{Planter.template}{x}".x
      spinners = TTY::Spinner::Multi.new(title, format: :dots, success_mark: '{bg}✔{x}'.x, error_mark: '{br}✖{x}'.x)

      copy_spinner = spinners.register "{bw}[{by}:spinner{bw}] {w}Copy files and directories{x}".x
      # dir_spinner = spinners.register "{bw}[{by}:spinner{bw}] {w}Rename directories{x}".x
      var_spinner = spinners.register "{bw}[{by}:spinner{bw}] {w}Apply variables{x}".x
      git_spinner = spinners.register "{bw}[{by}:spinner{bw}] {w}Initialize git repo{x}".x if @git

      spinners.auto_spin
      copy_spinner.auto_spin
      res = copy_files

      if res.is_a?(String)
        spinners.error
        copy_spinner.error("(#{res})")
        Process.exit 1
      else
        copy_spinner.success
      end

      var_spinner.auto_spin

      res = update_files
      if res.is_a?(String)
        spinners.error
        var_spinner.error("(#{res})")
        Process.exit 1
      else
        var_spinner.success
      end

      if @git
        git_spinner.auto_spin

        res = add_git
        if res.is_a?(String)
          spinners.error
          git_spinner.error("(#{res})")
          Process.exit 1
        else
          git_spinner.success
        end
      end

      if Planter.config[:script]
        scripts = Planter.config[:script]
        scripts = [scripts] if scripts.is_a?(String)
        scripts.each do |script|
          s = Planter::Script.new(@basedir, Dir.pwd, script)
          s.run
        end
      end
    end

    def copy_files
      base = File.realdirpath(@basedir)
      path = File.join(base, '**/*')
      template_files = Dir.glob(path, File::FNM_DOTMATCH).reject do |file|
        file =~ %r{/(_scripts|\.git|config\.yml$|\.{1,2}$)}
      end
      template_files.sort_by!(&:length)

      template_files.each do |file|
        new_file = ".#{file.sub(/^#{base}/, '').apply_variables}"

        FileUtils.mkdir_p(File.dirname(new_file))
        FileUtils.cp(file, new_file) unless File.directory?(file) || File.exist?(new_file)
      end

      true
    rescue StandardError => e
      Planter.notify("#{e}\n#{e.backtrace}", :debug)
      'Error copying files/directories'
    end

    def update_files
      files = Dir.glob('**/*', File::FNM_DOTMATCH).reject { |f| File.directory?(f) || f =~ /^(\.git|config\.yml)/ }

      files.each do |file|
        type = `file #{file}`
        case type
        when /Apple binary property list/
          `plutil -convert xml1 #{file}`
        end
        content = IO.read(file)
        content.apply_variables!

        File.open(file, 'w') { |f| f.puts content }
      end

      true
    rescue StandardError => e
      Planter.notify("#{e}\n#{e.backtrace}", :debug)
      'Error updating files/directories'
    end

    def add_git
      return if File.directory?('.git')

      res = pass_fail('git init')
      res = pass_fail('git add .') if res
      res = pass_fail('git commit -a -m "initial commit"') if res
      res = pass_fail('git tag -a 0.0.1 -m "v0.0.1"') if res

      raise StandardError unless res

      true
    rescue StandardError => e
      Planter.notify("#{e}\n#{e.backtrace}", :debug)
      'Error initializing git'
    end
  end
end
