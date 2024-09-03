# frozen_string_literal: true

module Planter
  class Config < Hash
    attr_reader :template

    ##
    ## Initialize a new Config object for a template
    ##
    ## @param template [String] template name
    ##
    def initialize
      # super()

      @config = initial_config
      @template = Planter.template

      load_template

      die('No configuration found', :config) unless @config

      generate_accessors
    end

    def initial_config
      {
        defaults: false,
        git_init: false,
        files: { '_planter.yml' => 'ignore' },
        color: true,
        preserve_tags: nil,
        variables: nil,
        replacements: nil,
        repo: false,
        patterns: nil,
        debug: false,
        script: nil
      }
    end

    def to_s
      @config.to_s
    end

    def [](key)
      @config[key]
    end

    ##
    ## Set a config option
    ##
    ## @param key [String,Symbol] key
    ## @param value [String] value
    ##
    def []=(key, value)
      @config[key.to_sym] = value
      generate_accessors
    end

    private

    ##  Generate accessors for configuration
    def generate_accessors
      @config.each do |k, v|
        define_singleton_method(k) { v } unless respond_to?(k)
      end
    end

    ##
    ## Build a configuration from template name
    ##
    ## @param      template  [String] The template name
    ##
    ## @return     [Hash] Configuration object
    ##
    ## @api private
    ##
    def load_template
      Planter.variables ||= {}
      FileUtils.mkdir_p(Planter.base_dir) unless File.directory?(Planter.base_dir)
      base_config = File.join(Planter.base_dir, 'planter.yml')

      if File.exist?(base_config)
        @config = @config.deep_merge(YAML.load(IO.read(base_config)).symbolize_keys)
      else
        default_base_config = {
          defaults: false,
          git_init: false,
          files: { '_planter.yml' => 'ignore' },
          color: true,
          preserve_tags: true
        }
        begin
          File.open(base_config, 'w') { |f| f.puts(YAML.dump(default_base_config.stringify_keys)) }
        rescue Errno::ENOENT
          Planter.notify("Unable to create #{base_config}", :error)
        end
        @config = @config.deep_merge(default_base_config).symbolize_keys
        Planter.notify("New configuration written to #{base_config}, edit as needed.", :warn)
      end

      base_dir = File.join(Planter.base_dir, 'templates', @template)
      unless File.directory?(base_dir)
        notify("Template #{@template} does not exist", :error)
        res = Prompt.yn('Create template directory', default_response: false)

        die('Canceled') unless res

        FileUtils.mkdir_p(base_dir)
      end

      load_template_config

      config_array_to_hash(:files) if @config[:files].is_a?(Array)
      config_array_to_hash(:replacements) if @config[:replacements].is_a?(Array)
    rescue Psych::SyntaxError => e
      die("Parse error in configuration file:\n#{e.message}", :config)
    end

    ##
    ## Load a template-specific configuration
    ##
    ## @return     [Hash] updated config object
    ##
    ## @api private
    ##
    def load_template_config
      base_dir = File.join(Planter.base_dir, 'templates', @template)
      config = File.join(base_dir, '_planter.yml')

      unless File.exist?(config)
        default_config = {
          variables: [
            key: 'var_key',
            prompt: 'CLI Prompt',
            type: '[string, float, integer, number, date]',
            value: '(optional, force value, can include variables. Empty to prompt. For date type: today, now, etc.)',
            default: '(optional default value, leave empty or remove key for no default)',
            min: '(optional, for number type set a minimum value)',
            max: '(optional, for number type set a maximum value)'
          ],
          git_init: false,
          files: {
            '*.tmp' => 'ignore',
            '*.bak' => 'ignore',
            '.DS_Store' => 'ignore'
          }
        }
        FileUtils.mkdir_p(base_dir)
        File.open(config, 'w') { |f| f.puts(YAML.dump(default_config.stringify_keys)) }
        Planter.notify("New configuration written to #{config}, please edit.", :warn)
        Process.exit 0
      end
      @config = @config.deep_merge(YAML.load(IO.read(config)).symbolize_keys)
    end

    ##
    ## Convert an errant array to a hash
    ##
    ## @param      key   [Symbol] The key in @config to convert
    ##
    ## @api private
    ##
    def config_array_to_hash(key)
      files = {}
      @config[key].each do |k|
        files[k.keys.first] = k.values.first
      end
      @config[key] = files
    end
  end
end
