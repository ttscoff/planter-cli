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
      found = find_script(template_dir, output_dir, script)
      Planter.notify("Script #{script} not found", :error, exit_code: 10) unless found
      @script = found

      Planter.notify("Directory #{output_dir} not found", :error, exit_code: 10) unless File.directory?(output_dir)
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
      base_dir = Planter::BASE_DIR
      return File.join(template_dir, '_scripts', script) if File.exist?(File.join(template_dir, '_scripts', script))

      return File.join(base_dir, 'scripts', script) if File.exist?(File.join(base_dir, 'scritps', script))

      nil
    end

    ##
    ## Execute script, passing template directory and output directory as arguments $1 and $2
    ##
    ## @return     [Boolean] true if success?
    ##
    def run
      `#{@script} "#{@template_directory}" "#{@directory}"`

      Planter.notify("Error running #{File.basename(@script)}", :error, exit_code: 128) unless $CHILD_STATUS.success?

      true
    end
  end
end
