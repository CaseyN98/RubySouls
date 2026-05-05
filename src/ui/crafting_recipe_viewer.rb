class CraftingRecipeViewer
  SCROLL_SPEED = 30

  def initialize(window)
    @window = window
    @font = Gosu::Font.new(28, name: "Courier")

    @scroll_y = 0
    @max_scroll = 0
  end

  def update
    # Return to menu
    if Gosu.button_down?(Gosu::KB_E) ||
       Gosu.button_down?(Gosu::GP_BUTTON_0) # A button
      @window.return_to_menu
      return
    end

    # KEYBOARD SCROLL
    if Gosu.button_down?(Gosu::KB_UP)
      @scroll_y += SCROLL_SPEED
    elsif Gosu.button_down?(Gosu::KB_DOWN)
      @scroll_y -= SCROLL_SPEED
    end

    # CONTROLLER DPAD
    if Gosu.button_down?(Gosu::GP_UP)
      @scroll_y += SCROLL_SPEED
    elsif Gosu.button_down?(Gosu::GP_DOWN)
      @scroll_y -= SCROLL_SPEED
    end


  def clamp_scroll
    @scroll_y = 0 if @scroll_y > 0
    @scroll_y = -@max_scroll if @scroll_y < -@max_scroll
  end
end
  def draw
    @font.draw_text("CRAFTING RECIPES", 40, 40, 10, 1.4, 1.4, Gosu::Color::WHITE)

    y = 120 + @scroll_y
    line_height = 40

    recipes = $crafting_system.recipes

    recipes.each do |name, recipe|
      inputs = recipe[:inputs].join(" + ")
      output = recipe[:output]
      line = "#{name}: #{inputs} → #{output}"

      @font.draw_text(line, 40, y, 10, 1, 1, Gosu::Color::GRAY)
      y += line_height
    end

    # Calculate scroll range
    total_height = recipes.size * line_height
    visible_height = @window.height - 200
    @max_scroll = [total_height - visible_height, 0].max

    @font.draw_text("Press E / A to return", 40, @window.height - 60, 10)
  end
end
