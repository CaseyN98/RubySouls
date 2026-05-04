class Chest
  attr_reader :x, :y, :opened

  def initialize(x, y, props)
    @x = x
    @y = y

    # -----------------------------
    # Loot parsing (supports array or comma-separated string)
    # -----------------------------
    raw_loot = props["loot"]

    @loot_ids =
      case raw_loot
      when Array
        raw_loot.map(&:to_s).map(&:strip)
      when String
        raw_loot.split(",").map(&:strip)
      else
        []
      end

    # -----------------------------
    # Key requirement normalization
    # -----------------------------
    @key_required = props["key_required"] == true
    @key_id       = props["key_id"].to_s.strip

    if @key_id.empty? || @key_id == "0"
      @key_required = false
    end

    @opened = false

    @sprite_closed = Gosu::Image.new("assets/objects/chest_closed.png", retro: true)
    @sprite_opened = Gosu::Image.new("assets/objects/chest_open.png",   retro: true)
  end

  # -------------------------------------------------------------
  # Update: player interaction
  # -------------------------------------------------------------
  def update(player, ui)
    return if @opened

    if Gosu.distance(player.x, player.y, @x, @y) < 20 && Input.interact_pressed?
      if @key_required
        if player.inventory.has_key?(@key_id)
          open_chest(player, ui)
        else
          ui.add_damage_screen(200, 200, "Locked", Gosu::Color::GRAY)
        end
      else
        open_chest(player, ui)
      end
    end
  end

  # -------------------------------------------------------------
  # Open chest + give ALL loot items
  # -------------------------------------------------------------
  def open_chest(player, ui)
    return if @opened
    @opened = true

    @loot_ids.each do |id|
      next unless ITEM_DB[id]

      item = Item.new(id, ITEM_DB[id])
      player.pickup(item)

      ui.add_damage_world(@x, @y - 10, "+#{item.name}", Gosu::Color::YELLOW)
    end
  end

  # -------------------------------------------------------------
  # Draw
  # -------------------------------------------------------------
  def draw(cam_x, cam_y)
    img = @opened ? @sprite_opened : @sprite_closed
    img.draw(@x - cam_x - 8, @y - cam_y - 8, 5)
  end
end
