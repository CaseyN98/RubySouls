class Camera
  attr_reader :x, :y

  def initialize(target, virtual_w, virtual_h, smooth: true, deadzone: 8)
    @target = target
    @vw = virtual_w
    @vh = virtual_h

    @smooth = smooth
    @deadzone = deadzone

    @x = @y = 0
    @shake = 0
    @shake_decay = 0.85

    @map = nil
  end

  def set_map(map)
    @map = map
  end

  def update
    return unless @map

    # Desired camera center
    target_x = @target.x - @vw / 2.0
    target_y = @target.y - @vh / 2.0

    # Deadzone logic
    dx = target_x - @x
    dy = target_y - @y

    target_x = dx.abs > @deadzone ? @x + dx : @x
    target_y = dy.abs > @deadzone ? @y + dy : @y

    # Smooth follow
    if @smooth
      @x += (target_x - @x) * 0.15
      @y += (target_y - @y) * 0.15
    else
      @x = target_x
      @y = target_y
    end

    # Shake
    if @shake > 0.1
      @x += rand(-@shake..@shake)
      @y += rand(-@shake..@shake)
      @shake *= @shake_decay
    else
      @shake = 0
    end

    # ---------------------------------------------------------
    # BORDER CLAMPING — applied AFTER smoothing
    # ---------------------------------------------------------
    map_w = @map.width  * @map.tile_w
    map_h = @map.height * @map.tile_h

    max_x = map_w - @vw
    max_y = map_h - @vh

    # If map is smaller than screen, center it
    if max_x < 0
      @x = max_x / 2.0
    else
      @x = @x.clamp(0, max_x)
    end

    if max_y < 0
      @y = max_y / 2.0
    else
      @y = @y.clamp(0, max_y)
    end

    # Pixel-perfect
    @x = @x.round
    @y = @y.round
  end

  def shake(amount = 4)
    @shake = amount.to_f
  end
end
