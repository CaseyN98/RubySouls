class Physics
  def initialize(map, doors)
    @map   = map
    @doors = doors || []   # ensure array
  end

  def move(entity, dx, dy)
    new_x = entity.x + dx
    entity.x = new_x unless tile_blocked?(new_x, entity.y) || door_blocked?(new_x, entity.y)

    new_y = entity.y + dy
    entity.y = new_y unless tile_blocked?(entity.x, new_y) || door_blocked?(entity.x, new_y)
  end

  def tile_blocked?(px, py)
    @map.solid?(px, py)
  end

  def door_blocked?(px, py)
    return false if @doors.empty?
    @doors.any? { |door| door.solid_at?(px, py) }
  end
end
