class Door
  attr_reader :x, :y, :open

  def initialize(x, y, key_id)
    @x = x
    @y = y

    @key_id = key_id.to_s.strip
    @open   = (@key_id.empty? || @key_id == "")

    @sprite_closed = Gosu::Image.new("assets/objects/door_closed.png", retro: true)
    @sprite_open   = Gosu::Image.new("assets/objects/door_open.png",   retro: true)
  end

  def update(player, map)
    return if @open

    if player.inventory.has_key?(@key_id)
      @open = true
    end
  end

  def solid_at?(px, py)
    return false if @open
    Gosu.distance(px, py, @x, @y) < 12
  end

  def draw(cam_x, cam_y)
    img = @open ? @sprite_open : @sprite_closed
    img.draw(@x - cam_x - 8, @y - cam_y - 8, 5)
  end
end
