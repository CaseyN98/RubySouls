module Input
  DEADZONE = 0.2

  @prev_keys  = {}
  @prev_mouse = {}
  @prev_axes  = {}

  def self.update
    # no-op (edge-triggered helpers handle state)
  end

  # -------------------------------------------------------------
  # Internal helpers (edge-triggered)
  # -------------------------------------------------------------
  def self.key_pressed?(key)
    now  = Gosu.button_down?(key)
    prev = @prev_keys[key] || false
    @prev_keys[key] = now
    now && !prev
  end

  def self.mouse_pressed?(btn)
    now  = Gosu.button_down?(btn)
    prev = @prev_mouse[btn] || false
    @prev_mouse[btn] = now
    now && !prev
  end

  def self.axis_pressed?(id, threshold, positive = true)
    val = Gosu.axis(id) rescue 0.0
    now = positive ? (val > threshold) : (val < threshold)

    key = "#{id}_#{positive}"
    prev = @prev_axes[key] || false
    @prev_axes[key] = now

    now && !prev
  end
def self.register_button(id)
  @last_button = id
end

  # -------------------------------------------------------------
  # Menu Navigation (needed for Menu.rb)
  # -------------------------------------------------------------
  def self.up
    key_pressed?(Gosu::KB_UP) ||
    key_pressed?(Gosu::KB_W)  ||
    key_pressed?(Gosu::Gp0Button12) ||   # D-pad up
    axis_pressed?(Gosu::Gp0LeftStickYAxis, -0.5, false)
  end

  def self.down
    key_pressed?(Gosu::KB_DOWN) ||
    key_pressed?(Gosu::KB_S)    ||
    key_pressed?(Gosu::Gp0Button13) ||   # D-pad down
    axis_pressed?(Gosu::Gp0LeftStickYAxis, 0.5, true)
  end

  # -------------------------------------------------------------
  # RIGHT STICK — Inventory Navigation
  # -------------------------------------------------------------
  def self.inv_left?
    axis_pressed?(Gosu::Gp0RightStickXAxis, -0.5, false)
  end

  def self.inv_right?
    axis_pressed?(Gosu::Gp0RightStickXAxis, 0.5, true)
  end

  def self.inv_up?
    axis_pressed?(Gosu::Gp0RightStickYAxis, -0.5, false)
  end

  def self.inv_down?
    axis_pressed?(Gosu::Gp0RightStickYAxis, 0.5, true)
  end

  def self.any_inventory_stick?
    x = axis(Gosu::Gp0RightStickXAxis)
    y = axis(Gosu::Gp0RightStickYAxis)
    x.abs > 0.5 || y.abs > 0.5
  rescue
    false
  end

  # -------------------------------------------------------------
  # Mouse helpers
  # -------------------------------------------------------------
  def self.mouse_left_pressed?
    mouse_pressed?(Gosu::MS_LEFT)
  end

  def self.mouse_left_down?
    Gosu.button_down?(Gosu::MS_LEFT)
  end

  def self.mouse_pos(window)
    [window.mouse_x, window.mouse_y]
  end
def self.drop_pressed?
  key_pressed?(Gosu::Gp0Button1)
end


  # -------------------------------------------------------------
  # Movement (Left Stick)
  # -------------------------------------------------------------
  def self.axis(id)
    v = Gosu.axis(id) rescue 0.0
    v.abs < DEADZONE ? 0.0 : v
  end

  def self.move_x
    return 0 if $player&.inventory_open?

    stick = axis(Gosu::Gp0LeftStickXAxis)
    left  = (Gosu.button_down?(Gosu::KB_A) || Gosu.button_down?(Gosu::KB_LEFT))  ? -1 : 0
    right = (Gosu.button_down?(Gosu::KB_D) || Gosu.button_down?(Gosu::KB_RIGHT)) ?  1 : 0
    stick != 0 ? stick : (left + right)
  end

  def self.move_y
    return 0 if $player&.inventory_open?

    stick = axis(Gosu::Gp0LeftStickYAxis)
    up    = (Gosu.button_down?(Gosu::KB_W) || Gosu.button_down?(Gosu::KB_UP))    ? -1 : 0
    down  = (Gosu.button_down?(Gosu::KB_S) || Gosu.button_down?(Gosu::KB_DOWN))  ?  1 : 0
    stick != 0 ? stick : (up + down)
  end

  # -------------------------------------------------------------
  # Combat
  # -------------------------------------------------------------
  def self.attack_pressed?
    key_pressed?(Gosu::KB_SPACE) ||
    key_pressed?(Gosu::Gp0Button0)
  end

  def self.roll_pressed?
    key_pressed?(Gosu::KB_K) ||
    key_pressed?(Gosu::KB_LEFT_SHIFT) ||
    key_pressed?(Gosu::Gp0Button1)
  end

  # -------------------------------------------------------------
  # World Interaction + Item Use
  # -------------------------------------------------------------
  def self.interact_pressed?
    key_pressed?(Gosu::KB_E) ||
    key_pressed?(Gosu::Gp0Button3)
  end

  # -------------------------------------------------------------
  # UI Confirm (menus, hotbar use)
  # -------------------------------------------------------------
  def self.ui_confirm_pressed?
    key_pressed?(Gosu::KB_E) ||
    key_pressed?(Gosu::Gp0Button0)
  end

  # -------------------------------------------------------------
  # Crafting Confirm
  # -------------------------------------------------------------
  def self.craft_confirm?
    key_pressed?(Gosu::KB_ENTER) ||
    key_pressed?(Gosu::KB_RETURN) ||
    key_pressed?(Gosu::Gp0Button8)
  end

  def self.craft_confirm_down?
    Gosu.button_down?(Gosu::KB_RETURN) ||
    Gosu.button_down?(Gosu::KB_ENTER)  ||
    Gosu.button_down?(Gosu::Gp0Button8)
  end

  # -------------------------------------------------------------
  # Hotbar Cycling
  # -------------------------------------------------------------
  def self.hotbar_next?
    key_pressed?(Gosu::KB_Q) ||
    key_pressed?(Gosu::Gp0Button10)
  end

  def self.hotbar_prev?
    key_pressed?(Gosu::KB_Z) ||
    key_pressed?(Gosu::Gp0Button9)
  end

  # -------------------------------------------------------------
  # Inventory Toggle
  # -------------------------------------------------------------
  def self.inventory_toggle?
    key_pressed?(Gosu::KB_I) ||
    key_pressed?(Gosu::KB_TAB) ||
    key_pressed?(Gosu::Gp0Button4)
  end

  # -------------------------------------------------------------
  # Crafting Toggle
  # -------------------------------------------------------------
  def self.craft_toggle?
    key_pressed?(Gosu::KB_C) ||
    key_pressed?(Gosu::Gp0Button7)
  end
  def self.clear
  @prev_keys.clear
  @prev_mouse.clear
  @prev_axes.clear
  @last_button = nil
end

end
