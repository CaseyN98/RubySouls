class Combat
  def update(player, enemies, map, ui)
    enemies.each do |enemy|
      next if enemy.dead?

      # -------------------------------------------------------------
      # PLAYER → ENEMY DAMAGE
      # -------------------------------------------------------------
      if player.hit_frame? && !player.attack_hit_applied
        if in_attack_range?(player, enemy)

          damage = player.attack_power
          enemy.hit(damage)

          ui.add_damage_world(enemy.x, enemy.y, damage, Gosu::Color::YELLOW)

          # Track kills for graveyard
          if enemy.dead?
            player.kills += 1
            enemy.instance_variable_set(:@just_died, true)
          end

          player.mark_attack_hit
        end
      end

      # -------------------------------------------------------------
      # ENEMY → PLAYER DAMAGE
      # -------------------------------------------------------------
      if enemy.respond_to?(:attack_frame?) && enemy.attack_frame?
        if enemy.respond_to?(:can_attack_player?) && enemy.can_attack_player?(player)
          damage = enemy.attack_power
          apply_player_damage(player, ui, damage, enemy)
        end
      end
    end
  end

  # -------------------------------------------------------------
  # PLAYER DAMAGE POPUP (RED)
  # -------------------------------------------------------------
  def apply_player_damage(player, ui, damage, enemy=nil)
    player.hit(damage, enemy)
    ui.add_damage_world(player.x, player.y, damage, Gosu::Color::RED)
  end

  # -------------------------------------------------------------
  # ATTACK RANGE CHECK
  # -------------------------------------------------------------
  def in_attack_range?(player, enemy)
    dx = enemy.x - player.x
    dy = enemy.y - player.y

    distance = Math.hypot(dx, dy)
    return false if distance > 20

    angle = Math.atan2(dy, dx)

    facing_angle =
      case player.direction
      when :right then 0
      when :down  then Math::PI / 2
      when :left  then Math::PI
      when :up    then -Math::PI / 2
      end

    diff = (angle - facing_angle).abs
    diff = 2 * Math::PI - diff if diff > Math::PI

    diff < Math::PI / 3
  end

  # -------------------------------------------------------------
  # DRAW (reserved for future VFX)
  # -------------------------------------------------------------
  def draw(cam_x, cam_y)
    # reserved for melee effects later
  end
end
