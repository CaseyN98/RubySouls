class KeyPickup
  attr_reader :x, :y, :dead

  def initialize(x, y, key_id)
    @x = x
    @y = y
    @key_id = key_id.to_s.strip


    @sprite = Gosu::Image.new("assets/objects/key.png", retro: true)
    @dead = false
  end

  def update(player)
    return if @dead


    if Gosu.distance(player.x, player.y, @x, @y) < 12
      item_id = "key_#{@key_id}"   # e.g. "key_2"
      item = Item.new(item_id, ITEM_DB[item_id])

      player.inventory.add(item)
      @dead = true
    end
  end

  def draw(cam_x, cam_y)
    return if @dead
    @sprite.draw(@x - cam_x - 8, @y - cam_y - 8, 5)
  end
end
