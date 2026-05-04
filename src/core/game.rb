require "gosu"
require "json"

require_relative "map"
require_relative "../entities/player"
require_relative "../entities/enemy"
require_relative "../ui/camera"
require_relative "../ui/menu"
require_relative "../entities/projectile"
require_relative "../ui/ui"

require_relative "../entities/item"
require_relative "../entities/item_db"
require_relative "../entities/item_pickup"
require_relative "../ui/inventory"
require_relative "../entities/chest"
require_relative "../entities/key_pickup"
require_relative "../entities/door"

require_relative "../systems/input"
require_relative "../systems/physics"
require_relative "../systems/combat"
require_relative "../systems/enemy"
require_relative "../systems/crafting"

$crafting_system = CraftingSystem.new

class Game < Gosu::Window
  WIDTH  = 1280
  HEIGHT = 720
  SCALE  = 4

  attr_reader :projectiles, :ui

  LEVEL_ORDER = [
    "assets/maps/test.json",
    "assets/maps/level2.json",
    "assets/maps/level3.json"
  ]

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ruby Souls"

    @projectiles = []
    @state = :menu
    @input = Input
	@menu = Menu.new(self)
    @current_level = 0
    
  end
def start_game
  @state = :playing
  @current_level = 0
  load_level(LEVEL_ORDER[@current_level])
end

  # -------------------------------------------------------------
  # LOAD LEVEL
  # -------------------------------------------------------------
  def load_level(path)
    @map = Map.new(path)
    @doors = @map.door_instances
    @physics = Physics.new(@map, @doors)
    @combat  = Combat.new

    # Player spawn
    spawn = @map.objects.find { |o| o[:name] == "player" } || { x: 100, y: 100 }

    if @player
      @player.x = spawn[:x]
      @player.y = spawn[:y]
    else
      @player = Player.new(spawn[:x], spawn[:y])
    end

    # Global reference for Input.move_x/move_y
    $player = @player

   @camera = Camera.new(@player, WIDTH / SCALE, HEIGHT / SCALE)
@camera.set_map(@map)

    @ui     = UI.new(self, @player)

    # Enemies
    @enemies = @map.objects
                   .select { |o| o[:type] == "enemy" }
                   .map do |o|
      hp   = o[:props]["hp"]   || 20
      kind = o[:props]["kind"] || "default"
      Enemy.new(o[:x], o[:y], hp, type: kind, props: o[:props])
    end

    @enemy_system = EnemySystem.new(@enemies)

    # Item pickups
    @pickups = @map.objects
                   .select { |o| o[:type] == "item" }
                   .map do |o|
      kind = o[:props]["kind"]
      next unless kind && ITEM_DB[kind]
      ItemPickup.new(o[:x], o[:y], kind)
    end.compact

    # Keys
    @keys = @map.objects
                .select { |o| o[:type] == "key" }
                .map { |o| KeyPickup.new(o[:x], o[:y], o[:props]["key_id"]) }

    # Chests
    @chests = @map.objects
                  .select { |o| o[:type] == "chest" }
                  .map { |o| Chest.new(o[:x], o[:y], o[:props]) }
  end

  # -------------------------------------------------------------
  # NEXT LEVEL
  # -------------------------------------------------------------
  def next_level
    @current_level += 1
    return if @current_level >= LEVEL_ORDER.size
    load_level(LEVEL_ORDER[@current_level])
  end

  # -------------------------------------------------------------
  # UPDATE LOOP
  # -------------------------------------------------------------
def update
  Input.update

  case @state
  when :menu
    @menu.update
    return

  when :dead
    return

  when :playing
    # normal gameplay update
    @player.update(@input, @physics, self)

    if @player.hp <= 0
      @state = :dead
      return
    end

    @enemy_system.update(@player, @physics, @ui)
    @combat.update(@player, @enemies, @map, @ui)

    @projectiles.each { |p| p.update(@map, @enemies, @ui) }
    @projectiles.reject!(&:dead)

    @pickups.each { |p| p.update(@player) }
    @pickups.reject!(&:dead)

    @keys.each { |k| k.update(@player) }
    @keys.reject!(&:dead)

    @chests.each { |c| c.update(@player, @ui) }
    @doors.each  { |d| d.update(@player, @map) }

    @player.update_hotbar(@input, self)

    @camera.update
    @ui.update
  end
end


  # -------------------------------------------------------------
  # DEATH SCREEN
  # -------------------------------------------------------------
  def draw_death_screen
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, Gosu::Color.argb(0xaa000000), 200)

    font = Gosu::Font.new(80, name: "Courier")
    text = "YOU DIED (press any key to restart)"

    w = font.text_width(text)
    font.draw_text(text, (WIDTH - w) / 2, HEIGHT / 2 - 40, 201, 1, 1, Gosu::Color::RED)
  end

def button_down(id)
  if @state == :menu
    # Let Input system handle it
    Input.register_button(id)
    return
  end

  if @state == :dead
    restart_game
    return
  end

  super if defined?(super)
end


  def restart_game
    initialize
  end

  # -------------------------------------------------------------
  # DRAW LOOP
  # -------------------------------------------------------------
def draw
  case @state
  when :menu
    @menu.draw
    return

  when :dead
    draw_death_screen
    return
  end

  # PLAYING
  Gosu.scale(SCALE, SCALE) do
    @map.draw(@camera.x, @camera.y, WIDTH, HEIGHT)
    @player.draw(@camera.x, @camera.y)
    @enemies.each { |e| e.draw(@camera.x, @camera.y) }
    @pickups.each { |p| p.draw(@camera.x, @camera.y) }
    @keys.each    { |k| k.draw(@camera.x, @camera.y) }
    @chests.each  { |c| c.draw(@camera.x, @camera.y) }
    @doors.each   { |d| d.draw(@camera.x, @camera.y) }
    @combat.draw(@camera.x, @camera.y)
    @projectiles.each { |p| p.draw(@camera.x, @camera.y) }
    @ui.draw_world(@camera.x, @camera.y)
  end

  @ui.draw_hud
end

end
