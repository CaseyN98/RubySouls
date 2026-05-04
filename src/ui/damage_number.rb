class DamageNumber
  attr_reader :finished

  def initialize(x, y, amount, color = Gosu::Color::WHITE)
    @x = x
    @y = y
    @amount = amount

    @base_color = color.dup
    @color = color.dup

    @time = 0.0
    @duration = 0.6   # seconds
    @finished = false

    @vx = rand(-0.3..0.3) # small horizontal drift
    @vy = -1.2            # initial upward velocity
    @gravity = 1.8        # slows upward motion over time

    @scale = 1.0
  end

  def update
    dt = 1.0 / 60.0
    @time += dt

    if @time >= @duration
      @finished = true
      return
    end

    @x += @vx
    @y += @vy
    @vy += @gravity * dt

    @scale = 1.0 + (0.4 * (1.0 - (@time / @duration)))

    fade_ratio = 1.0 - (@time / @duration)
    @color = Gosu::Color.rgba(
      @base_color.red,
      @base_color.green,
      @base_color.blue,
      (fade_ratio * 255).to_i
    )
  end

  def draw(font, cam_x, cam_y)
    return if @finished

    # World coords → screen coords (no extra scale; Gosu.scale already applied)
    screen_x = (@x - cam_x).round
    screen_y = (@y - cam_y).round

    font.draw_text(
      @amount.to_s,
      screen_x,
      screen_y,
      200,
      @scale,
      @scale,
      @color
    )
  end
end
