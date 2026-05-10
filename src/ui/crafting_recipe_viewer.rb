class CraftingRecipeViewer
  SCROLL_SPEED = 30

  def initialize(window)
    @window = window
    @font = Gosu::Font.new(28, name: "Courier")
    @small = Gosu::Font.new(22, name: "Courier")

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

    clamp_scroll
  end

  def clamp_scroll
    @scroll_y = 0 if @scroll_y > 0
    @scroll_y = -@max_scroll if @scroll_y < -@max_scroll
  end

  def draw
    y = 40 + @scroll_y

    # Title
    @font.draw_text("CRAFTING SYSTEM", 40, y, 10, 1.4, 1.4, Gosu::Color::WHITE)
    y += 70

    # -------------------------------
    # NEW CRAFTING RULES SECTION
    # -------------------------------
    rules = [
      "• Combine two identical items → upgrades to next tier",
      "• Combine item + Upgrade Stone → upgrades to next tier",
      "• Fire Orb + Iron Sword → Fire Sword (tier preserved)",
      "• Fire Orb + Wooden Bow → Flame Bow (tier preserved)",
      "• All items can upgrade endlessly in Rogue Mode",
      "• Higher tiers auto-generate stats (+8 ATK, +20 DUR, etc.)",
      "• Only special fusion recipes are listed below"
    ]

    rules.each do |line|
      @small.draw_text(line, 40, y, 10, 1, 1, Gosu::Color::YELLOW)
      y += 32
    end

    y += 20
    @font.draw_text("SPECIAL RECIPES", 40, y, 10, 1.2, 1.2, Gosu::Color::WHITE)
    y += 60

    # -------------------------------
    # STATIC RECIPES FROM JSON
    # -------------------------------
    recipes = $crafting_system.recipes
    line_height = 40

    recipes.each do |name, recipe|
      inputs = recipe[:inputs].join(" + ")
      output = recipe[:output]
      line = "#{name}: #{inputs} → #{output}"

      @font.draw_text(line, 40, y, 10, 1, 1, Gosu::Color::GRAY)
      y += line_height
    end

    # Scroll range
    total_height = y - 40
    visible_height = @window.height - 200
    @max_scroll = [total_height - visible_height, 0].max

    # Footer
    @font.draw_text("Press E / A to return", 40, @window.height - 60, 10)
  end
end
