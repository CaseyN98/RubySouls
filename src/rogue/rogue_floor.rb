# src/rogue/rogue_floor.rb
require_relative "rogue_enemy_pool"
require_relative "rogue_loot"
require_relative "rogue_map"

class RogueFloor
  attr_reader :map, :enemies, :boss, :chests, :exit_tile

  def initialize(floor_number)
    @floor_number = floor_number

    @map = RogueMap.new(40, 25)

    generate_enemies
    generate_boss
    generate_chests
    generate_exit
  end

  # -------------------------------------------------------------
  # Helper: pick a floor tile NOT inside the spawn room
  # -------------------------------------------------------------
  def safe_random_tile
    loop do
      pos = @map.random_floor_tile
      return pos unless near_spawn?(pos)
    end
  end

  def near_spawn?(pos)
    sx = @map.spawn_point[:x]
    sy = @map.spawn_point[:y]
    (pos[:x] - sx).abs < 64 && (pos[:y] - sy).abs < 64
  end

  # -------------------------------------------------------------
  # Enemies
  # -------------------------------------------------------------
  def generate_enemies
    # Balanced: 5–7 enemies per floor
    count = 3 + rand(2..4)
    @enemies = []

    count.times do
      base = RogueEnemyPool.random_enemy_for_floor(@floor_number)

      pos = safe_random_tile
      @enemies << {
        x: pos[:x],
        y: pos[:y],
        type: base[:type],
        props: base[:props]
      }
    end
  end

  # -------------------------------------------------------------
  # Boss — spawn far from player
  # -------------------------------------------------------------
  def generate_boss
    base = RogueEnemyPool.random_boss_for_floor(@floor_number)

    # Try 50 random tiles, pick the furthest from spawn
    spawn = @map.spawn_point
    candidates = 50.times.map { @map.random_floor_tile }

    far = candidates.max_by do |pos|
      dx = pos[:x] - spawn[:x]
      dy = pos[:y] - spawn[:y]
      dx * dx + dy * dy
    end

    @boss = {
      x: far[:x],
      y: far[:y],
      type: base[:type],
      props: base[:props]
    }
  end

  # -------------------------------------------------------------
  # Chests — spawn in rooms, not corridors
  # -------------------------------------------------------------
  def generate_chests
    count = 1 + rand(1..2)
    @chests = []

    count.times do
      loot_count = rand(2..4)

      loot_items = loot_count.times.map do
        loot = RogueLoot.random_for_floor(@floor_number)
        loot["item"]
      end

      chest_props = { "loot" => loot_items }

      pos = safe_random_tile

      @chests << {
        x: pos[:x],
        y: pos[:y],
        props: chest_props
      }
    end
  end

  # -------------------------------------------------------------
  # Exit tile — also avoid spawn room
  # -------------------------------------------------------------
  def generate_exit
    pos = safe_random_tile
    @exit_tile = {
      x: pos[:x],
      y: pos[:y],
      width: 16,
      height: 16
    }
  end
end
