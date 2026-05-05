class GraveyardViewer
  SCROLL_SPEED = 30

  def initialize(window, graveyard)
    @window    = window
    @graveyard = graveyard
    @font      = Gosu::Font.new(28, name: "Courier")

    @scroll_y   = 0
    @max_scroll = 0
  end

  def update
    # Exit viewer
    if Gosu.button_down?(Gosu::KB_E) || Gosu.button_down?(Gosu::GP_BUTTON_0)
      @window.return_to_menu
      return
    end

    # Scroll input
    if Gosu.button_down?(Gosu::KB_UP) || Gosu.button_down?(Gosu::GP_UP)
      @scroll_y += SCROLL_SPEED
    elsif Gosu.button_down?(Gosu::KB_DOWN) || Gosu.button_down?(Gosu::GP_DOWN)
      @scroll_y -= SCROLL_SPEED
    end

end
  def clamp_scroll
    @scroll_y = 0 if @scroll_y > 0
    @scroll_y = -@max_scroll if @scroll_y < -@max_scroll
  end

  def draw
    @font.draw_text("GRAVEYARD", 40, 40, 10, 1.4, 1.4, Gosu::Color::WHITE)

    y = 120 + @scroll_y
    line_height = 40

    @graveyard.entries.each_with_index do |e, i|
      line = "#{i+1}. Floor #{e[:floor]} — #{e[:kills]} kills — #{e[:time]} — #{e[:cause]} (#{e[:timestamp]})"
      @font.draw_text(line, 40, y, 10, 1, 1, Gosu::Color::GRAY)
      y += line_height
    end

    total_height   = @graveyard.entries.size * line_height
    visible_height = @window.height - 200
    @max_scroll    = [total_height - visible_height, 0].max

    @font.draw_text("Press E / A to return", 40, @window.height - 60, 10)
  end
end
