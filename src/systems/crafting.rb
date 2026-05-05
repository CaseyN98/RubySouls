require "json"

class CraftingSystem
attr_reader :recipes

  def initialize
    # Resolve path relative to this file, so it works no matter where the game is run from
    path = File.join(__dir__, "../../src/entities/crafting_recipes.json")
    @recipes = JSON.parse(File.read(path), symbolize_names: true)
  end

  # -------------------------------------------------------------
  # Crafting entry point
  # items_or_ids = array of Item instances OR String IDs
  # Returns: item_id string OR nil
  # -------------------------------------------------------------
  def craft(items_or_ids)
    # Allow both Item instances and raw IDs for flexibility
    item_ids = items_or_ids.map { |it| it.respond_to?(:id) ? it.id : it }

    @recipes.each do |_name, recipe|
      inputs = recipe[:inputs]
      next unless match_inputs?(inputs, item_ids)

      return recipe[:output]
    end

    nil
  end

  # -------------------------------------------------------------
  # Input matching logic
  # Supports:
  #   - 2 or 3 item recipes
  #   - unordered matching
  #   - simple wildcards: "any_<substring>" (matches id including substring)
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
