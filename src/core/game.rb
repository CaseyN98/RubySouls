require "gosu"
require "json"

require_relative "map"
require_relative "../entities/player"
require_relative "../entities/enemy"
require_relative "../ui/camera"
require_relative "../ui/menu"
require_relative "../entities/projectile"
require_relative "../ui/ui"
require_relative "../ui/crafting_recipe_viewer"
require_relative "../ui/graveyard"
require_relative "../ui/graveyard_viewer"

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

require_relative "../rogue/rogue_floor"
require_relative "../rogue/rogue_map"

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

    @open_portal_img   = Gosu::Image.new("assets/objects/open_portal.png", retro: true)
    @closed_portal_img = Gosu::Image.new("assets/objects/closed_portal.png", retro: true)

    @graveyard = Graveyard.new

    @projectiles   = []
    @state         = :menu
    @rogue_mode    = false

    @input         = Input
    @menu          = Menu.new(self)
    @current_level = 0
    @current_floor = 1

    @map     = nil
    @doors   = []
    @keys    = []
    @pickups = []
    @chests  = []
    @enemies = []
    @boss_dead = false
  end

  # -------------------------------------------------------------
  # START GAME (NORMAL)
  # -------------------------------------------------------------
  def start_game
    @rogue_mode    = false
    @state         = :playing
    @current_level = 0
    load_level(LEVEL_ORDER[@current_level])
  end

  # -------------------------------------------------------------
  # START ROGUE MODE
  # -------------------------------------------------------------
  def start_rogue_mode
    @rogue_mode    = true
    @state         = :playing
    @current_floor = 1
    load_rogue_floor
  end

  def load_rogue_floor
    floor = RogueFloor.new(@current_floor)

    @map     = floor.map
    @doors   = []
    @keys    = []
    @pickups = []

    @chests = floor.chests.map { |c| Chest.new(c[:x], c[:y], c[:props]) }

    @enemies = floor.enemies.map do |e|
      Enemy.new(e[:x], e[:y], e[:props]["hp"], type: e[:type], props: e[:props])
    end

    boss = floor.boss
    @boss = Enemy.new(
      boss[:x],
      boss[:y],
      boss[:props]["hp"],
      type: boss[:type],
      props: boss[:props]
    )
    @enemies << @boss

    @exit = floor.exit_tile
    @boss_dead = false

    if @player
      @player.x = @map.spawn_point[:x]
      @player.y = @map.spawn_point[:y]
    else
      @player = Player.new(@map.spawn_point[:x], @map.spawn_point[:y])
    end

    $player = @player

    @physics = Physics.new(@map, [])
    @combat  = Combat.new

    @camera = Camera.new(@player, WIDTH / SCALE, HEIGHT / SCALE)
    @camera.set_map(@map)

    @ui = UI.new(self, @player)

    @enemy_system = EnemySystem.new(@enemies)
  end

  # -------------------------------------------------------------
  # GRAVEYARD VIEW
  # -------------------------------------------------------------
  def open_graveyard
    @graveyard_viewer = GraveyardViewer.new(self, @graveyard)
    @state = :graveyard
  end

  # -------------------------------------------------------------
  # LOAD LEVEL (NORMAL MODE)
  # -------------------------------------------------------------
  def load_level(path)
    @map    = Map.new(path)
    @doors  = @map.door_instances
    @physics = Physics.new(@map, @doors)
    @combat  = Combat.new

    spawn = @map.objects.find { |o| o[:name] == "player" } || { x: 100, y: 100 }

    if @player
      @player.x = spawn[:x]
      @player.y = spawn[:y]
    else
      @player = Player.new(spawn[:x], spawn[:y])
    end

    $player = @player

    @camera = Camera.new(@player, WIDTH / SCALE, HEIGHT / SCALE)
    @camera.set_map(@map)

    @ui = UI.new(self, @player)

    @enemies = @map.objects
                   .select { |o| o[:type] == "enemy" }
                   .map do |o|
      hp   = o[:props]["hp"]   || 20
      kind = o[:props]["kind"] || "default"
      Enemy.new(o[:x], o[:y], hp, type: kind, props: o[:props])
    end

    @enemy_system = EnemySystem.new(@enemies)

    @pickups = @map.objects
                   .select { |o| o[:type] == "item" }
                   .map do |o|
      kind = o[:props]["kind"]
      next unless kind && ITEM_DB[kind]
      ItemPickup.new(o[:x], o[:y], kind)
    end.compact

    @keys = @map.objects
                .select { |o| o[:type] == "key" }
                .map { |o| KeyPickup.new(o[:x], o[:y], o[:props]["key_id"]) }

    @chests = @map.objects
                  .select { |o| o[:type] == "chest" }
                  .map { |o| Chest.new(o[:x], o[:y], o[:props]) }
  end

  # -------------------------------------------------------------
  # NEXT LEVEL (NORMAL)
  # -------------------------------------------------------------
  def next_level
    @current_level += 1
    return if @current_level >= LEVEL_ORDER.size
    load_level(LEVEL_ORDER[@current_level])
  end

  # -------------------------------------------------------------
  # MENU → CRAFTING VIEWER
  # -------------------------------------------------------------
  def open_crafting_recipes
    @crafting_viewer = CraftingRecipeViewer.new(self)
    @state = :crafting_viewer
  end

  def return_to_menu
    @state = :menu
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

    when :graveyard
      @graveyard_viewer.update
      return

    when :crafting_viewer
      @crafting_viewer.update
      return

    when :dead
      return

    when :playing
      if @rogue_mode
        update_rogue_mode
      else
        update_normal_mode
      end
    end
  end

  def update_normal_mode
    @player.update(@input, @physics, self)

    if @player.hp <= 0
      log_death("Killed by #{@player.last_hit_by || 'Unknown'}")
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

  def update_rogue_mode
    @player.update(@input, @physics, self)

    if @player.hp <= 0
      log_death("Killed by #{@player.last_hit_by || 'Unknown'}")
      @state = :dead
      return
    end

    @enemy_system.update(@player, @physics, @ui)
    @combat.update(@player, @enemies, @map, @ui)

    @boss_dead = @boss && @boss.dead?

    @projectiles.each { |p| p.update(@map, @enemies, @ui) }
    @projectiles.reject!(&:dead)

    @chests.each { |c| c.update(@player, @ui) }

    if @boss_dead && touching_exit?(@player, @exit)
      @current_floor += 1
      load_rogue_floor
      return
    end

    @player.update_hotbar(@input, self)

    @camera.update
    @ui.update
  end

  def touching_exit?(player, exit)
    return false unless exit
    px = player.x
    py = player.y
    ex = exit[:x]
    ey = exit[:y]
    ew = exit[:width]
    eh = exit[:height]

    px.between?(ex, ex + ew) && py.between?(ey, ey + eh)
  end

  # -------------------------------------------------------------
  # GRAVEYARD LOGGING
  # -------------------------------------------------------------
  def log_death(cause)
    entry = {
      name:  "Player",
      floor: @rogue_mode ? @current_floor : @current_level + 1,
      kills: @player.kills,
      time:  format_time(@player.play_time),
      cause: cause
    }

    @graveyard.add(entry)
  end

  def format_time(seconds)
    m = (seconds / 60).to_i
    s = (seconds % 60).to_i
    "#{m}m #{s}s"
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

  # -------------------------------------------------------------
  # INPUT HANDLING
  # -------------------------------------------------------------
  def button_down(id)
    if @state == :menu
      Input.register_button(id)
      return
    end

    if @state == :crafting_viewer
      if id == Gosu::KB_E || id == Gosu::GP_BUTTON_0
        return_to_menu
      end
      return
    end

    if @state == :graveyard
      if id == Gosu::KB_E || id == Gosu::GP_BUTTON_0
        return_to_menu
      end
      return
    end

    if @state == :dead
      restart_game
      return
    end

    super if defined?(super)
  end

def restart_game
  Input.clear
  initialize
  @player = nil
  @state = :menu
end
def rogue_mode?
  @rogue_mode
end


  # -------------------------------------------------------------
  # DRAW LOOP
  # -------------------------------------------------------------
  def draw
    case @state
    when :menu
      @menu.draw
      return

    when :graveyard
      @graveyard_viewer.draw
      return

    when :crafting_viewer
      @crafting_viewer.draw
      return

    when :dead
      draw_death_screen
      return
    end

    Gosu.scale(SCALE, SCALE) do
      @map.draw(@camera.x, @camera.y, WIDTH, HEIGHT)
      @player.draw(@camera.x, @camera.y)
      @enemies.each { |e| e.draw(@camera.x, @camera.y) }
      @pickups.each { |p| p.draw(@camera.x, @camera.y) }

      unless @rogue_mode
        @keys.each   { |k| k.draw(@camera.x, @camera.y) }
        @doors.each  { |d| d.draw(@camera.x, @camera.y) }
      end

      @chests.each  { |c| c.draw(@camera.x, @camera.y) }
      @combat.draw(@camera.x, @camera.y)
      @projectiles.each { |p| p.draw(@camera.x, @camera.y) }

      if @rogue_mode && @exit
        img = @boss_dead ? @open_portal_img : @closed_portal_img
        img.draw(@exit[:x] - @camera.x, @exit[:y] - @camera.y, 5)
      end

      @ui.draw_world(@camera.x, @camera.y)
    end

    @ui.draw_hud
    @ui.draw_rogue_floor(@current_floor) if @rogue_mode
  end
end
