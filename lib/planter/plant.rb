# frozen_string_literal: true

module Planter
  # Primary class
  class Plant
    attr_reader :config

    ##
    ## Initialize a new Plant object
    ##
    ## @param      template   [String] the template name
    ## @param      variables  [Hash] Pre-populated variables
    ##
    def initialize(template = nil, variables = nil)
      Planter.variables = variables if variables.is_a?(Hash)
      # Planter.config = template if template
      template ||= Planter.template
      die('No template specified', :config) unless template

      @config = Planter::Config.new

      @basedir = File.join(Planter.base_dir, 'templates', @config.template)
      @target = Planter.target || Dir.pwd

      @git = @config.git_init || false
      @debug = Planter.debug
      @repo = @config.repo || false

      # Coerce any existing variables (like from the command line) to the types
      # defined in configuration
      coerced = {}
      Planter.variables.each do |k, v|
        cfg_var = @config.variables.select { |var| k = var[:key] }
        next unless cfg_var.count.positive?

        var = cfg_var.first
        type = var[:type].normalize_type
        coerced[k] = v.coerce(type)
      end
      coerced.each { |k, v| Planter.variables[k] = v }

      # Ask user for any variables not already defined
      @config.variables.each do |var|
        key = var[:key].to_var
        next if Planter.variables.keys.include?(key)

        q = Planter::Prompt::Question.new(
          key: key,
          prompt: var[:prompt] || var[:key],
          type: var[:type].normalize_type || :string,
          default: var[:default],
          value: var[:value],
          min: var[:min],
          max: var[:max],
          choices: var[:choices] || nil,
          date_format: var[:date_format] || nil
        )
        answer = q.ask
        if answer.nil?
          Planter.notify("Missing value #{key}", :error, exit_code: 15) unless var[:default]

          answer = var[:default]
        end

        Planter.variables[key] = answer.apply_all
      end

      git_pull if @repo

      @files = FileList.new(@basedir)
    end

    ##
    ## Expand GitHub name to full path
    ##
    ## @example Pass a GitHub-style repo path and get full url
    ##   expand_repo("ttscoff/planter-cli") #=> https://github.com/ttscoff/planter-cli.git
    ##
    ## @param      repo  [String] The repo
    ##
    ## @return     { description_of_the_return_value }
    ##
    def expand_repo(repo)
      repo =~ %r{(?!=http)\w+/\w+} ? "https://github.com/#{repo}.git" : repo
    end

    ##
    ## Directory for repo, subdirectory of template
    ##
    ## @return     [String] repo path
    ##
    def repo_dir
      File.join(@basedir, File.basename(@repo).sub(/\.git$/, ''))
    end

    ##
    ## Pull or clone a git repo
    ##
    ## @return     [String] new base directory
    ##
    def git_pull
      Planter.spinner.update(title: 'Pulling git repo')

      die('`git` executable not found', :git) unless TTY::Which.exist?('git')

      pwd = Dir.pwd
      @repo = expand_repo(@repo)

      if File.exist?(repo_dir)
        Dir.chdir(repo_dir)
        die("Directory #{repo_dir} exists but is not git repo", :git) unless File.exist?('.git')

        res = `git pull`
        die("Error pulling #{@repo}:\n#{res}", :git) unless $?.success?
      else
        Dir.chdir(@basedir)
        res = `git clone "#{@repo}" "#{repo_dir}"`
        die("Error cloning #{@repo}:\n#{res}", :git) unless $?.success?
      end
      Dir.chdir(pwd)
      @basedir = repo_dir
    rescue StandardError => e
      die("Error pulling #{@repo}:\n#{e.message}", :git)
    end

    ##
    ## Plant the template to current directory
    ##
    def plant
      Dir.chdir(@target)

      Planter.spinner.auto_spin
      Planter.spinner.update(title: 'Copying files')
      res = copy_files
      if res.is_a?(String)
        Planter.spinner.error("(#{res})")
        Process.exit 1
      end

      Planter.spinner.update(title: 'Applying variables')

      res = update_files
      if res.is_a?(String)
        Planter.spinner.error('(Error)')
        Planter.notify(res, :error, exit_code: 1)
      end

      if @git
        die('`git` executable not found', :git) unless TTY::Which.exist?('git')

        Planter.spinner.update(title: 'Initializing git repo')
        res = add_git
        if res.is_a?(String)
          Planter.spinner.error('(Error)')
          Planter.notify(res, :error, exit_code: 1)
        end
      end

      if @config.script
        Planter.spinner.update(title: 'Running script')

        scripts = @config.script
        scripts = [scripts] if scripts.is_a?(String)
        scripts.each do |script|
          s = Planter::Script.new(@basedir, Dir.pwd, script)
          s.run
        end
      end
      Planter.spinner.update(title: 'Planting complete!')
      Planter.spinner.success
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
        next if File.binary?(file)

        content = IO.read(file)

        new_content = content.apply_all

        new_content.gsub!(%r{^.{.4}/?merge *.{,4}\n}, '') if new_content =~ /^.{.4}merge *\n/

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
