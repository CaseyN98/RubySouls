require_relative "hotbar"

class Inventory
  attr_reader :items, :hotbar
  attr_accessor :equipped_weapon, :equipped_armor

  def initialize
    @items  = []
    @hotbar = Hotbar.new(3)

    @equipped_weapon = nil
    @equipped_armor  = nil
  end

  # -------------------------------------------------------------
  # Add item to inventory
  # -------------------------------------------------------------
  def add(item)
    @items << item
  end

  # -------------------------------------------------------------
  # Remove item safely
  # -------------------------------------------------------------
  def remove(item)
    @items.delete(item)

    # Clean hotbar references
    @hotbar.slots.map! { |slot| slot == item ? nil : slot }
  end

  # -------------------------------------------------------------
  # Key helpers
  # -------------------------------------------------------------
  def keys
    @items
      .select { |i| i.kind == "key" }
      .map    { |i| i.props[:key_id].to_s.strip }
  end

  def has_key?(id)
    @items.any? do |i|
      i.kind == "key" && i.props[:key_id].to_s == id.to_s
    end
  end

  # -------------------------------------------------------------
  # Equipment handling
  # -------------------------------------------------------------
  def equip_weapon(item)
    # Return current weapon to inventory
    if @equipped_weapon
      @items << @equipped_weapon
    end

    @equipped_weapon = item
    remove(item)
  end

def unequip_weapon
  return unless @equipped_weapon

  # Return weapon to inventory
  @items << @equipped_weapon

  # Remove from hotbar if present
  @hotbar.slots.map! { |slot| slot == @equipped_weapon ? nil : slot }

  @equipped_weapon = nil
end


  # -------------------------------------------------------------
  # Hotbar selection (delegation)
  # -------------------------------------------------------------
  def select_next
    @hotbar.next
  end

  def select_prev
    @hotbar.prev
  end

  def selected_item
    @hotbar.current
  end

  def selected_index
    @hotbar.selected_index
  end
def assign_to_hotbar(index, item)
  return if item && (item.kind == "key" || item.kind == "material")
  @hotbar.slots[index] = item
end




  # -------------------------------------------------------------
  # UI helpers
  # -------------------------------------------------------------
  def hotbar_icons
    @hotbar.icons
  end

  def hotbar_slots
    {
      slots: @hotbar.slots,
      selected: @hotbar.selected_index
    }
  end
end
