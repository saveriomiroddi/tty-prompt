# encoding: utf-8

RSpec.describe TTY::Prompt do
  let(:symbols) { TTY::Prompt::Symbols.symbols }

  def output_helper(prompt, choices, active, selected, options = {})
    hint = options.fetch(:hint, "Use arrow keys, press Space to select and Enter to finish")
    init = options.fetch(:init, false)

    out = if init
            "\e[?25l#{prompt} \e[90m(#{hint})\e[0m\n"
          else
            "#{prompt} #{selected.join(', ')}\n"
          end
    out << choices.map do |choice|
      prefix = choice == active ? "#{symbols[:pointer]} " : "  "
      prefix += if selected.include? choice
                  "\e[32m#{symbols[:radio_on]}\e[0m "
                else
                  "#{symbols[:radio_off]} "
                end
      prefix + choice
    end.join("\n")
    out << "\e[2K\e[1G\e[1A" * choices.count
    out << "\e[2K\e[1G"
    out
  end

  it "selects nothing when return pressed immediately" do
    prompt = TTY::TestPrompt.new
    choices = %w(vodka beer wine whisky bourbon)
    prompt.input << "\r"
    prompt.input.rewind
    expect(prompt.multi_select("Select drinks?", choices)). to eq([])
    expect(prompt.output.string).to eq([
      "\e[?25lSelect drinks? \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} #{symbols[:radio_off]} vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? \n\e[?25h"
    ].join)
  end

  it "selects item when space pressed" do
    prompt = TTY::TestPrompt.new
    choices = %w(vodka beer wine whisky bourbon)
    prompt.input << " \r"
    prompt.input.rewind
    expect(prompt.multi_select("Select drinks?", choices)). to eq(['vodka'])
    expect(prompt.output.string).to eq([
      "\e[?25lSelect drinks? \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} #{symbols[:radio_off]} vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? vodka\n",
      "#{symbols[:pointer]} \e[32m#{symbols[:radio_on]}\e[0m vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? \e[32mvodka\e[0m\n\e[?25h"
    ].join)
  end

  it "selects item when space pressed but doesn't echo item if echo: false" do
    prompt = TTY::TestPrompt.new
    choices = %w(vodka beer wine whisky bourbon)
    prompt.input << " \r"
    prompt.input.rewind
    expect(prompt.multi_select("Select drinks?", choices, echo: false)). to eq(['vodka'])
    expect(prompt.output.string).to eq([
      "\e[?25lSelect drinks? \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} #{symbols[:radio_off]} vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? \n",
      "#{symbols[:pointer]} \e[32m#{symbols[:radio_on]}\e[0m vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? \n\e[?25h"
    ].join)
  end

  it "sets choice custom values" do
    prompt = TTY::TestPrompt.new
    choices = {vodka: 1, beer: 2, wine: 3, whisky: 4, bourbon: 5}
    prompt.input << " \r"
    prompt.input.rewind
    expect(prompt.multi_select("Select drinks?", choices)).to eq([1])
    expect(prompt.output.string).to eq([
      "\e[?25lSelect drinks? \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} #{symbols[:radio_off]} vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? vodka\n",
      "#{symbols[:pointer]} \e[32m#{symbols[:radio_on]}\e[0m vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? \e[32mvodka\e[0m\n\e[?25h"
    ].join)
  end

  it "sets choice name and value through DSL" do
    prompt = TTY::TestPrompt.new
    prompt.input << " \r"
    prompt.input.rewind
    value = prompt.multi_select("Select drinks?") do |menu|
              menu.enum ')'

              menu.choice :vodka, {score: 1}
              menu.choice :beer, 2
              menu.choice :wine, 3
              menu.choices whisky: 4, bourbon: 5
            end
    expect(value).to eq([{score: 1}])
    expect(prompt.output.string).to eq([
      "\e[?25lSelect drinks? \e[90m(Use arrow or number (1-5) keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} #{symbols[:radio_off]} 1) vodka\n",
      "  #{symbols[:radio_off]} 2) beer\n",
      "  #{symbols[:radio_off]} 3) wine\n",
      "  #{symbols[:radio_off]} 4) whisky\n",
      "  #{symbols[:radio_off]} 5) bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? vodka\n",
      "#{symbols[:pointer]} \e[32m#{symbols[:radio_on]}\e[0m 1) vodka\n",
      "  #{symbols[:radio_off]} 2) beer\n",
      "  #{symbols[:radio_off]} 3) wine\n",
      "  #{symbols[:radio_off]} 4) whisky\n",
      "  #{symbols[:radio_off]} 5) bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? \e[32mvodka\e[0m\n\e[?25h"
    ].join)
  end

  it "sets default options through DSL syntax" do
    prompt = TTY::TestPrompt.new
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.multi_select("Select drinks?") do |menu|
              menu.default 2, 5

              menu.choice :vodka,   {score: 10}
              menu.choice :beer,    {score: 20}
              menu.choice :wine,    {score: 30}
              menu.choice :whisky,  {score: 40}
              menu.choice :bourbon, {score: 50}
            end
    expect(value).to match_array([{score: 20}, {score: 50}])
    expect(prompt.output.string).to eq([
      "\e[?25lSelect drinks? beer, bourbon \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "  #{symbols[:radio_off]} vodka\n",
      "  \e[32m#{symbols[:radio_on]}\e[0m beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "#{symbols[:pointer]} \e[32m#{symbols[:radio_on]}\e[0m bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? \e[32mbeer, bourbon\e[0m\n\e[?25h",
    ].join)
  end

  it "sets default options through hash syntax" do
    prompt = TTY::TestPrompt.new
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.multi_select("Select drinks?", default: [2, 5]) do |menu|
              menu.choice :vodka,   {score: 10}
              menu.choice :beer,    {score: 20}
              menu.choice :wine,    {score: 30}
              menu.choice :whisky,  {score: 40}
              menu.choice :bourbon, {score: 50}
            end
    expect(value).to match_array([{score: 20}, {score: 50}])
  end

  it "raises error for defaults out of range" do
    prompt = TTY::TestPrompt.new
    prompt.input << "\r"
    prompt.input.rewind
    expect {
      prompt.multi_select("Select drinks?", default: [2, 6]) do |menu|
        menu.choice :vodka,   {score: 10}
        menu.choice :beer,    {score: 20}
        menu.choice :wine,    {score: 30}
        menu.choice :whisky,  {score: 40}
        menu.choice :bourbon, {score: 50}
      end
    }.to raise_error(TTY::Prompt::ConfigurationError,
                     /default index `6` out of range \(1 - 5\)/)
  end

  it "sets prompt prefix" do
    prompt = TTY::TestPrompt.new(prefix: '[?] ')
    choices = %w(vodka beer wine whisky bourbon)
    prompt.input << "\r"
    prompt.input.rewind
    expect(prompt.multi_select("Select drinks?", choices)). to eq([])
    expect(prompt.output.string).to eq([
      "\e[?25l[?] Select drinks? \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} #{symbols[:radio_off]} vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "[?] Select drinks? \n\e[?25h"
    ].join)
  end

  it "changes selected item color & marker" do
    prompt = TTY::TestPrompt.new
    choices = %w(vodka beer wine whisky bourbon)
    prompt.input << "\r"
    prompt.input.rewind
    options = {default: [1], active_color: :blue, marker: '>'}
    expect(prompt.multi_select("Select drinks?", choices, options)). to eq(['vodka'])
    expect(prompt.output.string).to eq([
      "\e[?25lSelect drinks? vodka \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "> \e[34m#{symbols[:radio_on]}\e[0m vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? \e[34mvodka\e[0m\n\e[?25h"
    ].join)
  end

  it "changes help text" do
    prompt = TTY::TestPrompt.new
    choices = %w(vodka beer wine whisky bourbon)
    prompt.input << "\r"
    prompt.input.rewind
    expect(prompt.multi_select("Select drinks?", choices, help: '(Bash keyboard)')). to eq([])
    expect(prompt.output.string).to eq([
      "\e[?25lSelect drinks? \e[90m(Bash keyboard)\e[0m\n",
      "#{symbols[:pointer]} #{symbols[:radio_off]} vodka\n",
      "  #{symbols[:radio_off]} beer\n",
      "  #{symbols[:radio_off]} wine\n",
      "  #{symbols[:radio_off]} whisky\n",
      "  #{symbols[:radio_off]} bourbon",
      "\e[2K\e[1G\e[1A" * 5, "\e[2K\e[1G",
      "Select drinks? \n\e[?25h"
    ].join)
  end

  it "paginates long selections" do
    prompt = TTY::TestPrompt.new
    choices = %w(A B C D E F G H)
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.multi_select("What letter?", choices, per_page: 3, default: 4)
    expect(value).to eq(['D'])
    expect(prompt.output.string).to eq([
      "\e[?25lWhat letter? D \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} \e[32m#{symbols[:radio_on]}\e[0m D\n",
      "  #{symbols[:radio_off]} E\n",
      "  #{symbols[:radio_off]} F\n",
      "\e[90m(Move up or down to reveal more choices)\e[0m",
      "\e[2K\e[1G\e[1A" * 4, "\e[2K\e[1G",
      "What letter? \e[32mD\e[0m\n\e[?25h",
    ].join)
  end

  it "paginates choices as hash object" do
    prompt = TTY::TestPrompt.new
    choices = {A: 1, B: 2, C: 3, D: 4, E: 5, F: 6, G: 7, H: 8}
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.multi_select("What letter?", choices, default: 4, per_page: 3)
    expect(value).to eq([4])
    expect(prompt.output.string).to eq([
      "\e[?25lWhat letter? D \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} \e[32m#{symbols[:radio_on]}\e[0m D\n",
      "  #{symbols[:radio_off]} E\n",
      "  #{symbols[:radio_off]} F\n",
      "\e[90m(Move up or down to reveal more choices)\e[0m",
      "\e[2K\e[1G\e[1A" * 4, "\e[2K\e[1G",
      "What letter? \e[32mD\e[0m\n\e[?25h",
    ].join)
  end

  it "paginates long selections through DSL" do
    prompt = TTY::TestPrompt.new
    choices = %w(A B C D E F G H)
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.multi_select("What letter?") do |menu|
              menu.per_page 3
              menu.page_help '(Wiggle thy finger up or down to see more)'
              menu.default 4
              menu.choices choices
            end
    expect(value).to eq(['D'])
    expect(prompt.output.string).to eq([
      "\e[?25lWhat letter? D \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} \e[32m#{symbols[:radio_on]}\e[0m D\n",
      "  #{symbols[:radio_off]} E\n",
      "  #{symbols[:radio_off]} F\n",
      "\e[90m(Wiggle thy finger up or down to see more)\e[0m",
      "\e[2K\e[1G\e[1A" * 4, "\e[2K\e[1G",
      "What letter? \e[32mD\e[0m\n\e[?25h",
    ].join)
  end

  it "doesn't paginate short selections" do
    prompt = TTY::TestPrompt.new
    choices = %w(A B C D)
    prompt.input << "\r"
    prompt.input.rewind
    value = prompt.multi_select("What letter?", choices, per_page: 4, default: 1)
    expect(value).to eq(['A'])

    expect(prompt.output.string).to eq([
      "\e[?25lWhat letter? A \e[90m(Use arrow keys, press Space to select and Enter to finish)\e[0m\n",
      "#{symbols[:pointer]} \e[32m#{symbols[:radio_on]}\e[0m A\n",
      "  #{symbols[:radio_off]} B\n",
      "  #{symbols[:radio_off]} C\n",
      "  #{symbols[:radio_off]} D",
      "\e[2K\e[1G\e[1A" * 4, "\e[2K\e[1G",
      "What letter? \e[32mA\e[0m\n\e[?25h",
    ].join)
  end

  it "doesn't cycle by default" do
    prompt = TTY::TestPrompt.new
    choices = %w(A B C)
    prompt.on(:keypress) { |e| prompt.trigger(:keydown) if e.value == "j" }
    prompt.input << "j" << "j" << "j" << " " << "\r"
    prompt.input.rewind
    value = prompt.multi_select("What letter?", choices)
    expect(value).to eq(["C"])
    expect(prompt.output.string).to eq(
      output_helper("What letter?", choices, "A", [], init: true) +
      output_helper("What letter?", choices, "B", []) +
      output_helper("What letter?", choices, "C", []) +
      output_helper("What letter?", choices, "C", []) +
      output_helper("What letter?", choices, "C", ["C"]) +
      "What letter? \e[32mC\e[0m\n\e[?25h"
    )
  end

  it "cycles when configured to do so" do
    prompt = TTY::TestPrompt.new
    choices = %w(A B C)
    prompt.on(:keypress) { |e| prompt.trigger(:keydown) if e.value == "j" }
    prompt.input << "j" << "j" << "j" << " " << "\r"
    prompt.input.rewind
    value = prompt.multi_select("What letter?", choices, cycle: true)
    expect(value).to eq(["A"])
    expect(prompt.output.string).to eq(
      output_helper("What letter?", choices, "A", [], init: true) +
      output_helper("What letter?", choices, "B", []) +
      output_helper("What letter?", choices, "C", []) +
      output_helper("What letter?", choices, "A", []) +
      output_helper("What letter?", choices, "A", ["A"]) +
      "What letter? \e[32mA\e[0m\n\e[?25h"
    )
  end

  context "with filter" do
    it "doesn't lose the selection when switching between filters" do
      prompt = TTY::TestPrompt.new
      choices = %w(Tiny Medium Large Huge)

      prompt.input << " "         # select `Tiny`
      prompt.input << "a" << " "  # match and select `Large`
      prompt.input << "\u007F"    # backspace (shows all)
      prompt.input << "\r"
      prompt.input.rewind

      actual_values = prompt.multi_select("What size?", choices, filter: true)
      expected_values = %w(Tiny Large)

      expect(actual_values).to eql(expected_values)

      actual_prompt_output = prompt.output.string
      expected_prompt_output =
        "\e[?25lWhat size? \e[90m(Use arrow keys, press Space to select and Enter to finish, and alphanumeric/underscore characters to filter)\e[0m\n" \
        "‣ ⬡ Tiny\n" \
        "  ⬡ Medium\n" \
        "  ⬡ Large\n" \
        "  ⬡ Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? Tiny\n" \
        "‣ \e[32m⬢\e[0m Tiny\n" \
        "  ⬡ Medium\n" \
        "  ⬡ Large\n  ⬡ Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? Tiny (Filter: \"a\")\n" \
        "‣ ⬡ Large\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? Tiny, Large (Filter: \"a\")\n" \
        "‣ \e[32m⬢\e[0m Large\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? Tiny, Large\n" \
        "‣ \e[32m⬢\e[0m Tiny\n" \
        "  ⬡ Medium\n" \
        "  \e[32m⬢\e[0m Large\n" \
        "  ⬡ Huge\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1G\e[1A\e[2K\e[1GWhat size? \e[32mTiny, Large\e[0m\n" \
        "\e[?25h"

      expect(actual_prompt_output).to eql(expected_prompt_output)
    end
  end
end
