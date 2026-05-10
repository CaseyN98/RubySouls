# src/rogue/rogue_map.rb
require_relative "rogue_map_generator"

class RogueMap
  attr_reader :width, :height, :tile_w, :tile_h
  attr_reader :tiles, :collision, :spawn_point

  TILE_SIZE = 16

  def initialize(width, height)
    @tile_w = TILE_SIZE
    @tile_h = TILE_SIZE

    generator = RogueMapGenerator.new(width, height)

    @width       = width
    @height      = height
    @tiles       = generator.tiles
    @spawn_point = generator.spawn_point

    build_collision
    load_tile_images
  end

  # -------------------------------------------------------------
  # Build collision grid
  # -------------------------------------------------------------
  def build_collision
    @collision = Array.new(@height) { Array.new(@width, false) }

    @tiles.each do |t|
      tx = t.x / TILE_SIZE
      ty = t.y / TILE_SIZE
      @collision[ty][tx] = t.solid
    end
  end

  # -------------------------------------------------------------
  # Load tile images (uses your existing tileset PNGs)
  # -------------------------------------------------------------
  def load_tile_images
    @tile_images = {
      "floor2"    => Gosu::Image.new("assets/tilesets/floor1.png", retro: true),
      "wall_cave" => Gosu::Image.new("assets/tilesets/wall_cave.png", retro: true)
    }
  end

  # -------------------------------------------------------------
  # Collision check
  # -------------------------------------------------------------
  def solid?(px, py)
    tx = (px / TILE_SIZE).floor
    ty = (py / TILE_SIZE).floor
    return true unless tx.between?(0, @width - 1) && ty.between?(0, @height - 1)
    @collision[ty][tx]
  end

  # -------------------------------------------------------------
  # Draw map
  # -------------------------------------------------------------
def draw(cam_x, cam_y, screen_w, screen_h)
  @tiles.each do |t|
    img = @tile_images[t.kind]
    next unless img

    sx = t.x - cam_x
    sy = t.y - cam_y

    next if sx < -TILE_SIZE || sx > screen_w
    next if sy < -TILE_SIZE || sy > screen_h

    img.draw(sx.floor, sy.floor, 0)
  end
end

  def random_floor_tile
  loop do
    tile = @tiles.sample
    return { x: tile.x, y: tile.y } unless tile.solid
  end
end

end
