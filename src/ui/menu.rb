class Menu
  def initialize(window)
    @window = window

    @options = [
      "START GAME",
      "GRAVEYARD (COMING SOON)",
      "QUIT"
    ]

    @selected = 0
    @input_timer = 200

    @font = Gosu::Font.new(36, name: "Courier")

    @bg   = Gosu::Image.new("assets/ect/menu_bg.png", tileable: true)
    @logo = Gosu::Image.new("assets/ect/logo.png") rescue nil

    # Scale factor for 512x512 logo
    @logo_scale = 0.7
  end

  # -------------------------------------------------------------
  # UPDATE
  # -------------------------------------------------------------
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

  # -------------------------------------------------------------
  # HANDLE SELECTION
  # -------------------------------------------------------------
  def handle_select
    case @selected
    when 0
      @window.start_game
    when 1
      puts "Graveyard not implemented yet!"
    when 2
      @window.close
    end
  end

  # -------------------------------------------------------------
  # DRAW
  # -------------------------------------------------------------
  def draw
    w = @window.width
    h = @window.height

    # Background
    @bg.draw(0, 0, 0, w.to_f / @bg.width, h.to_f / @bg.height)

    # ---------------------------------------------------------
    # LOGO — moved to top, scaled down
    # ---------------------------------------------------------
    if @logo
      scaled_w = @logo.width * @logo_scale
      scaled_h = @logo.height * @logo_scale

      lx = (w - scaled_w) / 2
      ly = 40  # top padding

      @logo.draw(lx, ly, 10, @logo_scale, @logo_scale)
    end

    # ---------------------------------------------------------
    # MENU OPTIONS — pushed down to make room for logo
    # ---------------------------------------------------------
    base_y = 360  # moved down from 320 → 260 (adjust as needed)

    @options.each_with_index do |opt, i|
      text_w = @font.text_width(opt)
      x = (w - text_w) / 2
      y = base_y + i * 80  # increased spacing for better layout

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
