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

  def self.weak_pool
    [
      loot("health_potion"),
      loot("health_potion_1"),
      loot("stamina_potion"),
      loot("wooden_bow"),
      loot("iron_sword"),
      loot("iron_axe"),
      loot("upgrade_stone"),
      loot("fire_orb")     
    ].compact
  end

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
      loot("flame_bow"),
      loot("fire_sword"),
      loot("black_sword"),
      loot("upgrade_stone"),
      loot("fire_orb"),
      loot("water_orb")
    ].compact
  end

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
      loot("black_sword_1"),
      loot("black_sword_2"),
      loot("key_blade"),
      loot("upgrade_stone"),
      loot("fire_orb"),
      loot("water_orb")
    ].compact
  end

  def self.loot(item_id)
    return nil unless ITEM_DB[item_id]

    {
      "kind"   => ITEM_DB[item_id]["kind"],
      "item"   => item_id,   # FIXED: Chest expects "item", not "item_id"
      "amount" => 1
    }
  end
end
