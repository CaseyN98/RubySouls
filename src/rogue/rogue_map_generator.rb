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

  # -------------------------------------------------------------
  # MAIN GENERATION PIPELINE
  # -------------------------------------------------------------
  def generate
    # 1. Initial random fill (balanced)
    grid = Array.new(@height) { Array.new(@width, false) }

    @height.times do |y|
      @width.times do |x|
        if border?(x, y)
          grid[y][x] = true
        else
          grid[y][x] = rand < 0.45
        end
      end
    end

    # 2. Carve rooms BEFORE smoothing
    rooms = []

    # Spawn room
    spawn_room = { x: @width/2 - 4, y: @height/2 - 4, w: 8, h: 8 }
    carve_room(grid, spawn_room[:x], spawn_room[:y], spawn_room[:w], spawn_room[:h])
    rooms << spawn_room

    # Add more rooms (this is the ONLY change)
    rand(6..10).times do
      rx = rand(3..@width - 12)
      ry = rand(3..@height - 12)
      rw = rand(5..10)
      rh = rand(5..10)
      carve_room(grid, rx, ry, rw, rh)
      rooms << { x: rx, y: ry, w: rw, h: rh }
    end

    # 3. Connect rooms
    connect_rooms(grid, rooms)

    # 4. Light smoothing (keeps structure)
    2.times do
      grid = smooth(grid)
    end

    # 5. Convert to tiles
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

  # -------------------------------------------------------------
  # ROOM CARVING
  # -------------------------------------------------------------
  def carve_room(grid, x, y, w, h)
    (y...(y + h)).each do |yy|
      (x...(x + w)).each do |xx|
        next if xx <= 0 || yy <= 0 || xx >= @width - 1 || yy >= @height - 1
        grid[yy][xx] = false
      end
    end
  end

  # -------------------------------------------------------------
  # CONNECT ROOMS WITH CORRIDORS
  # -------------------------------------------------------------
  def connect_rooms(grid, rooms)
    rooms.each_cons(2) do |a, b|
      carve_corridor(grid, a, b)
    end
  end

  def carve_corridor(grid, room_a, room_b)
    ax = room_a[:x] + room_a[:w] / 2
    ay = room_a[:y] + room_a[:h] / 2
    bx = room_b[:x] + room_b[:w] / 2
    by = room_b[:y] + room_b[:h] / 2

    carve_line(grid, ax, ay, bx, ay)
    carve_line(grid, bx, ay, bx, by)
  end

  def carve_line(grid, x1, y1, x2, y2)
    if x1 == x2
      Range.new(*[y1, y2].sort).each { |y| grid[y][x1] = false }
    elsif y1 == y2
      Range.new(*[x1, x2].sort).each { |x| grid[y1][x] = false }
    end
  end

  # -------------------------------------------------------------
  # CELLULAR AUTOMATA SMOOTHING
  # -------------------------------------------------------------
  def smooth(grid)
    new_grid = Array.new(@height) { Array.new(@width, false) }

    @height.times do |y|
      @width.times do |x|
        wall_count = count_walls(grid, x, y)

        if wall_count >= 5
          new_grid[y][x] = true
        elsif wall_count <= 3
          new_grid[y][x] = false
        else
          new_grid[y][x] = grid[y][x]
        end
      end
    end

    new_grid
  end

  def count_walls(grid, x, y)
    count = 0

    (-1..1).each do |dy|
      (-1..1).each do |dx|
        nx = x + dx
        ny = y + dy

        next if dx == 0 && dy == 0

        if nx < 0 || ny < 0 || nx >= @width || ny >= @height
          count += 1
        elsif grid[ny][nx]
          count += 1
        end
      end
    end

    count
  end

  # -------------------------------------------------------------
  # HELPERS
  # -------------------------------------------------------------
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
