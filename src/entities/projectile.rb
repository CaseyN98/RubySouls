class Projectile
  attr_accessor :x, :y, :dead
  attr_reader :radius, :damage

  SPEED = 7.0
  MAX_LIFETIME = 120

def initialize(x, y, angle, damage:, owner:)
  @x, @y = x, y
  @angle = angle
  @vx = Math.cos(angle) * SPEED
  @vy = Math.sin(angle) * SPEED
  @radius = 4
  @damage = damage
  @owner = owner
  @dead = false
  @lifetime = MAX_LIFETIME
end


  def update(map, enemies, ui)
    @x += @vx
    @y += @vy

    if map.solid?(@x, @y)
      @dead = true
      return
    end

    enemies.each do |enemy|
      next if enemy.dead?
      if Gosu.distance(@x, @y, enemy.x, enemy.y) < enemy.radius + @radius
        enemy.hit(@damage, @owner, ui)
        ui.add_damage_world(enemy.x, enemy.y, @damage, Gosu::Color::CYAN)
        @dead = true
        return
      end
    end
  end

def draw(cam_x, cam_y)
  @sprite ||= Gosu::Image.new("assets/items/arrow.png", retro: true)
angle_deg = (@angle * 180 / Math::PI)
@sprite.draw_rot(@x - cam_x, @y - cam_y, 15, angle_deg)

end

end
