class EnemySystem
  def initialize(enemies)
    @enemies = enemies
  end

  # -------------------------------------------------------------
  # Prevent enemies from stacking on top of each other
  # -------------------------------------------------------------
  def separate_enemies(physics)
    @enemies.combination(2).each do |a, b|
      next if a.dead? || b.dead?

      dx = b.x - a.x
      dy = b.y - a.y
      dist = Math.hypot(dx, dy)
      next if dist == 0

      # Optional: support variable radii
ra = a.radius
rb = b.radius

      min_dist = [ra, rb].min

      next if dist > min_dist

      overlap = min_dist - dist
      nx = dx / dist
      ny = dy / dist

      physics.move(a, -nx * overlap / 4, -ny * overlap / 4)
      physics.move(b,  nx * overlap / 4,  ny * overlap / 4)
    end
  end

  # -------------------------------------------------------------
  # Update all enemies + XP awarding
  # -------------------------------------------------------------
  def update(player, physics, ui)
    @enemies.each do |enemy|
      next if enemy.dead?
      enemy.update(player, physics, ui) if enemy.respond_to?(:update)
    end

    @enemies.each do |enemy|
      next unless enemy.dead?

      if enemy.instance_variable_get(:@just_died)
        xp = enemy.props["xp"] || enemy.instance_variable_get(:@xp_value) || 10

        player.gain_xp(xp)
        ui.add_damage_screen(300, 240, "+#{xp} XP", Gosu::Color::BLUE)

        enemy.instance_variable_set(:@just_died, false)
      end
    end

    separate_enemies(physics)
  end
end
