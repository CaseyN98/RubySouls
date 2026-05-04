require "json"

class Graveyard
  SAVE_PATH = "saves/graveyard.json"

  attr_reader :entries

  def initialize
    Dir.mkdir("saves") unless Dir.exist?("saves")
    @entries = load_entries
  end

  # -------------------------------------------------------------
  # Add a new death entry
  # -------------------------------------------------------------
  def add(entry)
    @entries.unshift({
      name:      entry[:name],
      floor:     entry[:floor],
      kills:     entry[:kills],
      time:      entry[:time],
      cause:     entry[:cause],
      timestamp: Time.now.strftime("%Y-%m-%d %H:%M")
    })

    save
  end

  # -------------------------------------------------------------
  # Draw graveyard screen
  # -------------------------------------------------------------
  def draw(font, window)
    y = 40
    font.draw_text("GRAVEYARD", 40, y, 10, 1.4, 1.4, Gosu::Color::WHITE)
    y += 60

    @entries.each_with_index do |e, i|
      line = "#{i+1}. Floor #{e[:floor]} — #{e[:kills]} kills — #{e[:time]} — #{e[:cause]} (#{e[:timestamp]})"
      font.draw_text(line, 40, y, 10, 1.0, 1.0, Gosu::Color::GRAY)
      y += 40
    end

    font.draw_text("Press Enter/A to return", 40, window.height - 60, 10, 1.0, 1.0, Gosu::Color::WHITE)
  end

  # -------------------------------------------------------------
  # Persistence
  # -------------------------------------------------------------
  def save
    File.write(SAVE_PATH, JSON.pretty_generate(@entries))
  end

  def load_entries
    return [] unless File.exist?(SAVE_PATH)
    JSON.parse(File.read(SAVE_PATH), symbolize_names: true)
  rescue
    []
  end
end
