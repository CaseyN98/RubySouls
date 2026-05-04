require_relative "damage_number"

class UI
  attr_reader :damage_numbers_world, :damage_numbers_screen

  def initialize(window, player)
    @window = window
    @player = player
    @font   = Gosu::Font.new(20, name: "Courier") rescue nil

    @damage_numbers_world  = []
    @damage_numbers_screen = []

    # Controller inventory cursor
    @cursor_index  = 0
    @cursor_active = false
    @last_mouse_pos = [0, 0]
    @hovered_item  = nil
    @hovered_index = nil

    # Crafting
    @crafting_mode = false
    @selected_for_craft = []
  end

  # -------------------------------------------------------------
  # Damage number helpers
  # -------------------------------------------------------------
  def add_damage_world(x, y, amount, color = Gosu::Color::WHITE)
    @damage_numbers_world << DamageNumber.new(x, y, amount, color)
  end

  def add_damage_screen(x, y, amount, color = Gosu::Color::WHITE)
    @damage_numbers_screen << DamageNumber.new(x, y, amount, color)
  end

  # -------------------------------------------------------------
  # Equipment + stats rendering
  # -------------------------------------------------------------
  def draw_equipment
    return unless @font

    base_x = 20
    base_y = 80
    slot_size = 48

    Gosu.draw_rect(base_x, base_y, slot_size, slot_size, Gosu::Color::GRAY, 20)

    weapon = @player.equipped_weapon

    if weapon
      icon = weapon.icon || weapon.sprite
      if icon
        scale = 48.0 / icon.width
        icon.draw(base_x + 4, base_y + 4, 22, scale, scale)
      end
      @font.draw_text(weapon.name, base_x + 60, base_y + 8, 23)
    else
      @font.draw_text("None", base_x + 60, base_y + 8, 23, 1, 1, Gosu::Color::GRAY)
    end

    @font.draw_text("ATK: #{@player.attack_power}", base_x, base_y + slot_size + 10, 24)
    @font.draw_text("DEF: #{@player.defense_power}", base_x, base_y + slot_size + 30, 24)

    if weapon && weapon.kind == "bow" && weapon.props[:durability]
      dur = weapon.props[:durability]
      @font.draw_text("DUR: #{dur}", base_x, base_y + slot_size + 50, 24, 1, 1, Gosu::Color::CYAN)
    end
  end

  # -------------------------------------------------------------
  # Hotbar rendering
  # -------------------------------------------------------------
  def draw_hotbar
    icons    = @player.inventory.hotbar_icons
    selected = @player.inventory.selected_index

    base_x    = 20
    base_y    = 520
    slot_size = 48
    padding   = 8

    icons.each_with_index do |icon, i|
      x = base_x + i * (slot_size + padding)

      Gosu.draw_rect(x, base_y, slot_size, slot_size, Gosu::Color::GRAY, 10)

      if i == selected
        Gosu.draw_rect(x - 2, base_y - 2, slot_size + 4, slot_size + 4, Gosu::Color::YELLOW, 9)
      end

      next unless icon

      scale = 48.0 / icon.width
      icon.draw(x + 4, base_y + 4, 11, scale, scale)
    end
  end

  # -------------------------------------------------------------
  # UPDATE
  # -------------------------------------------------------------
  def update
    # Damage numbers
    @damage_numbers_world.reject!(&:finished)
    @damage_numbers_screen.reject!(&:finished)

    @damage_numbers_world.each(&:update)
    @damage_numbers_screen.each(&:update)

    # Toggle crafting mode
    if Input.craft_toggle?
      @crafting_mode = !@crafting_mode
      @selected_for_craft.clear unless @crafting_mode
    end

    # Mouse movement disables controller cursor
    curr_mouse = Input.mouse_pos(@window)
    if curr_mouse != @last_mouse_pos
      @cursor_active = false
      @last_mouse_pos = curr_mouse
    end

    # Controller Navigation (Right Stick)
    if @player.inventory_open?
      items = @player.inventory.items

      @cursor_active = true if Input.any_inventory_stick?

      if @cursor_active && !items.empty?
        max  = items.length - 1
        cols = 6

        if Input.inv_right?
          @cursor_index = (@cursor_index + 1) % items.length
        elsif Input.inv_left?
          @cursor_index = (@cursor_index - 1) % items.length
        elsif Input.inv_down?
          @cursor_index = [@cursor_index + cols, max].min
        elsif Input.inv_up?
          @cursor_index = [@cursor_index - cols, 0].max
        end

        @cursor_index = [[@cursor_index, 0].max, max].min

        @hovered_item  = items[@cursor_index]
        @hovered_index = @cursor_index
      elsif items.empty?
        @hovered_item = nil
        @hovered_index = nil
      end
    end

    # ---------------------------------------------------------
    # CRAFTING SELECTION
    # ---------------------------------------------------------
    if @player.inventory_open? && @crafting_mode
      if @cursor_active && Input.interact_pressed?
        toggle_craft_selection(@hovered_item)
      end

      if Input.mouse_left_pressed? && @hovered_item
        toggle_craft_selection(@hovered_item)
      end
    end

    # ---------------------------------------------------------
    # HOTBAR ASSIGNMENT
    # ---------------------------------------------------------
    if @player.inventory_open? && !@crafting_mode
      if @cursor_active && Input.interact_pressed?
        assign_hovered_to_hotbar
      end

      if Input.mouse_left_pressed? && @hovered_item
        assign_hovered_to_hotbar
      end
    end

    # ---------------------------------------------------------
    # CRAFT BUTTON CLICK
    # ---------------------------------------------------------
    if @player.inventory_open? && @crafting_mode && @selected_for_craft.size >= 2
      bx = 100
      by = 380
      bw = 140
      bh = 40

      mx, my = Input.mouse_pos(@window)
      hovering = mx.between?(bx, bx + bw) && my.between?(by, by + bh)

      # ENTER crafts regardless of hover
      try_craft if Input.craft_confirm_down?

      # Mouse click crafts only when hovering
      try_craft if hovering && Input.mouse_left_down?
    end

    # ---------------------------------------------------------
    # RESET WHEN INVENTORY CLOSES
    # ---------------------------------------------------------
    unless @player.inventory_open?
      @hovered_item  = nil
      @hovered_index = nil
      @selected_for_craft.clear
      @cursor_active = false
      @cursor_index  = 0
    end
  end

  # -------------------------------------------------------------
  # Crafting helpers
  # -------------------------------------------------------------
  def toggle_craft_selection(item)
    return unless item
    if @selected_for_craft.include?(item)
      @selected_for_craft.delete(item)
    else
      @selected_for_craft << item if @selected_for_craft.size < 3
    end
  end

  def assign_hovered_to_hotbar
    return unless @hovered_item
    idx = @player.inventory.selected_index
    @player.inventory.assign_to_hotbar(idx, @hovered_item)
  end

  # -------------------------------------------------------------
  # Crafting execution
  # -------------------------------------------------------------
  def try_craft
    return unless @crafting_mode
    return unless @selected_for_craft.size >= 2

    ids = @selected_for_craft.map(&:id)
    result_id = $crafting_system.craft(ids)

    unless result_id
      add_damage_screen(300, 200, "Invalid recipe", Gosu::Color::RED)
      return
    end

    @selected_for_craft.each { |item| @player.inventory.remove(item) }

    new_item = Item.new(result_id, ITEM_DB[result_id])
    @player.inventory.add(new_item)

    add_damage_screen(300, 200, "Crafted: #{new_item.name}", Gosu::Color::CYAN)

    @selected_for_craft.clear
  end

  # -------------------------------------------------------------
  # World-space rendering
  # -------------------------------------------------------------
  def draw_world(cam_x, cam_y)
    return unless @font

    @damage_numbers_world.sort_by!(&:y) rescue nil
    @damage_numbers_world.each { |n| n.draw(@font, cam_x, cam_y) }
  end

  # -------------------------------------------------------------
  # Inventory rendering
  # -------------------------------------------------------------
  def draw_inventory
    items = @player.inventory.items
    return if items.empty?

    win_x = 80
    win_y = 80
    win_w = 480
    win_h = 360

    Gosu.draw_rect(win_x, win_y, win_w, win_h, Gosu::Color::argb(0xaa000000), 40)

    title = @crafting_mode ? "Crafting Mode" : "Inventory"
    title_color = @crafting_mode ? Gosu::Color::CYAN : Gosu::Color::WHITE

    @font.draw_text(title, win_x + 20, win_y + 10, 41, 1.2, 1.2, title_color)

    slot_size = 48
    padding   = 12
    cols      = 6
    scale     = 48.0 / 32.0

    start_x = win_x + 20
    start_y = win_y + 60

    mouse_x, mouse_y = Input.mouse_pos(@window)

    unless @cursor_active
      @hovered_item  = nil
      @hovered_index = nil
    end

    items.each_with_index do |item, i|
      col = i % cols
      row = i / cols

      x = start_x + col * (slot_size + padding)
      y = start_y + row * (slot_size + padding)

      Gosu.draw_rect(x, y, slot_size, slot_size, Gosu::Color::GRAY, 42)

      # Mouse hover
      if !@cursor_active && mouse_x.between?(x, x + slot_size) && mouse_y.between?(y, y + slot_size)
        Gosu.draw_rect(x, y, slot_size, slot_size, Gosu::Color::argb(0x55ffffff), 43)
        @hovered_item  = item
        @hovered_index = i
      end

      # Controller highlight
      if @cursor_active && i == @cursor_index
        Gosu.draw_rect(x, y, slot_size, slot_size, Gosu::Color::argb(0x55ffff00), 46)
        @hovered_item  = item
        @hovered_index = i
      end

      # Crafting highlight
      if @crafting_mode && @selected_for_craft.include?(item)
        Gosu.draw_rect(x, y, slot_size, slot_size, Gosu::Color::argb(0x5500aaff), 44)
      end

      item.sprite&.draw(x + 4, y + 4, 45, scale, scale)
    end

    if @hovered_item
      @font.draw_text(@hovered_item.name, mouse_x + 12, mouse_y + 12, 50)
    end

    if @crafting_mode && @selected_for_craft.size >= 2
      draw_craft_button
    end
  end

  # -------------------------------------------------------------
  # Craft button (DRAW ONLY — input handled in update)
  # -------------------------------------------------------------
  def draw_craft_button
    bx = 100
    by = 380
    bw = 140
    bh = 40

    mx, my = Input.mouse_pos(@window)

    hovering = mx.between?(bx, bx + bw) && my.between?(by, by + bh)

    color = hovering ? Gosu::Color::argb(0xcc00ff00) : Gosu::Color::argb(0xaa00aa00)

    Gosu.draw_rect(bx, by, bw, bh, color, 60)
    @font.draw_text("CRAFT", bx + 20, by + 8, 61)
  end

  # -------------------------------------------------------------
  # HUD rendering
  # -------------------------------------------------------------
  def draw_hud
    return unless @font

    draw_hotbar
    draw_equipment
    draw_inventory if @player.inventory_open?

    draw_bar(20, 20, 200, 12, @player.hp / @player.max_hp.to_f, Gosu::Color::RED)
    draw_bar(20, 40, 200, 12, @player.stamina / @player.max_stamina.to_f, Gosu::Color::GREEN)

    @font.draw_text("HP: #{@player.hp.to_i}", 230, 16, 100)
    @font.draw_text("ST: #{@player.stamina.to_i}", 230, 36, 100)

    xp_ratio = @player.xp.to_f / @player.xp_to_next.to_f
    draw_bar(20, 60, 200, 12, xp_ratio, Gosu::Color::BLUE)

    @font.draw_text("LV: #{@player.level}", 230, 52, 100)
    @font.draw_text("XP: #{@player.xp}/#{@player.xp_to_next}", 230, 68, 100)

    if @player.instance_variable_get(:@stamina_buff_timer) > 0
      @font.draw_text("Stamina Boost Active", 20, 80, 100, 1.0, 1.0, Gosu::Color::CYAN)
    end

    @damage_numbers_screen.each { |n| n.draw(@font, 0, 0) }
  end

  # -------------------------------------------------------------
  # Bar helper
  # -------------------------------------------------------------
  def draw_bar(x, y, w, h, ratio, color)
    ratio = [[ratio, 0.0].max, 1.0].min
    Gosu.draw_rect(x, y, w, h, Gosu::Color::argb(0xaa_666666), 90)
    Gosu.draw_rect(x, y, w * ratio, h, color, 91)
  end
end
