require "json"

class CraftingSystem
  attr_reader :recipes

  def initialize
    path = File.join(__dir__, "../../src/entities/crafting_recipes.json")
    @recipes = JSON.parse(File.read(path), symbolize_names: true)
  end

  # -------------------------------------------------------------
  # Crafting entry point
  # -------------------------------------------------------------
  def craft(items_or_ids)
    item_ids = items_or_ids.map { |it| it.respond_to?(:id) ? it.id : it }

    # 1. Element infusion (fire orb → flame weapons)
    if (infused = element_infuse(item_ids))
      return infused if ITEM_DB[infused] || generate_item_tier(infused)
    end

    # 2. Auto-upgrade logic (merge or upgrade stone)
    if (auto = auto_upgrade(item_ids))
      return auto if ITEM_DB[auto] || generate_item_tier(auto)
    end

    # 3. Special recipes (keys, black_sword, fire_sword, etc.)
    @recipes.each do |_name, recipe|
      inputs = recipe[:inputs]
      next unless match_inputs?(inputs, item_ids)
      return recipe[:output]
    end

    nil
  end

  # -------------------------------------------------------------
  # ELEMENT INFUSION (fire orb → flame weapons)
  # -------------------------------------------------------------
def element_infuse(item_ids)
  # FIRE infusion
  if item_ids.include?("fire_orb")
    other = item_ids.find { |id| id != "fire_orb" }
    return nil unless other

    # iron_sword_* → fire_sword_*
    if other.start_with?("iron_sword")
      tier = extract_tier(other)
      return tier.zero? ? "fire_sword" : "fire_sword_#{tier}"
    end

    # wooden_bow_* → flame_bow_*
    if other.start_with?("wooden_bow")
      tier = extract_tier(other)
      return tier.zero? ? "flame_bow" : "flame_bow_#{tier}"
    end

    # spiked_club → flame_club
    if other.start_with?("spiked_club")
      tier = extract_tier(other)
      return tier.zero? ? "flame_club" : "flame_club_#{tier}"
    end
  end

  # WATER infusion
  if item_ids.include?("water_orb")
    other = item_ids.find { |id| id != "water_orb" }
    return nil unless other

    # iron_sword_* → water_sword_*
    if other.start_with?("iron_sword")
      tier = extract_tier(other)
      return tier.zero? ? "water_sword" : "water_sword_#{tier}"
    end

    # wooden_bow_* → water_bow_*
    if other.start_with?("wooden_bow")
      tier = extract_tier(other)
      return tier.zero? ? "water_bow" : "water_bow_#{tier}"
    end

    # spiked_club → water_staff
    if other.start_with?("spiked_club")
      tier = extract_tier(other)
      return tier.zero? ? "water_staff" : "water_staff_#{tier}"
    end
  end

  nil
end

  # Extract tier number from id (iron_sword_3 → 3)
  def extract_tier(id)
    id =~ /_(\d+)$/ ? Regexp.last_match(1).to_i : 0
  end

  # -------------------------------------------------------------
  # AUTO-UPGRADE LOGIC
  # -------------------------------------------------------------
  def auto_upgrade(item_ids)
    return nil unless item_ids.size == 2

    a, b = item_ids

    # Case 1: Two identical items → merge upgrade
    return next_tier(a) if a == b

    # Case 2: Item + upgrade_stone → upgrade
    return next_tier(b) if a == "upgrade_stone"
    return next_tier(a) if b == "upgrade_stone"

    nil
  end

  # -------------------------------------------------------------
  # Compute next tier name
  # -------------------------------------------------------------
  def next_tier(id)
    if id =~ /(.*)_(\d+)$/
      base = Regexp.last_match(1)
      tier = Regexp.last_match(2).to_i
      "#{base}_#{tier + 1}"
    else
      "#{id}_1"
    end
  end

  # -------------------------------------------------------------
  # AUTO-GENERATE ITEM TIERS (ENDLESS SCALING)
  # -------------------------------------------------------------
  def generate_item_tier(id)
    return nil unless id =~ /(.*)_(\d+)$/

    base = Regexp.last_match(1)
    tier = Regexp.last_match(2).to_i
    base_item = ITEM_DB[base]
    return nil unless base_item

    new_item = deep_clone(base_item)

    # Auto-name
    new_item[:name] = "#{base_item[:name]} +#{tier}"

    # Auto-scale stats
    if base_item[:atk]
      new_item[:atk] = base_item[:atk] + (tier * 8)
    end

    if base_item[:durability]
      new_item[:durability] = base_item[:durability] + (tier * 20)
    end

    if base_item[:heal]
      new_item[:heal] = base_item[:heal] + (tier * 20)
    end

    ITEM_DB[id] = new_item
    id
  end

  def deep_clone(obj)
    Marshal.load(Marshal.dump(obj))
  end

  # -------------------------------------------------------------
  # Input matching logic for special recipes
  # -------------------------------------------------------------
  def match_inputs?(recipe_inputs, player_inputs)
    return false unless recipe_inputs.size == player_inputs.size

    needed = recipe_inputs.map(&:dup)
    have   = player_inputs.map(&:dup)

    needed.each do |req|
      if req.start_with?("any_")
        type = req.sub("any_", "")
        match = have.find { |id| id.include?(type) }
        return false unless match
        have.delete(match)
      else
        return false unless have.include?(req)
        have.delete_at(have.index(req))
      end
    end

    true
  end
end
