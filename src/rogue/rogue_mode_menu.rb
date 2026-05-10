# src/rogue/rogue_mode_menu.rb
class RogueModeMenu
  def initialize(window)
    @window = window
    @font   = Gosu::Font.new(36, name: "Courier")

    @options = [
      "NORMAL MODE",
      "ROGUE MODE",
      "BACK"
    ]

    @selected = 0
    @input_timer = 200
  end

  def update
    @input_timer -= 16 if @input_timer > 0
    return if @input_timer > 0

    if Input.move_y < 0 || Input.up
      @selected = (@selected - 1) % @options.length
      @input_timer = 200

    elsif Input.move_y > 0 || Input.down
      @selected = (@selected + 1) % @options.length
      @input_timer = 200

    elsif Input.interact_pressed? || Input.craft_confirm_down?
      handle_select
      @input_timer = 300
    end
  end

  def handle_select
    case @selected
    when 0
      @window.start_game          # NORMAL MODE
    when 1
      @window.start_rogue_mode    # ROGUE MODE
    when 2
      @window.return_to_menu      # BACK
    end
  end

  def draw
    w = @window.width
    h = @window.height

    base_y = 260

    @options.each_with_index do |opt, i|
      text_w = @font.text_width(opt)
      x = (w - text_w) / 2
      y = base_y + i * 80

      selected = (i == @selected)

      if selected
        Gosu.draw_rect(
          x - 30, y - 10,
          text_w + 60, 60,
          Gosu::Color.rgba(255, 255, 255, 40),
          5
        )
      end

      scale = selected ? 1.05 + Math.sin(Gosu.milliseconds / 200.0) * 0.03 : 1.0
      color = selected ? Gosu::Color::YELLOW : Gosu::Color::WHITE

      @font.draw_text(opt, x, y, 10, scale, scale, color)
    end
  end
end
