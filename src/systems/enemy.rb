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
      next if dist == 0 || dist > 16  # enemy radius

      overlap = 16 - dist
      nx = dx / dist
      ny = dy / dist

      # Use physics to avoid clipping walls
      physics.move(a, -nx * overlap / 4, -ny * overlap / 4)
      physics.move(b,  nx * overlap / 4,  ny * overlap / 4)
    end
  end

  # -------------------------------------------------------------
  # Update all enemies + XP awarding
  # -------------------------------------------------------------
  def update(player, physics, ui)
    # Update AI + movement
    @enemies.each do |enemy|
      next if enemy.dead?
      enemy.update(player, physics, ui)
    end

    # Award XP for newly dead enemies
    @enemies.each do |enemy|
      next unless enemy.dead?

      if enemy.instance_variable_get(:@just_died)
        xp = enemy.instance_variable_get(:@xp_value) || 10

        player.gain_xp(xp)
        ui.add_damage_screen(300, 240, "+#{xp} XP", Gosu::Color::BLUE)

        enemy.instance_variable_set(:@just_died, false)
      end
    end

    # Handle enemy separation after movement
    separate_enemies(physics)
  end
end
