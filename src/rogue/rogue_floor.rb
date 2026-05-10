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
  # Enemies
  # -------------------------------------------------------------
  def generate_enemies
    # Balanced: 5–7 enemies per floor
    count = 3 + rand(2..4)
    @enemies = []

    count.times do
      base = RogueEnemyPool.random_enemy_for_floor(@floor_number)

      pos = @map.random_floor_tile  # ensures valid tile
      @enemies << {
        x: pos[:x],
        y: pos[:y],
        type: base[:type],
        props: base[:props]
      }
    end
  end

  # -------------------------------------------------------------
  # Boss
  # -------------------------------------------------------------
  def generate_boss
    base = RogueEnemyPool.random_boss_for_floor(@floor_number)

    pos = @map.random_floor_tile
    @boss = {
      x: pos[:x],
      y: pos[:y],
      type: base[:type],
      props: base[:props]
    }
  end

  # -------------------------------------------------------------
  # Chests
  # -------------------------------------------------------------
def generate_chests
  count = 1 + rand(1..2)
  @chests = []

  count.times do
    # 1–4 items per chest
    loot_count = rand(2..4)

    loot_items = loot_count.times.map do
      loot = RogueLoot.random_for_floor(@floor_number)
      loot["item"]   # extract item id
    end

    chest_props = {
      "loot" => loot_items  # Chest supports arrays
    }

    pos = @map.random_floor_tile

    @chests << {
      x: pos[:x],
      y: pos[:y],
      props: chest_props
    }
  end
end


  # -------------------------------------------------------------
  # Exit tile
  # -------------------------------------------------------------
  def generate_exit
    pos = @map.random_floor_tile
    @exit_tile = {
      x: pos[:x],
      y: pos[:y],
      width: 16,
      height: 16
    }
  end
end
