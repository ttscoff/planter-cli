# frozen_string_literal: true

module Planter
  # Script handler
  class Script
    attr_reader :script

    ##
    ## Initialize a Script object
    ##
    ## @param      template_dir  [String] Path to the current template dir
    ## @param      output_dir    [String] The planted template directory
    ## @param      script        [String] The script name
    ##
    def initialize(template_dir, output_dir, script)
      found = find_script(template_dir, script)
      raise ScriptError.new("Script #{script} not found") unless found

      @script = found

      raise ScriptError.new("Output directory #{output_dir} not found") unless File.directory?(output_dir)

      @template_directory = template_dir
      @directory = output_dir
    end

    ##
    ## Locate a script in either the base directory or template directory
    ##
    ## @param      template_dir  [String] The template dir
    ## @param      script        [String] The script name
    ##
    ## @return     [String] Path to script
    ##
    def find_script(template_dir, script)
      parts = Shellwords.split(script)
      script_name = parts[0]
      args = parts[1..-1].join(' ')
      return script if File.exist?(script_name)

      if File.exist?(File.join(template_dir, '_scripts', script_name))
        return "#{File.join(template_dir, '_scripts', script_name)} #{args}".strip
      elsif File.exist?(File.join(Planter.base_dir, 'scripts', script_name))
        return "#{File.join(Planter.base_dir, 'scripts', script_name)} #{args}".strip
      end

      nil
    end

    ##
    ## Execute script, passing template directory and output directory as arguments $1 and $2
    ##
    ## @return     [Boolean] true if success?
    ##
    def run
      `#{@script} "#{@template_directory}" "#{@directory}"`

      Planter.notify("Error running #{File.basename(@script)}", :error, exit_code: 128) unless $?.success?

      true
    end
  end
end
