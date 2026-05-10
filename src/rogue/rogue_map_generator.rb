# src/rogue/rogue_map_generator.rb
class RogueMapGenerator
  Tile = Struct.new(:x, :y, :kind, :solid)

  attr_reader :width, :height, :tiles, :spawn_point

  TILE_SIZE = 16

  def initialize(width, height)
    @width  = width
    @height = height
    @tiles  = []
    @spawn_point = { x: width * TILE_SIZE / 2, y: height * TILE_SIZE / 2 }
    generate
  end

  def generate
    @height.times do |ty|
      @width.times do |tx|
        if border?(tx, ty) || rand < 0.12
          add_tile(tx, ty, "wall_cave", true)
        else
          add_tile(tx, ty, "floor2", false)
        end
      end
    end
  end

  def border?(x, y)
    x == 0 || y == 0 || x == @width - 1 || y == @height - 1
  end

  def add_tile(tx, ty, kind, solid)
    @tiles << Tile.new(tx * TILE_SIZE, ty * TILE_SIZE, kind, solid)
  end

  # -------------------------------------------------------------
  # REQUIRED BY RogueFloor — ensures valid spawn positions
  # -------------------------------------------------------------
  def random_floor_tile
    loop do
      tile = @tiles.sample
      return { x: tile.x, y: tile.y } unless tile.solid
    end
  end
end
