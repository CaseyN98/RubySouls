require_relative "damage_number"

class UI
  attr_reader :damage_numbers_world, :damage_numbers_screen

  SLOT_SIZE = 48
  INV_COLS  = 6

  def initialize(window, player)
    @window = window
    @player = player
    @font   = Gosu::Font.new(20, name: "Courier") rescue nil

    @damage_numbers_world  = []
    @damage_numbers_screen = []

    # Controller inventory cursor
    @cursor_index   = 0
    @cursor_active  = false
    @last_mouse_pos = [0, 0]

    @hovered_item  = nil
    @hovered_index = nil

    # Crafting
    @crafting_mode      = false
    @selected_for_craft = []
  end

  # -------------------------------------------------------------
  # DAMAGE NUMBERS
  # -------------------------------------------------------------
  def add_damage_world(x, y, amount, color = Gosu::Color::WHITE)
    @damage_numbers_world << DamageNumber.new(x, y, amount, color)
  end

  def add_damage_screen(x, y, amount, color = Gosu::Color::WHITE)
    @damage_numbers_screen << DamageNumber.new(x, y, amount, color)
  end

  # -------------------------------------------------------------
  # UPDATE
  # -------------------------------------------------------------
  def update
    update_damage_numbers
    update_crafting_toggle
    update_mouse_tracking

    if @player.inventory_open?
      update_inventory_navigation
      update_crafting_input
      update_hotbar_assignment
      update_craft_button
      update_weapon_unequip
    else
      reset_inventory_state
    end
	update_weapon_unequip
  end

  # -------------------------------------------------------------
  # UPDATE HELPERS
  # -------------------------------------------------------------
  def update_damage_numbers
    @damage_numbers_world.reject!(&:finished)
    @damage_numbers_screen.reject!(&:finished)

    @damage_numbers_world.each(&:update)
    @damage_numbers_screen.each(&:update)
  end

  def update_crafting_toggle
    return unless Input.craft_toggle?

    @crafting_mode = !@crafting_mode
    @selected_for_craft.clear unless @crafting_mode
  end

  def update_mouse_tracking
    curr_mouse = Input.mouse_pos(@window)

    if curr_mouse != @last_mouse_pos
      @cursor_active = false
      @last_mouse_pos = curr_mouse
    end
  end

  def update_inventory_navigation
    items = @player.inventory.items

    @cursor_active = true if Input.any_inventory_stick?

    if @cursor_active && !items.empty?
      max = items.length - 1

      if Input.inv_right?
        @cursor_index = (@cursor_index + 1) % items.length
      elsif Input.inv_left?
        @cursor_index = (@cursor_index - 1) % items.length
      elsif Input.inv_down?
        @cursor_index = (@cursor_index + INV_COLS) % items.length
      elsif Input.inv_up?
        @cursor_index = (@cursor_index - INV_COLS) % items.length
      end

      @cursor_index = [[@cursor_index, 0].max, max].min

      @hovered_item  = items[@cursor_index]
      @hovered_index = @cursor_index
    elsif items.empty?
      @hovered_item  = nil
      @hovered_index = nil
    end
  end

  def update_crafting_input
    return unless @crafting_mode

    if @cursor_active && Input.interact_pressed?
      toggle_craft_selection(@hovered_item)
    end

    if Input.mouse_left_pressed? && @hovered_item
      toggle_craft_selection(@hovered_item)
    end
  end

  def update_hotbar_assignment
    return if @crafting_mode

    if @cursor_active && Input.interact_pressed?
      assign_hovered_to_hotbar
    end

    if Input.mouse_left_pressed? && @hovered_item
      assign_hovered_to_hotbar
    end
  end

  def update_craft_button
    return unless @crafting_mode
    return unless @selected_for_craft.size >= 2

    bx = 100
    by = 380
    bw = 140
    bh = 40

    mx, my = Input.mouse_pos(@window)

    hovering =
      mx.between?(bx, bx + bw) &&
      my.between?(by, by + bh)

    try_craft if Input.craft_confirm_down?
    try_craft if hovering && Input.mouse_left_pressed?
  end

  def update_weapon_unequip
    base_x = 20
    base_y = 80

    mx, my = Input.mouse_pos(@window)

    hovered_weapon_slot =
      mx.between?(base_x, base_x + SLOT_SIZE) &&
      my.between?(base_y, base_y + SLOT_SIZE)

    if hovered_weapon_slot && Input.mouse_left_pressed?
      unequip_weapon
    end

    if Input.drop_pressed?
      unequip_weapon
    end
  end

  def reset_inventory_state
    @hovered_item  = nil
    @hovered_index = nil

    @selected_for_craft.clear

    @cursor_active = false
    @cursor_index  = 0
  end

  # -------------------------------------------------------------
  # EQUIPMENT
  # -------------------------------------------------------------
  def draw_equipment
    return unless @font

    base_x = 20
    base_y = 80

    Gosu.draw_rect(base_x, base_y, SLOT_SIZE, SLOT_SIZE, Gosu::Color::GRAY, 20)

    weapon = @player.equipped_weapon

    if weapon
      icon = weapon.icon || weapon.sprite

      if icon
        scale = [40.0 / icon.width, 40.0 / icon.height].min
        icon.draw(base_x + 4, base_y + 4, 22, scale, scale)
      end

      @font.draw_text(weapon.name, base_x + 60, base_y + 8, 23)
    else
      @font.draw_text("None", base_x + 60, base_y + 8, 23, 1, 1, Gosu::Color::GRAY)
    end

    @font.draw_text("ATK: #{@player.attack_power}", base_x, base_y + 58, 24)
    @font.draw_text("DEF: #{@player.defense_power}", base_x, base_y + 78, 24)

    if weapon&.kind == "bow" && weapon.props[:durability]
      dur = weapon.props[:durability]

      @font.draw_text(
        "DUR: #{dur}",
        base_x,
        base_y + 98,
        24,
        1,
        1,
        Gosu::Color::CYAN
      )
    end
  end

  # -------------------------------------------------------------
  # HOTBAR
  # -------------------------------------------------------------
  def draw_hotbar
    icons    = @player.inventory.hotbar_icons
    selected = @player.inventory.selected_index

    base_x  = 20
    base_y  = 520
    padding = 8

    icons.each_with_index do |icon, i|
      x = base_x + i * (SLOT_SIZE + padding)

      Gosu.draw_rect(x, base_y, SLOT_SIZE, SLOT_SIZE, Gosu::Color::GRAY, 10)

      if i == selected
        Gosu.draw_rect(
          x - 2,
          base_y - 2,
          SLOT_SIZE + 4,
          SLOT_SIZE + 4,
          Gosu::Color::YELLOW,
          9
        )
      end

      next unless icon

      scale = [40.0 / icon.width, 40.0 / icon.height].min
      icon.draw(x + 4, base_y + 4, 11, scale, scale)
    end
  end

  # -------------------------------------------------------------
  # CRAFTING
  # -------------------------------------------------------------
  def toggle_craft_selection(item)
    return unless item

    if @selected_for_craft.include?(item)
      @selected_for_craft.delete(item)
    elsif @selected_for_craft.size < 3
      @selected_for_craft << item
    end
  end

  def assign_hovered_to_hotbar
    return unless @hovered_item

    idx = @player.inventory.selected_index
    @player.inventory.assign_to_hotbar(idx, @hovered_item)
  end

  def try_craft
    return unless @crafting_mode
    return unless @selected_for_craft.size >= 2

    ids = @selected_for_craft.map(&:id).sort

    result_id = $crafting_system.craft(ids)

    unless result_id
      add_damage_screen(300, 200, "Invalid recipe", Gosu::Color::RED)
      return
    end

    @selected_for_craft.each do |item|
      @player.inventory.remove(item)
    end

    new_item = Item.new(result_id, ITEM_DB[result_id])

    @player.inventory.add(new_item)

    add_damage_screen(
      300,
      200,
      "Crafted: #{new_item.name}",
      Gosu::Color::CYAN
    )

    @selected_for_craft.clear
  end

  def unequip_weapon
    return unless @player.equipped_weapon

    @player.inventory.unequip_weapon

    add_damage_screen(
      300,
      200,
      "Weapon removed",
      Gosu::Color::YELLOW
    )
  end

  # -------------------------------------------------------------
  # WORLD DRAWING
  # -------------------------------------------------------------
  def draw_world(cam_x, cam_y)
    return unless @font

    @damage_numbers_world.sort_by!(&:y) rescue nil

    @damage_numbers_world.each do |n|
      n.draw(@font, cam_x, cam_y)
    end
  end

  # -------------------------------------------------------------
  # INVENTORY
  # -------------------------------------------------------------
  def draw_inventory
    items = @player.inventory.items
    return if items.empty?

    win_x = 100
    win_y = 150

    win_w = 580
    win_h = 360

    Gosu.draw_rect(
      win_x,
      win_y,
      win_w,
      win_h,
      Gosu::Color.argb(0xaa000000),
      40
    )

    title       = @crafting_mode ? "Crafting Mode" : "Inventory"
    title_color = @crafting_mode ? Gosu::Color::CYAN : Gosu::Color::WHITE

    @font.draw_text(
      title,
      win_x + 20,
      win_y + 10,
      41,
      1.2,
      1.2,
      title_color
    )

    padding = 12
    scale   = 48.0 / 32.0

    start_x = win_x + 20
    start_y = win_y + 60

    mouse_x, mouse_y = Input.mouse_pos(@window)

    unless @cursor_active
      @hovered_item  = nil
      @hovered_index = nil
    end

    items.each_with_index do |item, i|
      col = i % INV_COLS
      row = i / INV_COLS

      x = start_x + col * (SLOT_SIZE + padding)
      y = start_y + row * (SLOT_SIZE + padding)

      Gosu.draw_rect(x, y, SLOT_SIZE, SLOT_SIZE, Gosu::Color::GRAY, 42)

      # Mouse hover
      if !@cursor_active &&
         mouse_x.between?(x, x + SLOT_SIZE) &&
         mouse_y.between?(y, y + SLOT_SIZE)

        Gosu.draw_rect(
          x,
          y,
          SLOT_SIZE,
          SLOT_SIZE,
          Gosu::Color.argb(0x55ffffff),
          43
        )

        @hovered_item  = item
        @hovered_index = i
      end

      # Controller highlight
      if @cursor_active && i == @cursor_index
        Gosu.draw_rect(
          x,
          y,
          SLOT_SIZE,
          SLOT_SIZE,
          Gosu::Color.argb(0x55ffff00),
          46
        )

        @hovered_item  = item
        @hovered_index = i
      end

      # Craft highlight
      if @crafting_mode && @selected_for_craft.include?(item)
        Gosu.draw_rect(
          x,
          y,
          SLOT_SIZE,
          SLOT_SIZE,
          Gosu::Color.argb(0x5500aaff),
          44
        )
      end

      item.sprite&.draw(x + 4, y + 4, 45, scale, scale)
    end

    draw_hovered_item_tooltip(start_x, start_y, padding)

    draw_craft_button if @crafting_mode && @selected_for_craft.size >= 2
  end

  def draw_hovered_item_tooltip(start_x, start_y, padding)
    return unless @hovered_item

    mouse_x, mouse_y = Input.mouse_pos(@window)

    tx = mouse_x + 12
    ty = mouse_y + 12

    if @cursor_active && @hovered_index
      col = @hovered_index % INV_COLS
      row = @hovered_index / INV_COLS

      tx = start_x + col * (SLOT_SIZE + padding) + 60
      ty = start_y + row * (SLOT_SIZE + padding)
    end

    @font.draw_text(@hovered_item.name, tx, ty, 50)
  end

  # -------------------------------------------------------------
  # CRAFT BUTTON
  # -------------------------------------------------------------
  def draw_craft_button
    bx = 100
    by = 380
    bw = 140
    bh = 40

    mx, my = Input.mouse_pos(@window)

    hovering =
      mx.between?(bx, bx + bw) &&
      my.between?(by, by + bh)

    color =
      hovering ?
      Gosu::Color.argb(0xcc00ff00) :
      Gosu::Color.argb(0xaa00aa00)

    Gosu.draw_rect(bx, by, bw, bh, color, 60)

    @font.draw_text("CRAFT", bx + 20, by + 8, 61)
  end

  # -------------------------------------------------------------
  # HUD
  # -------------------------------------------------------------
  def draw_hud
    return unless @font

    draw_hotbar
    draw_equipment

    draw_inventory if @player.inventory_open?

    draw_bar(
      20,
      20,
      200,
      12,
      @player.hp / @player.max_hp.to_f,
      Gosu::Color::RED
    )

    draw_bar(
      20,
      40,
      200,
      12,
      @player.stamina / @player.max_stamina.to_f,
      Gosu::Color::GREEN
    )

    @font.draw_text("HP: #{@player.hp.to_i}", 230, 16, 100)
    @font.draw_text("ST: #{@player.stamina.to_i}", 230, 36, 100)

    xp_ratio = @player.xp.to_f / @player.xp_to_next.to_f

    draw_bar(20, 60, 200, 12, xp_ratio, Gosu::Color::BLUE)

    @font.draw_text("LV: #{@player.level}", 230, 52, 100)
    @font.draw_text("XP: #{@player.xp}/#{@player.xp_to_next}", 230, 68, 100)

    buff_timer = @player.instance_variable_get(:@stamina_buff_timer).to_i

    if buff_timer > 0
      @font.draw_text(
        "Stamina Boost Active",
        20,
        80,
        100,
        1.0,
        1.0,
        Gosu::Color::CYAN
      )
    end

    @damage_numbers_screen.each do |n|
      n.draw(@font, 0, 0)
    end
  end

  # -------------------------------------------------------------
  # BARS
  # -------------------------------------------------------------
  def draw_bar(x, y, w, h, ratio, color)
    ratio = [[ratio, 0.0].max, 1.0].min

    Gosu.draw_rect(
      x,
      y,
      w,
      h,
      Gosu::Color.argb(0xaa666666),
      90
    )

    Gosu.draw_rect(
      x,
      y,
      w * ratio,
      h,
      color,
      91
    )
  end

  # -------------------------------------------------------------
  # ROGUE FLOOR
  # -------------------------------------------------------------
 def draw_rogue_floor(floor)
  return unless @font

  @font.draw_text(
    "Floor #{floor}",
    20,
    200,   # moved down so it sits below the equipment panel
    100,
    1.2,
    1.2,
    Gosu::Color::WHITE
  )
end

end