require "console_selector/version"
require 'io/console'

module Console
  module Keys
    C_f, C_b, C_n, C_p = [
      "\u0006", "\u0002", "\u000E", "\u0010"
    ]
    Up, Down, Right, Left = [
      "\e[A","\e[B", "\e[C", "\e[D"
    ]

    def self.get_key(io)
      c = io.getch
      case c
      when "\e"
        # \eから始まるキーは3文字で構成.
        c + io.getch + io.getch
      else
        c
      end 
    end
  end

  class Selector
    def initialize(choices, index = 1)
      @choices, @index = choices, index
      set_control_keys(
        [
          "k", "h",
          "p", "b",
          Keys::Left, Keys::Up,
          Keys::C_b, Keys::C_p,
        ],
        [
          "j", "l",
          "n", "f",
          Keys::Right, Keys::Down,
          Keys::C_f, Keys::C_n,
        ])
      set_correct_keys ["\r", "\n"]
      set_interrupt_keys ["\u0003"]
      set_number_keys ("1".."9").to_a
    end

    def set_control_keys(up_keys, down_keys)
      @control_keys = [up_keys, down_keys]
    end

    def set_correct_keys(keys)
      @correct_keys = keys
    end

    def set_interrupt_keys(keys)
      @interrupt_keys = keys
    end

    def set_number_keys(keys)
      @number_keys = keys
    end

    def self.run(choices, multi: false, indent: 0)
      new(choices).run(multi: multi, indent: indent)
    end

    def run(multi: false, indent: 0)
      if multi
        run_impl {
          _, rows = IO.console.winsize
          print "\r#{' '*indent}"
          @choices.each.with_index(1) do |choice, index|
            print " " unless index == 1
            prefix, postfix = if index == current_index
                                ["\e[1m\e[4m", "\e[m"]
                              else
                                ["", ""]
                              end
            print "#{prefix}#{index}:#{choice}#{postfix}"
          end
        }
      else
        run_impl {
          _, rows = IO.console.winsize
          print "\r#{' '*indent}#{current_index}: #{current_choice}".ljust(rows)
          print "\r#{' '*indent}"
        }
      end
    end

    private
    def run_impl(&reprint)
      begin
        IO.console.noecho do |io|
          loop do
            reprint.call
            case key = Keys.get_key(io)
            when *@control_keys[0]
              dec_index
            when *@control_keys[1]
              inc_index
            when *@number_keys
              set_index_or_do_nothing(key.to_i)
            when *@correct_keys
              break
            when *@interrupt_keys
              raise Interrupt
            end
          end
          [current_index, current_choice]
        end
      ensure
        puts
      end
    end

    def current_index
      @index
    end
    def inc_index
      set_index_or_do_nothing(@index + 1)
    end
    def dec_index
      set_index_or_do_nothing(@index - 1)
    end
    def set_index_or_do_nothing(new_index)
      @index = new_index if (1..@choices.size).include?(new_index)
    end
    def current_choice
      @choices[@index - 1]
    end
  end
end

