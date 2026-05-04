class ItemPickup
  attr_reader :x, :y, :dead

  def initialize(x, y, item_id)
    @x = x
    @y = y
    @item_id = item_id
    @dead = false

    # Load sprite directly for the pickup object
    data = ITEM_DB[@item_id]
    @sprite = Gosu::Image.new(data["sprite"], retro: true)
  end

  def update(player)
    return if @dead

    if Gosu.distance(player.x, player.y, @x, @y) < 12
      # Create a REAL Item object
      item = Item.new(@item_id, ITEM_DB[@item_id])

      #  use Player's pickup logic
      player.pickup(item)

      @dead = true
    end
  end

  def draw(cam_x, cam_y)
    return if @dead
    @sprite.draw(@x - cam_x - 8, @y - cam_y - 8, 5)
  end
end
