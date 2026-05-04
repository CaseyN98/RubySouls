class LevelWarpItem < Item
  def use(player, game)
    game.next_level
  end
end
