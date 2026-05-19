class RogueMapGenerator
  Tile = Struct.new(:x, :y, :kind, :solid)

  TILE_SIZE = 16

  attr_reader :width, :height, :tiles, :spawn_point

  def initialize(width, height)
    @width  = width
    @height = height
    @tiles  = []

    @spawn_point = {
      x: (width * TILE_SIZE) / 2,
      y: (height * TILE_SIZE) / 2
    }

    generate
  end

  # -------------------------------------------------------------
  # MAIN GENERATION
  # -------------------------------------------------------------
def generate
  grid = create_random_grid
  rooms = create_rooms(grid)

  corridor_mask = Array.new(@height) { Array.new(@width, false) }
  connect_rooms(grid, rooms, corridor_mask)

  1.times do
    grid = smooth(grid, corridor_mask)
  end

  grid = ensure_connectivity(grid)

  build_tiles(grid)
end

  # -------------------------------------------------------------
  # INITIAL RANDOM FILL
  # -------------------------------------------------------------
  def create_random_grid
    Array.new(@height) do |y|
      Array.new(@width) do |x|
        if border?(x, y)
          true
        else
          # More walls = denser cave
          rand < 0.52
        end
      end
    end
  end

  # -------------------------------------------------------------
  # ROOM GENERATION
  # -------------------------------------------------------------
  def create_rooms(grid)
    rooms = []

    # Central spawn room
    spawn_room = {
      x: (@width / 2) - 4,
      y: (@height / 2) - 4,
      w: 8,
      h: 8
    }

    carve_room(grid, spawn_room)
    rooms << spawn_room

    # Smaller/tighter rooms with overlap prevention
    target_rooms = rand(7..12)
    attempts     = target_rooms * 5

    attempts.times do
      break if rooms.size >= target_rooms + 1 # +1 for spawn room

      room = {
        x: rand(2..@width - 12),
        y: rand(2..@height - 12),
        w: rand(4..8),
        h: rand(4..8)
      }

      next if room_overlaps?(rooms, room)

      carve_room(grid, room)
      rooms << room
    end

    rooms
  end

  def carve_room(grid, room)
    x1 = room[:x]
    y1 = room[:y]
    x2 = x1 + room[:w]
    y2 = y1 + room[:h]

    (y1...y2).each do |y|
      (x1...x2).each do |x|
        next if border?(x, y)

        grid[y][x] = false
      end
    end
  end

  def room_overlaps?(rooms, new_room)
    # Small padding so rooms don't touch directly
    padding = 1

    nx1 = new_room[:x] - padding
    ny1 = new_room[:y] - padding
    nx2 = new_room[:x] + new_room[:w] + padding
    ny2 = new_room[:y] + new_room[:h] + padding

    rooms.any? do |r|
      rx1 = r[:x]
      ry1 = r[:y]
      rx2 = r[:x] + r[:w]
      ry2 = r[:y] + r[:h]

      nx1 < rx2 && nx2 > rx1 && ny1 < ry2 && ny2 > ry1
    end
  end

  # -------------------------------------------------------------
  # ROOM CONNECTIONS
  # -------------------------------------------------------------
  def connect_rooms(grid, rooms, corridor_mask)
    rooms.each_cons(2) do |room_a, room_b|
      carve_corridor(grid, corridor_mask, room_a, room_b)
    end
  end

  def carve_corridor(grid, corridor_mask, room_a, room_b)
    ax = room_a[:x] + room_a[:w] / 2
    ay = room_a[:y] + room_a[:h] / 2

    bx = room_b[:x] + room_b[:w] / 2
    by = room_b[:y] + room_b[:h] / 2

    # Slightly wider corridors (2 tiles)
    if rand < 0.5
      carve_horizontal(grid, corridor_mask, ax, bx, ay)
      carve_vertical(grid, corridor_mask, ay, by, bx)
    else
      carve_vertical(grid, corridor_mask, ay, by, ax)
      carve_horizontal(grid, corridor_mask, ax, bx, by)
    end
  end

  def carve_horizontal(grid, corridor_mask, x1, x2, y)
    Range.new(*[x1, x2].sort).each do |x|
      [-1, 0].each do |dy|
        ny = y + dy
        next if out_of_bounds?(x, ny) || border?(x, ny)

        grid[ny][x]          = false
        corridor_mask[ny][x] = true
      end
    end
  end

  def carve_vertical(grid, corridor_mask, y1, y2, x)
    Range.new(*[y1, y2].sort).each do |y|
      [-1, 0].each do |dx|
        nx = x + dx
        next if out_of_bounds?(nx, y) || border?(nx, y)

        grid[y][nx]          = false
        corridor_mask[y][nx] = true
      end
    end
  end

  # -------------------------------------------------------------
  # CELLULAR AUTOMATA
  # -------------------------------------------------------------
  def smooth(grid, corridor_mask)
    Array.new(@height) do |y|
      Array.new(@width) do |x|
        # Preserve carved corridors exactly
        if corridor_mask[y][x]
          false
        else
          walls = count_walls(grid, x, y)

          # Stronger wall preservation
          if walls >= 5
            true
          elsif walls <= 2
            false
          else
            grid[y][x]
          end
        end
      end
    end
  end

  def count_walls(grid, x, y)
    count = 0

    (-1..1).each do |dy|
      (-1..1).each do |dx|
        next if dx == 0 && dy == 0

        nx = x + dx
        ny = y + dy

        if out_of_bounds?(nx, ny)
          count += 1
        elsif grid[ny][nx]
          count += 1
        end
      end
    end

    count
  end

  # -------------------------------------------------------------
  # TILE BUILDING
  # -------------------------------------------------------------
  def build_tiles(grid)
    @tiles.clear

    @height.times do |y|
      @width.times do |x|
        if grid[y][x]
          add_tile(x, y, "wall_cave", true)
        else
          add_tile(x, y, "floor2", false)
        end
      end
    end
  end

  def add_tile(tx, ty, kind, solid)
    @tiles << Tile.new(
      tx * TILE_SIZE,
      ty * TILE_SIZE,
      kind,
      solid
    )
  end

  # -------------------------------------------------------------
  # HELPERS
  # -------------------------------------------------------------
  def border?(x, y)
    x <= 0 ||
      y <= 0 ||
      x >= @width - 1 ||
      y >= @height - 1
  end

  def out_of_bounds?(x, y)
    x < 0 || y < 0 || x >= @width || y >= @height
  end
def ensure_connectivity(grid)
  visited = Array.new(@height) { Array.new(@width, false) }

  # Convert spawn pixel → tile coords
  sx = @spawn_point[:x] / TILE_SIZE
  sy = @spawn_point[:y] / TILE_SIZE

  queue = [[sx, sy]]
  visited[sy][sx] = true

  # BFS flood fill
  until queue.empty?
    x, y = queue.shift

    [[1,0],[-1,0],[0,1],[0,-1]].each do |dx, dy|
      nx = x + dx
      ny = y + dy
      next if out_of_bounds?(nx, ny)
      next if visited[ny][nx]
      next if grid[ny][nx] == true  # wall

      visited[ny][nx] = true
      queue << [nx, ny]
    end
  end

  # Any floor tile not visited becomes a wall
  @height.times do |y|
    @width.times do |x|
      if grid[y][x] == false && !visited[y][x]
        grid[y][x] = true
      end
    end
  end

  grid
end

  # -------------------------------------------------------------
  # RANDOM FLOOR TILE
  # -------------------------------------------------------------
  def random_floor_tile
    floor_tiles = @tiles.reject(&:solid)
    tile = floor_tiles.sample
    return nil unless tile

    {
      x: tile.x,
      y: tile.y
    }
  end
end
