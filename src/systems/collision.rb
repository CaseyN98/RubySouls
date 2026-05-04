class Collision
  def initialize(map)
    @map = map
  end

  def move(entity, dx, dy)
    new_x = entity.x + dx
    new_y = entity.y + dy

    entity.x = new_x unless @map.solid?(new_x, entity.y)
    entity.y = new_y unless @map.solid?(entity.x, new_y)
  end
end