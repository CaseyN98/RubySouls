# src/rogue/rogue_loot.rb
require_relative "../entities/item_db"

class RogueLoot
  def self.random_for_floor(floor)
    pool =
      if floor < 3
        weak_pool
      elsif floor < 7
        mid_pool
      else
        strong_pool
      end

    pool.sample
  end

  # -------------------------------------------------------------
  # WEAK FLOORS (1–2)
  # -------------------------------------------------------------
  def self.weak_pool
    [
      loot("health_potion"),
      loot("health_potion_1"),
      loot("stamina_potion"),
      loot("wooden_bow"),
      loot("iron_sword"),
      loot("iron_axe"),
      loot("spiked_club"),
      loot("upgrade_stone"),
      loot("fire_orb"),
      loot("water_orb")
    ].compact
  end

  # -------------------------------------------------------------
  # MID FLOORS (3–6)
  # -------------------------------------------------------------
  def self.mid_pool
    [
      loot("health_potion_1"),
      loot("health_potion_2"),
      loot("stamina_potion_1"),
      loot("stamina_potion_2"),

      loot("iron_sword_1"),
      loot("iron_sword_2"),
      loot("iron_axe_1"),
      loot("iron_axe_2"),
      loot("wooden_bow_1"),
      loot("wooden_bow_2"),

      loot("fire_sword"),
      loot("flame_bow"),
      loot("flame_club"),
      loot("water_sword"),
      loot("water_bow"),
      loot("water_staff"),

      loot("black_sword"),
      loot("upgrade_stone"),
      loot("fire_orb"),
      loot("water_orb")
    ].compact
  end

  # -------------------------------------------------------------
  # STRONG FLOORS (7+)
  # -------------------------------------------------------------
  def self.strong_pool
    [
      loot("health_potion_2"),
      loot("health_potion_3"),
      loot("stamina_potion_2"),
      loot("stamina_potion_3"),

      loot("iron_sword_3"),
      loot("iron_axe_3"),
      loot("wooden_bow_3"),

      loot("flame_bow_1"),
      loot("flame_bow_2"),
      loot("flame_bow_3"),

      loot("fire_sword_1"),
      loot("fire_sword_2"),
      loot("fire_sword_3"),

      loot("flame_club_1"),
      loot("flame_club_2"),
      loot("flame_club_3"),

      loot("water_sword_1"),
      loot("water_sword_2"),
      loot("water_sword_3"),

      loot("water_bow_1"),
      loot("water_bow_2"),
      loot("water_bow_3"),

      loot("water_staff_1"),
      loot("water_staff_2"),
      loot("water_staff_3"),

      loot("black_sword_1"),
      loot("black_sword_2"),

      loot("key_blade"),
      loot("upgrade_stone"),
      loot("fire_orb"),
      loot("water_orb")
    ].compact
  end

  # -------------------------------------------------------------
  # Loot wrapper
  # -------------------------------------------------------------
  def self.loot(item_id)
    return nil unless ITEM_DB[item_id]

    {
      "kind"   => ITEM_DB[item_id]["kind"],
      "item"   => item_id,
      "amount" => 1
    }
  end
end
