# encoding: utf-8

RSpec.describe TTY::Prompt, '#select' do

  subject(:prompt) { TTY::TestPrompt.new }

  let(:symbols) { TTY::Prompt::Symbols.symbols }

  def output_helper(prompt, choices, active, options = {})
    hint = options.fetch(:hint, "Use arrow keys, press Enter to select")
    init = options.fetch(:init, false)
    out = ""
    out << (init ? "\e[?25l#{prompt} \e[90m(#{hint})\e[0m\n" : "#{prompt} \n")
    out << choices.map do |c|
      (c == active ? "\e[32m#{symbols[:pointer]} #{c}\e[0m" : "  #{c}")
    end.join("\n")
    out << "\e[2K\e[1G\e[1A" * choices.count
    out << "\e[2K\e[1G"
    out
  end

  it "selects by default first option" do
    choices = %w(Large Medium Small)
    prompt.input << "\r"
    prompt.input.rewind
    expect(prompt.select('What size?', choices)).to eq('Large')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} Large\e[0m\n",
      "  Medium\n",
      "  Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mLarge\e[0m\n\e[?25h"
    ].join)
  end

  it "allows navigation using events without errors" do
    choices = %w(Large Medium Small)
    prompt.input << "j" << "\r"
    prompt.input.rewind
    prompt.on(:keypress) do |event|
      prompt.trigger(:keydown) if event.value == "j"
    end
    expect { prompt.select('What size?', choices) }.not_to output.to_stderr
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} Large\e[0m\n",
      "  Medium\n",
      "  Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \n",
      "  Large\n",
      "\e[32m#{symbols[:pointer]} Medium\e[0m\n",
      "  Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mMedium\e[0m\n\e[?25h"
    ].join)
  end

  it "sets choice name and value" do
    choices = {large: 1, medium: 2, small: 3}
    prompt.input << " "
    prompt.input.rewind
    expect(prompt.select('What size?', choices, default: 1)).to eq(1)
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} large\e[0m\n",
      "  medium\n",
      "  small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mlarge\e[0m\n\e[?25h"
    ].join)
  end

  it "sets choice name through DSL" do
    prompt.input << " "
    prompt.input.rewind
    value = prompt.select('What size?') do |menu|
              menu.choice "Large"
              menu.choice "Medium"
              menu.choice "Small"
            end
    expect(value).to eq('Large')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} Large\e[0m\n",
      "  Medium\n",
      "  Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mLarge\e[0m\n\e[?25h"
    ].join)
  end

  it "sets choice name & value through DSL" do
    prompt.input << " "
    prompt.input.rewind
    value = prompt.select('What size?') do |menu|
              menu.choice :large, 1
              menu.choice :medium, 2
              menu.choice :small, 3
            end
    expect(value).to eq(1)
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} large\e[0m\n",
      "  medium\n",
      "  small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mlarge\e[0m\n\e[?25h"
    ].join)
  end

  it "sets choices and single choice through DSL" do
    prompt.input << " "
    prompt.input.rewind
    value = prompt.select('What size?') do |menu|
              menu.choice 'Large'
              menu.choices %w(Medium Small)
            end
    expect(value).to eq('Large')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} Large\e[0m\n",
      "  Medium\n",
      "  Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mLarge\e[0m\n\e[?25h"
    ].join)
  end

  it "sets choice name & value through DSL" do
    prompt.input << " "
    prompt.input.rewind
    value = prompt.select('What size?') do |menu|
              menu.default 2
              menu.enum '.'

              menu.choice :large, 1
              menu.choice :medium, 2
              menu.choice :small, 3
            end
    expect(value).to eq(2)
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Use arrow or number (1-3) keys, press Enter to select)\e[0m\n",
      "  1. large\n",
      "\e[32m#{symbols[:pointer]} 2. medium\e[0m\n",
      "  3. small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mmedium\e[0m\n\e[?25h"
    ].join)
  end

  it "sets choice value to proc and executes it" do
    prompt.input << " "
    prompt.input.rewind
    value = prompt.select('What size?', default: 2, enum: ')') do |menu|
              menu.choice :large, 1
              menu.choice :medium do 'Good choice!' end
              menu.choice :small, 3
            end
    expect(value).to eq('Good choice!')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Use arrow or number (1-3) keys, press Enter to select)\e[0m\n",
      "  1) large\n",
      "\e[32m#{symbols[:pointer]} 2) medium\e[0m\n",
      "  3) small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mmedium\e[0m\n\e[?25h"
    ].join)
  end

  it "sets default option through hash syntax" do
    choices = %w(Large Medium Small)
    prompt.input << " "
    prompt.input.rewind
    expect(prompt.select('What size?', choices, default: 2, enum: '.')).to eq('Medium')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Use arrow or number (1-3) keys, press Enter to select)\e[0m\n",
      "  1. Large\n",
      "\e[32m#{symbols[:pointer]} 2. Medium\e[0m\n",
      "  3. Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mMedium\e[0m\n\e[?25h"
    ].join)
  end

  it "changes selected item color & marker" do
    choices = %w(Large Medium Small)
    prompt.input << " "
    prompt.input.rewind
    options = {active_color: :blue, help_color: :red, marker: '>'}
    value = prompt.select('What size?', choices, options)
    expect(value).to eq('Large')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[31m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[34m> Large\e[0m\n",
      "  Medium\n",
      "  Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[34mLarge\e[0m\n\e[?25h"
    ].join)
  end

  it "changes help text" do
    choices = %w(Large Medium Small)
    prompt.input << " "
    prompt.input.rewind
    value = prompt.select('What size?', choices, help: "(Bash keyboard)")
    expect(value).to eq('Large')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Bash keyboard)\e[0m\n",
      "\e[32m#{symbols[:pointer]} Large\e[0m\n",
      "  Medium\n",
      "  Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mLarge\e[0m\n\e[?25h"
    ].join)
  end

  it "changes help text through DSL" do
    choices = %w(Large Medium Small)
    prompt.input << " "
    prompt.input.rewind
    value = prompt.select('What size?') do |menu|
              menu.help "(Bash keyboard)"
              menu.choices choices
            end
    expect(value).to eq('Large')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat size? \e[90m(Bash keyboard)\e[0m\n",
      "\e[32m#{symbols[:pointer]} Large\e[0m\n",
      "  Medium\n",
      "  Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "What size? \e[32mLarge\e[0m\n\e[?25h"
    ].join)
  end

  it "sets prompt prefix" do
    prompt = TTY::TestPrompt.new(prefix: '[?] ')
    choices = %w(Large Medium Small)
    prompt.input << "\r"
    prompt.input.rewind
    expect(prompt.select('What size?', choices)).to eq('Large')
    expect(prompt.output.string).to eq([
      "\e[?25l[?] What size? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} Large\e[0m\n",
      "  Medium\n",
      "  Small",
      "\e[2K\e[1G\e[1A" * 3,
      "\e[2K\e[1G",
      "[?] What size? \e[32mLarge\e[0m\n\e[?25h"
    ].join)
  end

  it "paginates long selections" do
    choices = %w(A B C D E F G H)
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.select("What letter?", choices, per_page: 3, default: 4)
    expect(value).to eq('D')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat letter? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} D\e[0m\n",
      "  E\n",
      "  F\n",
      "\e[90m(Move up or down to reveal more choices)\e[0m",
      "\e[2K\e[1G\e[1A" * 4,
      "\e[2K\e[1G",
      "What letter? \e[32mD\e[0m\n\e[?25h",
    ].join)
  end

  it "paginates choices as hash object" do
    prompt = TTY::TestPrompt.new
    choices = {A: 1, B: 2, C: 3, D: 4, E: 5, F: 6, G: 7, H: 8}
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.select("What letter?", choices, per_page: 3, default: 4)
    expect(value).to eq(4)
    expect(prompt.output.string).to eq([
      "\e[?25lWhat letter? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} D\e[0m\n",
      "  E\n",
      "  F\n",
      "\e[90m(Move up or down to reveal more choices)\e[0m",
      "\e[2K\e[1G\e[1A" * 4,
      "\e[2K\e[1G",
      "What letter? \e[32mD\e[0m\n\e[?25h",
    ].join)
  end

  it "paginates long selections through DSL" do
    prompt = TTY::TestPrompt.new
    choices = %w(A B C D E F G H)
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.select("What letter?") do |menu|
              menu.per_page 3
              menu.page_help '(Wiggle thy finger up or down to see more)'
              menu.default 4

              menu.choices choices
            end
    expect(value).to eq('D')
    expect(prompt.output.string).to eq([
      "\e[?25lWhat letter? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} D\e[0m\n",
      "  E\n",
      "  F\n",
      "\e[90m(Wiggle thy finger up or down to see more)\e[0m",
      "\e[2K\e[1G\e[1A" * 4,
      "\e[2K\e[1G",
      "What letter? \e[32mD\e[0m\n\e[?25h",
    ].join)
  end

  it "doesn't cycle by default" do
    prompt = TTY::TestPrompt.new
    choices = %w(A B C)
    prompt.on(:keypress) { |e| prompt.trigger(:keydown) if e.value == "j" }
    prompt.input << "j" << "j" << "j" << "\r"
    prompt.input.rewind
    value = prompt.select("What letter?", choices)
    expect(value).to eq("C")
    expect(prompt.output.string).to eq(
      output_helper("What letter?", choices, "A", init: true) +
      output_helper("What letter?", choices, "B") +
      output_helper("What letter?", choices, "C") +
      output_helper("What letter?", choices, "C") +
      "What letter? \e[32mC\e[0m\n\e[?25h"
    )
  end

  it "cycles around when configured to do so" do
    prompt = TTY::TestPrompt.new
    choices = %w(A B C)
    prompt.on(:keypress) { |e| prompt.trigger(:keydown) if e.value == "j" }
    prompt.input << "j" << "j" << "j" << "\r"
    prompt.input.rewind
    value = prompt.select("What letter?", choices, cycle: true)
    expect(value).to eq("A")
    expect(prompt.output.string).to eq(
      output_helper("What letter?", choices, "A", init: true) +
      output_helper("What letter?", choices, "B") +
      output_helper("What letter?", choices, "C") +
      output_helper("What letter?", choices, "A") +
      "What letter? \e[32mA\e[0m\n\e[?25h"
    )
  end

  it "verifies default index format" do
    prompt = TTY::TestPrompt.new
    choices = %w(Large Medium Small)
    prompt.input << "\r"
    prompt.input.rewind

    expect {
      prompt.select('What size?', choices, default: '')
    }.to raise_error(TTY::Prompt::ConfigurationError, /in range \(1 - 3\)/)
  end

  it "doesn't paginate short selections" do
    prompt = TTY::TestPrompt.new
    choices = %w(A B C D)
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.select("What letter?", choices, per_page: 4, default: 1)
    expect(value).to eq('A')

    expect(prompt.output.string).to eq([
      "\e[?25lWhat letter? \e[90m(Use arrow keys, press Enter to select)\e[0m\n",
      "\e[32m#{symbols[:pointer]} A\e[0m\n",
      "  B\n",
      "  C\n",
      "  D",
      "\e[2K\e[1G\e[1A" * 4,
      "\e[2K\e[1G",
      "What letter? \e[32mA\e[0m\n\e[?25h",
    ].join)
  end

  it "verifies default index range" do
    prompt = TTY::TestPrompt.new
    choices = %w(Large Medium Small)
    prompt.input << "\r"
    prompt.input.rewind

    expect {
      prompt.select("What size?", choices, default: 10)
    }.to raise_error(TTY::Prompt::ConfigurationError, /`10` out of range \(1 - 3\)/)
  end

  context "with filter" do
    it "doesn't allow mixing enumeration and filter" do
      prompt = TTY::TestPrompt.new

      expect {
        prompt.select("What size?", [], enum: '.', filter: true)
      }.to raise_error(TTY::Prompt::ConfigurationError, "Enumeration can't be used with filter")
    end

    it "filters and chooses a uniquely matching entry, ignoring case" do
      prompt = TTY::TestPrompt.new
      choices = %w(Small Medium Large Huge)

      prompt.input << "U" << "g"  << "\r"
      prompt.input.rewind

      actual_value = prompt.select("What size?", choices, filter: true)
      expected_value = "Huge"

      expect(actual_value).to eql(expected_value)

      actual_prompt_output = prompt.output.string

      expected_prompt_output =
        "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select, and alphanumeric/underscore characters to filter)\e[0m\n" \
        "\e[32m‣ Small\e[0m\n" \
        "  Medium\n" \
        "  Large\n" \
        "  Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[90m(Filter: \"U\")\e[0m\n" \
        "\e[32m‣ Medium\e[0m\n" \
        "  Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[90m(Filter: \"Ug\")\e[0m\n" \
        "\e[32m‣ Huge\e[0m\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[32mHuge\e[0m\n" \
        "\e[?25h"

      expect(actual_prompt_output).to eql(expected_prompt_output)
    end

    it "filters and chooses the first of multiple matching entries" do
      prompt = TTY::TestPrompt.new
      choices = %w(Small Medium Large Huge)

      prompt.input << "g"  << "\r"
      prompt.input.rewind

      actual_value = prompt.select("What size?", choices, filter: true)
      expected_value = "Large"

      expect(actual_value).to eql(expected_value)

      actual_prompt_output = prompt.output.string
      expected_prompt_output =
        "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select, and alphanumeric/underscore characters to filter)\e[0m\n"\
        "\e[32m‣ Small\e[0m\n"\
        "  Medium\n"\
        "  Large\n"\
        "  Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[90m(Filter: \"g\")\e[0m\n"\
        "\e[32m‣ Large\e[0m\n"\
        "  Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[32mLarge\e[0m\n"\
        "\e[?25h"

      expect(actual_prompt_output).to eql(expected_prompt_output)
    end

    # This test can't be done in an exact way, at least, with the current framework
    it "doesn't exit when there are no matching entries" do
      prompt = TTY::TestPrompt.new
      choices = %w(Tiny Medium Large Huge)

      prompt.input << "z" << "\r"    # shows no entry, blocking exit
      prompt.input << "\u007F"       # reset filter (backspace) and show all
      prompt.input << "a" << "\r"
      prompt.input.rewind

      actual_value = prompt.select("What size?", choices, filter: true)
      expected_value = "Large"

      expect(actual_value).to eql(expected_value)

      actual_prompt_output = prompt.output.string

      expected_prompt_output =
        "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select, and alphanumeric/underscore characters to filter)\e[0m\n" \
        "\e[32m‣ Tiny\e[0m\n" \
        "  Medium\n" \
        "  Large\n" \
        "  Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[90m(Filter: \"z\")\e[0m\n" \
        "\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[90m(Filter: \"z\")\e[0m\n" \
        "\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \n" \
        "\e[32m‣ Tiny\e[0m\n" \
        "  Medium\n" \
        "  Large\n" \
        "  Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[90m(Filter: \"a\")\e[0m\n" \
        "\e[32m‣ Large\e[0m\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[32mLarge\e[0m\n" \
        "\e[?25h"

      expect(actual_prompt_output).to eql(expected_prompt_output)
    end

    it "cancels a selection" do
      prompt = TTY::TestPrompt.new
      choices = %w(Small Medium Large Huge)

      prompt.input << "H"
      prompt.input << TTY::Prompt::List::KEY_CANC << "\r"
      prompt.input.rewind

      actual_value = prompt.select("What size?", choices, filter: true)
      expected_value = "Small"

      expect(actual_value).to eql(expected_value)

      actual_prompt_output = prompt.output.string
      expected_prompt_output =
        "\e[?25lWhat size? \e[90m(Use arrow keys, press Enter to select, and alphanumeric/underscore characters to filter)\e[0m\n" \
        "\e[32m‣ Small\e[0m\n" \
        "  Medium\n" \
        "  Large\n" \
        "  Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[90m(Filter: \"H\")\e[0m\n" \
        "\e[32m‣ Huge\e[0m\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \n" \
        "\e[32m‣ Small\e[0m\n" \
        "  Medium\n" \
        "  Large\n" \
        "  Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[32mSmall\e[0m\n" \
        "\e[?25h"

      expect(actual_prompt_output).to eql(expected_prompt_output)
    end
  end
end
