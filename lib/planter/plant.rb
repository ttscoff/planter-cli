# frozen_string_literal: true

module Planter
  # Primary class
  class Plant
    ## Initialize a new Plant object
    def initialize(template = nil, variables = nil)
      Planter.variables = variables if variables&.is_a?(Hash)
      Planter.config = template if template

      @basedir = File.join(Planter::BASE_DIR, Planter.template)
      @target = Planter.target || Dir.pwd

      @git = Planter.config[:git] || false
      @debug = Planter.debug

      # Coerce any existing variables (like from the command line) to the types
      # defined in configuration
      coerced = {}
      Planter.variables.each do |k, v|
        cfg_var = Planter.config[:variables].select { |var| k = var[:key] }
        next unless cfg_var.count.positive?

        var = cfg_var.first
        type = var[:type].normalize_type
        coerced[k] = v.coerce(type)
      end
      coerced.each { |k, v| Planter.variables[k] = v }

      # Ask user for any variables not already defined
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

      @files = FileList.new(@basedir)
    end

    ##
    ## Plant the template to current directory
    ##
    def plant
      Dir.chdir(@target)
      # title = "{bw}[{bg}:spinner{bw}] {w}Planting {bg}#{Planter.template}{x}".x
      # spinners = TTY::Spinner::Multi.new(title, hide_cursor: true, format: :dots, success_mark: '{bg}✔{x}'.x, error_mark: '{br}✖{x}'.x)

      # copy_spinner = spinners.register '{bw}[{by}:spinner{bw}] {w}Copy files and directories{x}'.x
      # var_spinner = spinners.register '{bw}[{by}:spinner{bw}] {w}Apply variables{x}'.x
      # git_spinner = spinners.register '{bw}[{by}:spinner{bw}] {w}Initialize git repo{x}'.x if @git

      spinner = TTY::Spinner.new('{bw}[{by}:spinner{bw}] {w}:title'.x, hide_cursor: true, format: :dots, success_mark: '{bg}✔{x}'.x, error_mark: '{br}✖{x}'.x)
      spinner.auto_spin
      spinner.update(title: 'Copying files')
      res = copy_files
      # spinners.auto_spin
      # copy_spinner.auto_spin
      if res.is_a?(String)
        # spinners.error
        spinner.error("(#{res})")
        Process.exit 1
      else
        # spinner.success
      end

      # var_spinner.auto_spin
      spinner.update(title: 'Applying variables')

      res = update_files
      if res.is_a?(String)
        # spinners.error
        spinner.error("(#{res})")
        Process.exit 1
      else
        # spinner.success
      end

      if @git
        # git_spinner.auto_spin
        spinner.update(title: 'Initializing git repo')
        res = add_git
        if res.is_a?(String)
          # spinners.error
          spinner.error("(#{res})")
          Process.exit 1
        else
          # git_spinner.success
        end
      end

      if Planter.config[:script]
        spinner.update(title: 'Running script')

        scripts = Planter.config[:script]
        scripts = [scripts] if scripts.is_a?(String)
        scripts.each do |script|
          s = Planter::Script.new(@basedir, Dir.pwd, script)
          s.run
        end
      end
      spinner.update(title: '😄')
      spinner.success(' Planting complete!')
    end

    ##
    ## Copy files from template directory, renaming if %%template vars%% exist in title
    ##
    ## @return     true if successful, otherwise error description
    ##
    def copy_files
      @files.copy
      true
    end

    ##
    ## Update content of files in new directory using template variables
    ##
    def update_files
      files = Dir.glob('**/*', File::FNM_DOTMATCH).reject { |f| File.directory?(f) || f =~ /^(\.git|config\.yml)/ }

      files.each do |file|
        type = `file #{file}`
        case type.sub(/^#{Regexp.escape(file)}: /, '').split(/:/).first
        when /Apple binary property list/
          `plutil -convert xml1 #{file}`
        when /data/
          next
        else
          next if File.binary?(file)
        end

        content = IO.read(file)
        new_content = content.apply_variables

        if new_content =~ /^.{.4}merge *\n/
          new_content.gsub!(%r{^.{.4}/?merge *.{,4}\n}, '')
        end

        unless content == new_content
          Planter.notify("Applying variables to #{file}", :debug)
          File.open(file, 'w') { |f| f.puts new_content }
        end
      end

      true
    rescue StandardError => e
      Planter.notify("#{e}\n#{e.backtrace}", :debug)
      'Error updating files/directories'
    end

    ##
    ## Initialize a git repo and create initial commit/tag
    ##
    ## @return     true if successful, otherwise an error description
    ##
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
