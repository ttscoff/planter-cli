# frozen_string_literal: true

require 'chronic'
require 'tty-which'

module Planter
  # Individual question
  module Prompt
    class Question
      attr_reader :key, :type, :min, :max, :prompt, :gum, :condition, :default

      ##
      ## Initializes the given question.
      ##
      ## @param      question  [Hash] The question with key, prompt, and type,
      ##                       optionally default, min and max
      ##
      ## @return     [Question] the question object
      ##
      def initialize(question)
        @key = question[:key].to_var
        @type = question[:type].to_s.normalize_type
        @min = question[:min]&.to_f || 1
        @max = question[:max]&.to_f || 10
        @prompt = question[:prompt] || nil
        @default = question[:default]
        @value = question[:value]
        @gum = TTY::Which.exist?('gum')
      end

      ##
      ## Ask the question, prompting for input based on type
      ##
      ## @return     [Number, String] the response based on @type
      ##
      def ask
        return nil if @prompt.nil?

        res = case @type
              when :integer
                read_number(integer: true)
              when :float
                read_number
              when :string
                read_line
              when :date
                if @value
                  date_default
                else
                  read_date
                end
              when :class || :module
                read_line.to_class_name
              end
        Planter.notify("{dw}#{prompt}: {dy}#{res}{x}", :debug)
        res
      end

      private

      ##
      ## Read a numeric entry using gum or TTY::Reader
      ##
      ## @param      [Boolean] integer  Round result to nearest integer
      ##
      ## @return     [Number] integer response
      ##
      ##
      def read_number(integer: false)
        default = @default ? " {bw}[#{@default}]" : ''
        Planter.notify("{by}#{@prompt} {xc}({bw}#{@min}{xc}-{bw}#{@max}{xc})#{default}")

        res = @gum ? read_number_gum : read_line_tty

        return @default unless res

        res = integer ? res.to_f.round : res.to_f

        res = read_number if res < @min || res > @max
        res
      end

      def date_default
        default = @value ? @value : @default
        return nil unless default

        case default
        when /^(no|ti)/
          Time.now.strftime('%Y-%m-%d %H:%M')
        when /^(to|da)/
          Time.now.strftime('%Y-%m-%d')
        when /^%/
          Time.now.strftime(@default)
        else
          Chronic.parse(default)
        end
      end

      def read_date(prompt: nil)
        prompt ||= @prompt
        default = date_default

        default = default ? " {bw}[#{default}]" : ''
        Planter.notify("{by}#{prompt} (natural language)#{default}")
        line = @gum ? read_line_gum : read_line_tty
        return @default unless line

        Chronic.parse(line)
      end

      ##
      ## Reads a line.
      ##
      ## @param      prompt  [String] If not nil, will trigger
      ##                     asking for a secondary response
      ##                     until a blank entry is given
      ##
      ## @return     [String] the single-line response
      ##
      def read_line(prompt: nil)
        output = []
        prompt ||= @prompt
        default = @default ? " {bw}[#{@default}]" : ''
        Planter.notify("{by}#{prompt}#{default}")

        res = @gum ? read_line_gum : read_line_tty

        return @default unless res

        res
      end

      ##
      ## Reads multiple lines.
      ##
      ## @param      prompt  [String] if not nil, will trigger
      ##                     asking for a secondary response
      ##                     until a blank entry is given
      ##
      ## @return     [String] the multi-line response
      ##
      def read_lines(prompt: nil)
        output = []
        prompt ||= @prompt
        save = @gum ? 'Ctrl-J for newline, Enter' : 'Ctrl-D'
        Planter.notify("{by}#{prompt} {c}({bw}#{save}{c} to save)'")
        res = @gum ? read_multiline_gum(prompt) : read_mutliline_tty

        return @default unless res

        res.strip
      end

      ##
      ## Read a numeric entry using gum
      ##
      ## @param      [Boolean] integer  Round result to nearest integer
      ##
      ## @return     [Number] integer response
      ##
      ##
      def read_number_gum
        trap("SIGINT") { exit! }
        res = `gum input --placeholder "#{@min}-#{@max}"`.strip
        return nil if res.strip.empty?

        res
      end

      ##
      ## Read a single line entry using TTY::Reader
      ##
      ## @param      [Boolean] integer  Round result to nearest integer
      ##
      ## @return     [Number] integer response
      ##
      def read_line_tty
        trap("SIGINT") { exit! }
        reader = TTY::Reader.new
        res = reader.read_line(">> ").strip
        return nil if res.empty?

        res
      end

      ##
      ## Read a single line entry using gum
      ##
      ## @param      [Boolean] integer  Round result to nearest integer
      ##
      ## @return     [Number] integer response
      ##
      def read_line_gum
        trap("SIGINT") { exit! }
        res = `gum input --placeholder "(blank to use default)"`.strip
        return nil if res.empty?

        res
      end

      ##
      ## Read a multiline entry using TTY::Reader
      ##
      ## @return     [string] multiline input
      ##
      def read_mutliline_tty
        trap("SIGINT") { exit! }
        reader = TTY::Reader.new
        res = reader.read_multiline
        res.join("\n").strip
      end

      ##
      ## Read a multiline entry using gum
      ##
      ## @return     [string] multiline input
      ##
      def read_multiline_gum(prompt)
        trap("SIGINT") { exit! }
        width = TTY::Screen.cols > 80 ? 80 : TTY::Screen.cols
        `gum write --placeholder "#{prompt}" --width 80 --char-limit 0`.strip
      end
    end

    ##
    ## Ask a yes or no question in the terminal
    ##
    ## @param      question          [String] The question
    ##                               to ask
    ## @param      default_response  [Boolean]   default
    ##                               response if no input
    ##
    ## @return     [Boolean] yes or no
    ##
    def yn(question, default_response: false)
      $stdin.reopen('/dev/tty')

      default = if default_response.is_a?(String)
                  default_response =~ /y/i ? true : false
                else
                  default_response
                end

      # if this isn't an interactive shell, answer default
      return default unless $stdout.isatty

      # clear the buffer
      if ARGV&.length
        ARGV.length.times do
          ARGV.shift
        end
      end
      system 'stty cbreak'

      options = unless default.nil?
                  "{w}[#{default ? "{bg}Y{w}/{bw}n" : "{bw}y{w}/{bg}N"}{w}]"
                else
                  "{w}[{bw}y{w}/{bw}n{w}]"
                end
      $stdout.syswrite "{bw}#{question.sub(/\?$/, '')} #{options}{bw}? {x}".x
      res = $stdin.sysread 1
      puts
      system 'stty cooked'

      res.chomp!
      res.downcase!

      return default if res.empty?

      res =~ /y/i ? true : false
    end
  end
end
