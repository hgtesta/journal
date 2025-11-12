require "colorize"
require "csv"
require "io/console"

class Chart
  # cols = IO.console.winsize[1]

  def plot(scores)
    bars = {
      [0, 0] => " ",
      [0, 1] => "▗",
      [0, 2] => "▐",
      [1, 0] => "▖",
      [1, 1] => "▄",
      [1, 2] => "▟",
      [2, 0] => "▌",
      [2, 1] => "▙",
      [2, 2] => "█"
    }
    8.step(1, -2) do |i|
      line = scores.map { |score| (score - i).clamp(0, 2) }
      line.each_slice(2).to_a.each do |pair|
        print bars[pair]&.colorize(i >= 6 ? :yellow : :blue)
      end
      puts
    end
  end

  def plot_humor
    # Read humor data from CSV and store humor values (second column) in array
    humor_values = []
    CSV.foreach("humor_data.csv") do |row|
      humor_values << (row[1].to_f * 2).to_i
    end

    scores = humor_values.last(200)
    plot(scores)
  end
end
