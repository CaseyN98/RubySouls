class Player
  attr_reader :inventory
  attr_reader :level, :xp, :xp_to_next

  SPEED        = 1.5
  STAMINA_MAX  = 100
  ANIM_SPEED   = 10

  ROLL_COST      = 20
  ROLL_SPEED     = 4.0
  ROLL_DURATION  = 12
  BOW_STAMINA_COST = 15

  ATTACK_STAMINA_COST = 25
  SCROLL_COOLDOWN = 150

  attr_accessor :x, :y, :direction
  attr_reader :hp, :stamina, :state, :frame
  attr_accessor :attack_hit_applied
  attr_accessor :kills, :play_time, :last_hit_by


  HIT_FRAME = 2

  # -------------------------------------------------------------
  # Animation loader
  # -------------------------------------------------------------
  def load_animation(path, frame_count)
    return nil unless File.exist?(path)
    img = Gosu::Image.new(path, retro: true)
    frame_w = img.width / frame_count
    frame_h = img.height
    frames = []
    frame_count.times { |i| frames << img.subimage(i * frame_w, 0, frame_w, frame_h) }
    frames
  rescue
    nil
  end

  # -------------------------------------------------------------
  # Initialization
  # -------------------------------------------------------------
  def initialize(x, y)
    @x, @y = x, y
    @inventory_open = false

    @inventory = Inventory.new

    @direction = :down
    @state = :idle

    @level = 1
    @xp = 0
    @xp_to_next = 100

    @base_attack  = 10
    @base_defense = 5

    @hp = max_hp
    @stamina = max_stamina
	@kills       = 0
	@play_time   = 0.0
	@last_hit_by = nil


    @stamina_regen_multiplier = 1.0
    @stamina_buff_timer = 0

    @frame = 0
    @last_frame_time = Gosu.milliseconds

    @roll_timer = 0
    @invulnerable = false

    @attack_hit_applied = false
    @last_scroll_time = 0

    @animations = {}
    [:idle, :walk, :atk, :roll].each do |state|
      @animations[state] = {}
      [:up, :down, :left, :right].each do |dir|
        path = "assets/sprites/player/Char1_#{state}_#{dir}.png"
        @animations[state][dir] = load_animation(path, 6)
      end
    end
  end

  def inventory_open?
    @inventory_open
  end

  # -------------------------------------------------------------
  # XP + LEVELING
  # -------------------------------------------------------------
  def gain_xp(amount)
    @xp += amount
    check_level_up
  end

  def check_level_up
    while @xp >= @xp_to_next
      @xp -= @xp_to_next
      level_up
    end
  end

  def level_up
    @level += 1
    @hp = max_hp
    @stamina = max_stamina

    @base_attack  += 2
    @base_defense += 1

    @xp_to_next = (100 * (@level ** 1.5)).to_i
    puts "LEVEL UP! You are now level #{@level}"
  end

  # -------------------------------------------------------------
  # Equipment + stats
  # -------------------------------------------------------------
  def equipped_weapon
    @inventory.equipped_weapon
  end

  def attack_power
    weapon_bonus = equipped_weapon ? (equipped_weapon.props[:atk] || 0) : 0
    @base_attack + weapon_bonus
  end

  def defense_power
    armor = @inventory.respond_to?(:equipped_armor) ? @inventory.equipped_armor : nil
    armor_bonus = armor ? (armor.props[:def] || 0) : 0
    @base_defense + armor_bonus
  end

  def max_hp
    100 + (@level * 20)
  end

  def max_stamina
    STAMINA_MAX + (@level * 10)
  end

  # -------------------------------------------------------------
  # Update
  # -------------------------------------------------------------
def update(input, collision, game)
  @play_time += 1.0 / 60.0
  handle_hotbar_scroll(input)

    if input.inventory_toggle?
      @inventory_open = !@inventory_open
    end

    update_state_and_direction(input, game)

    if @state == :walk || @state == :roll
      collision.move(self, @vx, @vy)
    end

    update_animation
    regen_stamina
  end

  # -------------------------------------------------------------
  # HOTBAR (UI confirm = use item)
  # -------------------------------------------------------------
  def update_hotbar(input, game)
    use_hotbar_item(game) if input.ui_confirm_pressed?
  end

  def handle_hotbar_scroll(input)
    now = Gosu.milliseconds
    return if now - @last_scroll_time < SCROLL_COOLDOWN

    if input.hotbar_next?
      @inventory.select_next
      @last_scroll_time = now
    elsif input.hotbar_prev?
      @inventory.select_prev
      @last_scroll_time = now
    end
  end

  # -------------------------------------------------------------
  # HOTBAR USAGE
  # -------------------------------------------------------------
  def use_hotbar_item(game = nil)
    item = @inventory.selected_item
    return unless item

    case item.kind
    when "consumable"
      if item.props[:heal]
        @hp = [@hp + item.props[:heal], max_hp].min
      end

      if item.props[:stamina_buff]
        @stamina_regen_multiplier = item.props[:multiplier] || 2.0
        @stamina_buff_timer = item.props[:duration] || 300
      end

      @inventory.remove(item)
      @inventory.assign_to_hotbar(@inventory.selected_index, nil)

    when "weapon", "bow"
      @inventory.equip_weapon(item)

    when "level_warp"
      game.next_level if game
      @inventory.remove(item)
      @inventory.assign_to_hotbar(@inventory.selected_index, nil)
    end
  end

  # -------------------------------------------------------------
  # Pickup
  # -------------------------------------------------------------
  def pickup(item)
    if (item.kind == "weapon" || item.kind == "bow") && @inventory.equipped_weapon.nil?
      @inventory.equip_weapon(item)
      return
    end

    @inventory.add(item)

    @inventory.hotbar.slots.each_with_index do |slot, i|
      if slot.nil?
        @inventory.assign_to_hotbar(i, item)
        break
      end
    end
  end

  # -------------------------------------------------------------
  # Combat
  # -------------------------------------------------------------
def hit(dmg, source=nil)
  return if @invulnerable
  @hp = [@hp - dmg, 0].max
  @last_hit_by = source.type if source && source.respond_to?(:type)
end


  def hit_frame?
    @state == :atk && @frame == HIT_FRAME
  end

  # -------------------------------------------------------------
  # Movement + state
  # -------------------------------------------------------------
  def update_state_and_direction(input, game)
    # ROLLING
    if @state == :roll
      @roll_timer -= 1

      case @direction
      when :up    then @vy = -ROLL_SPEED
      when :down  then @vy =  ROLL_SPEED
      when :left  then @vx = -ROLL_SPEED
      when :right then @vx =  ROLL_SPEED
      end

      if @roll_timer <= 0
        @state = :idle
        @invulnerable = false
      end

      return
    end

    # START ROLL
    if input.roll_pressed? && @stamina >= ROLL_COST
      @state = :roll
      @stamina -= ROLL_COST
      @roll_timer = ROLL_DURATION
      @invulnerable = true
      @vx = @vy = 0
      return
    end

    # ATTACK
    if input.attack_pressed?
      if equipped_weapon && equipped_weapon.kind == "bow"
        if @stamina >= BOW_STAMINA_COST
          @stamina -= BOW_STAMINA_COST
          fire_projectile(game)
          @state = :walk
        end
        return
      end

      if @stamina >= ATTACK_STAMINA_COST && @state != :atk
        @state = :atk
        @frame = 0
        @attack_hit_applied = false
        @stamina -= ATTACK_STAMINA_COST
        @vx = @vy = 0
        return
      end
    end

    # Attack freeze frames
    if @state == :atk && @frame < 5
      @vx = @vy = 0
      return
    end

    # MOVEMENT
    @vx = input.move_x * SPEED
    @vy = input.move_y * SPEED

    if @vx != 0 || @vy != 0
      @state = :walk
      if @vx.abs > @vy.abs
        @direction = @vx > 0 ? :right : :left
      else
        @direction = @vy > 0 ? :down : :up
      end
    else
      @state = :idle
    end
  end

  # -------------------------------------------------------------
  # Projectile
  # -------------------------------------------------------------
  def fire_projectile(game)
    bow = equipped_weapon
    return unless bow && bow.kind == "bow"

    angle =
      case @direction
      when :right then 0
      when :down  then Math::PI / 2
      when :left  then Math::PI
      when :up    then -Math::PI / 2
      end

    dmg = bow.props[:atk] || 5

    game.projectiles << Projectile.new(@x, @y, angle, damage: dmg, owner: self)

    if bow.props[:durability]
      bow.props[:durability] -= 1
      if bow.props[:durability] <= 0
        @inventory.unequip_weapon
        game.ui.add_damage_screen(300, 200, "Bow broke!", Gosu::Color::RED)
      end
    end
  end

  # -------------------------------------------------------------
  # Animation
  # -------------------------------------------------------------
  def update_animation
    if Gosu.milliseconds - @last_frame_time > 100
      @frame = (@frame + 1) % 6
      @last_frame_time = Gosu.milliseconds
    end
  end
def mark_attack_hit
  @attack_hit_applied = true
end

  # -------------------------------------------------------------
  # Regen
  # -------------------------------------------------------------
  def regen_stamina
    regen = 0.2 * @stamina_regen_multiplier
    @stamina = [@stamina + regen, max_stamina].min

    if @stamina_buff_timer > 0
      @stamina_buff_timer -= 1
      @stamina_regen_multiplier = 1.0 if @stamina_buff_timer <= 0
    end
  end

  # -------------------------------------------------------------
  # Draw
  # -------------------------------------------------------------
  def draw(cam_x, cam_y)
    anim_set = @animations[@state][@direction]

    screen_x = (@x - cam_x).to_i - 8
    screen_y = (@y - cam_y).to_i - 8

    if anim_set && anim_set[@frame]
      anim_set[@frame].draw(screen_x, screen_y, 10)
    else
      Gosu.draw_rect(screen_x, screen_y, 16, 16, Gosu::Color::WHITE, 10)
    end
  end
end
