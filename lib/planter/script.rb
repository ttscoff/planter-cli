# frozen_string_literal: true

module Planter
  class Script
    attr_reader :script

    def initialize(template_dir, output_dir, script)
      found = find_script(template_dir, output_dir, script)
      Planter.notify("Script #{script} not found", :error, exit_code: 10) unless found
      @script = found

      Planter.notify("Directory #{output_dir} not found", :error, exit_code: 10) unless File.directory?(output_dir)
      @directory = output_dir
    end

    def find_script(template_dir, script)
      base_dir = Planter::BASE_DIR
      return File.join(template_dir, '_scripts', script) if File.exist?(File.join(template_dir, '_scripts', script))
      return File.join(base_dir, 'scripts', script) if File.exist?(File.join(base_dir, 'scritps', script))
      return nil
    end

    def run
      `#{@script}`
      unless $CHILD_STATUS.success?
        Planter.notify("Error running #{File.basename(@script)}", :error, exit_code: 128)
      end

      return true
    end
  end
end

