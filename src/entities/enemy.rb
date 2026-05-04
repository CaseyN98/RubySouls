class Enemy
  attr_accessor :x, :y, :aggro_timer
  attr_reader :hp, :dead, :attack_power, :defense_power, :aggro_range, :name, :radius


  # -------------------------------------------------------------
  # Animation definitions per enemy type
  # -------------------------------------------------------------
  ENEMY_TYPES = {
    "default" => {
      states: [:idle, :walk, :atk],
      dirs:   [:up, :down, :left, :right],
      frames: { idle: 6, walk: 6, atk: 6 },
      folder: "enemy"
    },
	 "skeleton" => {
      states: [:idle, :walk, :atk],
      dirs:   [:up, :down, :left, :right],
      frames: { idle: 6, walk: 6, atk: 6 },
      folder: "skeleton"
    },
	"Bskeleton" => {
      states: [:idle, :walk, :atk],
      dirs:   [:up, :down, :left, :right],
      frames: { idle: 6, walk: 6, atk: 6 },
      folder: "Bskeleton"
    },

    "slime" => {
      states: [:idle, :walk, :atk],
      dirs:   [:up, :down, :left, :right],
      frames: { idle: 6, walk: 6, atk: 6 },
      folder: "slime"
    }
  }

  # -------------------------------------------------------------
  # Load animation with variable frame count
  # -------------------------------------------------------------
  def load_animation(path, frame_count)
    img = Gosu::Image.new(path, retro: true)
    frame_w = img.width / frame_count
    frame_h = img.height

    Array.new(frame_count) do |i|
      img.subimage(i * frame_w, 0, frame_w, frame_h)
    end
  rescue
    nil
  end

  # -------------------------------------------------------------
  # Initialize (supports Tiled props for atk/def)
  # -------------------------------------------------------------
  def initialize(x, y, hp = 20, type: "default", props: {})
    props ||= {}
	@x, @y = x, y
    @hp = hp
    @dead = false
	@radius = 8 
	@aggro_range = (props["aggro_range"] || 120).to_i
	@aggro_timer = rand(10..60)   # 0.2s to 1s delay
    
    @name = props["name"] || @type.to_s.capitalize

    @max_hp = @hp

    @speed = 0.8
    @direction = :down
    @state = :idle
    @frame = 0
    @last_frame_time = Gosu.milliseconds

    @type = type || "default"
    @config = ENEMY_TYPES[@type]

    # -----------------------------
    # Enemy stats (Tiled override)
    # -----------------------------
@attack_power  = (props["attack"]  || props["atk"]  || 5).to_i
@defense_power = (props["defense"] || props["def"] || 0).to_i
@xp_value      = (props["xp"]      || props["xp_value"] || 10).to_i

    load_animations
  end

  # -------------------------------------------------------------
  # Build animation table dynamically
  # -------------------------------------------------------------
  def load_animations
    @animations = {}

    @config[:states].each do |state|
      @animations[state] = {}

      @config[:dirs].each do |dir|
        frame_count = @config[:frames][state]
        folder = @config[:folder]

        path = "assets/sprites/#{folder}/#{folder}_#{state}_#{dir}.png"
        @animations[state][dir] = load_animation(path, frame_count)
      end
    end
  end

  # -------------------------------------------------------------
  # Update logic
  # -------------------------------------------------------------
  def update(player, physics, ui)
    return if @dead

    dist = Math.hypot(player.x - @x, player.y - @y)

    if @state == :atk
      # Attack animation plays out
    elsif dist < 120 && dist > 18
      @state = :walk
      angle = Math.atan2(player.y - @y, player.x - @x)
      vx = Math.cos(angle) * @speed
      vy = Math.sin(angle) * @speed

      if vx.abs > vy.abs
        @direction = vx > 0 ? :right : :left
      else
        @direction = vy > 0 ? :down : :up
      end

      physics.move(self, vx, vy)

    elsif dist <= 18
      @state = :atk
      @frame = 0

    else
      @state = :idle
    end

    update_animation(player)
  end

  # -------------------------------------------------------------
  # Animation update (variable frame counts)
  # -------------------------------------------------------------
  def update_animation(player)
    anim = @animations[@state][@direction]
    return unless anim

    frame_count = anim.length

    if Gosu.milliseconds - @last_frame_time > 120
      @frame = (@frame + 1) % frame_count
      @last_frame_time = Gosu.milliseconds

      # Enemy hits player on frame 3
      if @state == :atk && @frame == 3 && frame_count > 3
        dmg = [@attack_power - player.defense_power, 1].max
        player.hit(dmg)
      end

      # End attack after animation loops
      if @state == :atk && @frame == 0
        @state = :idle
      end
    end
  end

  # -------------------------------------------------------------
  # Taking damage (player attack)
  # -------------------------------------------------------------
def hit(dmg, player = nil, ui = nil)
  @hp -= dmg

  if @hp <= 0 && !@dead
    @dead = true

    if player && player.respond_to?(:gain_xp)
      player.gain_xp(@xp_value)
    end
  end
end


  def dead?
    @dead
  end

  # -------------------------------------------------------------
  # Draw
  # -------------------------------------------------------------
def draw(cam_x, cam_y)
  return if @dead

  anim = @animations[@state][@direction]
  return unless anim

  screen_x = (@x - cam_x).to_i - 8
  screen_y = (@y - cam_y).to_i - 8

  # Draw sprite
  anim[@frame].draw(screen_x, screen_y, 10)

  # -------------------------------------------------------------
  # Floating Health Bar + Name
  # -------------------------------------------------------------
  bar_width  = 20
  bar_height = 3
  hp_ratio   = @hp.to_f / @max_hp

  # Background bar (dark)
  Gosu.draw_rect(screen_x, screen_y - 10, bar_width, bar_height, Gosu::Color::GRAY, 21)

  # HP bar (red)
  Gosu.draw_rect(screen_x, screen_y - 10, bar_width * hp_ratio, bar_height, Gosu::Color::RED, 22)

  # Name text
  @name_font ||= Gosu::Font.new(8, name: "Courier")
  text_w = @name_font.text_width(@name)
  @name_font.draw_text(@name, screen_x + (bar_width - text_w) / 2, screen_y - 22, 22, 1, 1, Gosu::Color::WHITE)
end

end
