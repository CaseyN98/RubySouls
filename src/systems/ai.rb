class AI
  def initialize; end

  def update_enemy(enemy, player, collision)
    return if enemy.dead?

    # Reduce aggro timer if counting down
    enemy.aggro_timer -= 1 if enemy.aggro_timer > 0

    case enemy.state
    when :idle
      handle_idle(enemy, player)
    when :chase
      chase(enemy, player, collision)
      enemy.start_attack if distance(enemy, player) < enemy.attack_range
    when :attack
      enemy.update_attack
    when :stunned
      enemy.update_stun
    end
  end

  # -------------------------------------------------------------
  # IDLE → CHASE transition with staggered aggro
  # -------------------------------------------------------------
  def handle_idle(enemy, player)
    dist = distance(enemy, player)

    # Player not close enough
    return if dist > enemy.aggro_range

    # Enemy is close enough, but must wait for its personal delay
    if enemy.aggro_timer <= 0
      enemy.state = :chase
    end
  end

  # -------------------------------------------------------------
  # Chase behavior
  # -------------------------------------------------------------
  def chase(enemy, player, collision)
    angle = Math.atan2(player.y - enemy.y, player.x - enemy.x)
    vx = Math.cos(angle) * enemy.speed
    vy = Math.sin(angle) * enemy.speed
    collision.move(enemy, vx, vy)
  end

  def distance(a, b)
    Math.hypot(a.x - b.x, a.y - b.y)
  end
end
