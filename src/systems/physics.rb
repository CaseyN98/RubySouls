class Physics
  def initialize(map, doors)
    @map   = map
    @doors = doors   # Array of Door instances
  end

  def move(entity, dx, dy)
    # -----------------------------------------
    # X MOVEMENT
    # -----------------------------------------
    new_x = entity.x + dx

    unless tile_blocked?(new_x, entity.y) || door_blocked?(new_x, entity.y)
      entity.x = new_x
    end

    # -----------------------------------------
    # Y MOVEMENT
    # -----------------------------------------
    new_y = entity.y + dy

    unless tile_blocked?(entity.x, new_y) || door_blocked?(entity.x, new_y)
      entity.y = new_y
    end
  end

  # ----------------------------------------------------
  # Tile collision
  # ----------------------------------------------------
  def tile_blocked?(px, py)
    @map.solid?(px, py)
  end

  # ----------------------------------------------------
  # Door collision
  # ----------------------------------------------------
  def door_blocked?(px, py)
    @doors.any? { |door| door.solid_at?(px, py) }
  end
end
