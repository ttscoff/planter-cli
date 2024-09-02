require 'spec_helper'

describe ::String do
  describe '.to_var' do
    it 'turns string into snake-cased symbol' do
      expect('This is a test string'.to_var).to be :this_is_a_test_string
    end
  end

  describe '.to_slug' do
    it 'slugifies a string' do
      expect('This is a test string'.to_slug).to match(/this-is-a-test-string/)
    end

    it 'slugifies bad characters' do
      expect('This: #is a test string!'.to_slug).to match(/this-colon-hash-is-a-test-string-bang/)
    end
  end

  describe '.to_class_name' do
    it 'converts string to CamelCase' do
      expect('this is a test string'.to_class_name).to eq 'ThisIsATestString'
    end

    it 'handles special characters' do
      expect('this: #is a test string!'.to_class_name).to eq 'ThisIsATestString'
    end
  end

  describe '.snake_case' do
    it 'converts CamelCase to snake_case' do
      expect('ThisIsATestString'.snake_case).to eq 'this_is_a_test_string'
    end

    it 'handles strings with spaces' do
      expect('This is a test string'.snake_case).to eq 'this_is_a_test_string'
    end

    it 'handles strings with special characters' do
      expect('This: #is a test string!'.snake_case).to eq 'this_is_a_test_string'
    end
  end

  describe '.camel_case' do
    it 'converts snake_case to CamelCase' do
      expect('this_is_a_test_string'.camel_case).to eq 'thisIsATestString'
    end

    it 'handles strings with spaces' do
      expect('this is a test string'.camel_case).to eq 'thisIsATestString'
    end

    it 'handles strings with special characters' do
      expect('this: #is a test string!'.camel_case).to eq 'thisIsATestString'
    end
  end

  describe '.title_case' do
    it 'converts a string to Title Case' do
      expect('this is a test string'.title_case).to eq 'This Is A Test String'
    end

    it 'handles strings with special characters' do
      expect('this: #is a test string!'.title_case).to eq 'This: #Is A Test String!'
    end

    it 'handles mixed case strings' do
      expect('ThIs Is A TeSt StRiNg'.title_case).to eq 'This Is A Test String'
    end
  end

  describe '.apply_variables' do
    it 'replaces placeholders with variable values' do
      template = 'Hello, %%name%%!'
      variables = { name: 'World' }
      expect(template.apply_variables(variables: variables)).to eq 'Hello, World!'
    end

    it 'handles multiple variables' do
      template = 'Hello, %%first_name%% %%last_name%%!'
      variables = { first_name: 'John', last_name: 'Doe' }
      expect(template.apply_variables(variables: variables)).to eq 'Hello, John Doe!'
    end

    it 'handles missing variables gracefully' do
      template = 'Hello, %%name%%!'
      variables = {}
      expect(template.apply_variables(variables: variables)).to eq 'Hello, %%name%%!'
    end

    it 'handles variables with special characters' do
      template = 'Hello, %%name%%!'
      variables = { name: 'John #Doe' }
      expect(template.apply_variables(variables: variables)).to eq 'Hello, John #Doe!'
    end

    it 'handles modifiers' do
      template = 'Hello, %%title:upper%% %%name:title%%!'
      variables = { title: 'Mr.', name: 'john do' }
      expect(template.apply_variables(variables: variables)).to eq 'Hello, MR. John Do!'
    end

    it 'operates in place' do
      template = 'Hello, %%title:upper%% %%name:title%%!'
      variables = { title: 'Mr.', name: 'john do' }
      template.apply_variables!(variables: variables)
      expect(template).to eq 'Hello, MR. John Do!'
    end

    it 'handles last_only' do
      template = 'Hello, %%title%% %%title:upper%%!'
      variables = { title: 'project title' }
      expect(template.apply_variables(variables: variables, last_only: true)).to eq 'Hello, %%title%% PROJECT TITLE!'
    end
  end

  describe '.apply_logic' do
    it 'applies a single logic replacement' do
      template = 'Hello %%if language == ruby%%World%%else%%There%%end%%!'
      logic = { language: 'ruby' }
      expect(template.apply_logic(logic)).to eq 'Hello World!'
    end

    it 'handles quotes in logic' do
      template = 'Hello %%if language == "ruby"%%World%%else%%There%%end%%!'
      logic = { language: 'ruby' }
      expect(template.apply_logic(logic)).to eq 'Hello World!'
    end

    it 'handles no logic replacements' do
      template = 'Hello, World!'
      logic = {}
      expect(template.apply_logic(logic)).to eq 'Hello, World!'
    end

    it 'Operates in place' do
      template = 'Hello %%if language == "ruby"%%World%%else%%There%%end%%!'
      logic = { language: 'ruby' }
      template.apply_logic!(logic)
      expect(template).to eq 'Hello World!'
    end
  end

  describe '.apply_regexes' do
    it 'applies a single regex replacement' do
      template = 'Hello, World!'
      regexes = { /World/ => 'Universe' }
      expect(template.apply_regexes(regexes)).to eq 'Hello, Universe!'
    end

    it 'applies multiple regex replacements' do
      template = 'Hello, World! Welcome to the World!'
      regexes = { /World/ => 'Universe', /Welcome/ => 'Greetings' }
      expect(template.apply_regexes(regexes)).to eq 'Hello, Universe! Greetings to the Universe!'
    end

    it 'handles no regex replacements' do
      template = 'Hello, World!'
      regexes = {}
      expect(template.apply_regexes(regexes)).to eq 'Hello, World!'
    end

    it 'handles special characters in regex' do
      template = 'Hello, World! #Welcome to the World!'
      regexes = { /#Welcome/ => 'Greetings' }
      expect(template.apply_regexes(regexes)).to eq 'Hello, World! Greetings to the World!'
    end

    it 'Operates in place' do
      template = 'Hello, World! #Welcome to the World!'
      regexes = { /#Welcome/ => 'Greetings' }
      template.apply_regexes!(regexes)
      expect(template).to eq 'Hello, World! Greetings to the World!'
    end
  end

  describe '.ext' do
    it 'applies an extension' do
      expect("filename.rb".ext('txt')).to eq 'filename.txt'
    end

    it 'ignores an existing extension' do
      expect("filename.rb".ext('rb')).to eq 'filename.rb'
    end
  end

  describe '.normalize_type' do
    it 'normalizes a date type' do
      expect("da".normalize_type.to_s).to eq "date"
    end

    it 'normalizes an integer type' do
      expect("int".normalize_type.to_s).to eq "integer"
    end

    it 'normalizes a float type' do
      expect("f".normalize_type.to_s).to eq "float"
    end

    it 'normalizes a multiline type' do
      expect("para".normalize_type.to_s).to eq "multiline"
    end

    it 'normalizes a class type' do
      expect("cl".normalize_type.to_s).to eq "class"
    end

    it 'normalizes a multiple choice type' do
      expect("choice".normalize_type.to_s).to eq "choice"
    end
  end

  describe '.normalize_operator' do
    it 'normalizes a copy operator' do
      expect("copy".normalize_operator.to_s).to eq "copy"
    end
  end

  describe '.coerce' do
    it 'coerces a date type' do
      expect("now".coerce(:date)).to match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}/)
    end

    it 'coerces an integer type' do
      expect("10".coerce(:integer)).to eq 10
    end

    it 'coerces a float type' do
      expect("10.0".coerce(:float)).to eq 10.0
    end

    it 'coerces a multiline type' do
      expect("multi\nline".coerce(:multiline)).to eq "multi\nline"
    end

    it 'coerces a class type' do
      expect("Some class".coerce(:class)).to eq "SomeClass"
    end
  end

  describe '.clean_encode!' do
    it 'cleans an encoded string' do
      s = "This is a test string"
      s.clean_encode!
      expect(s).to eq "This is a test string"
    end
  end

  describe '.highlight_character' do
    it 'highlights characters' do
      s = "(o)ption 1 (s)econd option"
      expect(s.highlight_character).to eq "{dw}({xbw}o{dw}){xw}ption 1 {dw}({xbw}s{dw}){xw}econd option"
    end

    it 'highlights characters with default option' do
      s = "(o)ption 1 (s)econd option"
      expect(s.highlight_character(default: 's')).to eq "{dw}({xbw}o{dw}){xw}ption 1 {dw}({xbc}s{dw}){xw}econd option"
    end
  end
end
