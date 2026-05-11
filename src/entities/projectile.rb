class Projectile
  attr_accessor :x, :y, :dead
  attr_reader :radius, :damage, :element

  SPEED = 7.0
  MAX_LIFETIME = 120

  def initialize(x, y, angle, damage:, owner:, element: nil)
    @x, @y = x, y
    @angle = angle
    @vx = Math.cos(angle) * SPEED
    @vy = Math.sin(angle) * SPEED
    @radius = 4
    @damage = damage
    @owner = owner
    @element = element   # :fire, :water, or nil
    @dead = false
    @lifetime = MAX_LIFETIME
  end

  # -------------------------------------------------------------
  # UPDATE
  # -------------------------------------------------------------
  def update(map, enemies, ui)
    @x += @vx
    @y += @vy

    # Wall collision
    if map.solid?(@x, @y)
      @dead = true
      return
    end

    # Enemy collision
    enemies.each do |enemy|
      next if enemy.dead?

      if Gosu.distance(@x, @y, enemy.x, enemy.y) < enemy.radius + @radius
        apply_hit_effects(enemy, ui)
        @dead = true
        return
      end
    end

    # Lifetime expiration
    @lifetime -= 1
    @dead = true if @lifetime <= 0
  end

  # -------------------------------------------------------------
  # ELEMENTAL HIT EFFECTS
  # -------------------------------------------------------------
  def apply_hit_effects(enemy, ui)
    enemy.hit(@damage, @owner, ui)

    case @element
    when :fire
      # Burn effect hook (optional)
      # enemy.apply_burn(3, 30)
      ui.add_damage_world(enemy.x, enemy.y, @damage, Gosu::Color::RED)

    when :water
      # Slow effect hook (optional)
      # enemy.apply_slow(0.5, 60)
      ui.add_damage_world(enemy.x, enemy.y, @damage, Gosu::Color::CYAN)

    else
      ui.add_damage_world(enemy.x, enemy.y, @damage, Gosu::Color::WHITE)
    end
  end

  # -------------------------------------------------------------
  # SPRITE SELECTION
  # -------------------------------------------------------------
  def sprite
    @sprite ||= begin
      case @element
      when :fire
        Gosu::Image.new("assets/items/fire_orb.png", retro: true)
      when :water
        Gosu::Image.new("assets/items/water_orb.png", retro: true)
      else
        Gosu::Image.new("assets/items/arrow.png", retro: true)
      end
    end
  end

  # -------------------------------------------------------------
  # DRAW
  # -------------------------------------------------------------
  def draw(cam_x, cam_y)
    angle_deg = (@angle * 180 / Math::PI)
    sprite.draw_rot(@x - cam_x, @y - cam_y, 15, angle_deg)
  end
end
