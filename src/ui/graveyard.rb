require "json"

class Graveyard
  SAVE_PATH = "saves/graveyard.json"
  SCROLL_SPEED = 30

  attr_reader :entries

  def initialize
    Dir.mkdir("saves") unless Dir.exist?("saves")
    @entries = load_entries

    @scroll_y = 0
    @max_scroll = 0
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
  # Update (scroll + exit)
  # -------------------------------------------------------------
  def update(window)
    # Exit
    if Gosu.button_down?(Gosu::KB_ENTER) ||
       Gosu.button_down?(Gosu::GP_BUTTON_0)
      window.return_to_menu
      return
    end

    # Scroll
    if Gosu.button_down?(Gosu::KB_UP) || Gosu.button_down?(Gosu::GP_UP)
      @scroll_y += SCROLL_SPEED
    elsif Gosu.button_down?(Gosu::KB_DOWN) || Gosu.button_down?(Gosu::GP_DOWN)
      @scroll_y -= SCROLL_SPEED
    end

    clamp_scroll
  end

  def clamp_scroll
    @scroll_y = 0 if @scroll_y > 0
    @scroll_y = -@max_scroll if @scroll_y < -@max_scroll
  end

  # -------------------------------------------------------------
  # Draw graveyard screen
  # -------------------------------------------------------------
  def draw(font, window)
    y = 40 + @scroll_y

    font.draw_text("GRAVEYARD", 40, y, 10, 1.4, 1.4, Gosu::Color::WHITE)
    y += 60

    @entries.each_with_index do |e, i|
      line = "#{i+1}. Floor #{e[:floor]} — #{e[:kills]} kills — #{e[:time]} — #{e[:cause]} (#{e[:timestamp]})"
      font.draw_text(line, 40, y, 10, 1.0, 1.0, Gosu::Color::GRAY)
      y += 40
    end

    # Scroll range
    total_height = y - 40
    visible_height = window.height - 200
    @max_scroll = [total_height - visible_height, 0].max

    font.draw_text("Press Enter / A to return", 40, window.height - 60, 10)
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
