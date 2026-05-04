require "json"
require "rexml/document"

class Map
  attr_reader :width, :height, :tile_w, :tile_h, :collision, :objects, :doors, :door_instances

  def initialize(json_path)
    data = JSON.parse(File.read(json_path))

    @width    = data["width"]
    @height   = data["height"]
    @tile_w   = data["tilewidth"]  || 16
    @tile_h   = data["tileheight"] || 16
    @layers   = data["layers"]

    @collision = Array.new(@height) { Array.new(@width, false) }
    @objects   = []
    @doors     = []          # filled AFTER parsing
    @door_instances = []     # actual Door objects

    @tilesets  = []

    load_tilesets(json_path, data)
    preprocess_tile_layers
    parse_object_layers
    instantiate_doors
  end

  # ----------------------------------------------------
  # Load tilesets (supports external .tsx)
  # ----------------------------------------------------
  def load_tilesets(json_path, data)
    data["tilesets"].each do |ts|
      first_gid = ts["firstgid"]

      img_path =
        if ts["source"] # external TSX tileset
          tsx_path = File.join(File.dirname(json_path), ts["source"])
          raise "TSX file not found: #{tsx_path}" unless File.exist?(tsx_path)

          xml = REXML::Document.new(File.read(tsx_path))
          image_node = xml.elements["tileset/image"]
          raise "No <image> tag found in TSX: #{tsx_path}" unless image_node

          image_node.attributes["source"]
        else
          ts["image"]
        end

      full_path =
        if File.exist?("assets/tilesets/#{img_path}")
          "assets/tilesets/#{img_path}"
        elsif File.exist?("assets/tiles/#{img_path}")
          "assets/tiles/#{img_path}"
        else
          raise "Tileset image not found: #{img_path}"
        end

      tiles = Gosu::Image.load_tiles(full_path, @tile_w, @tile_h, retro: true, tileable: true)

      @tilesets << {
        first_gid: first_gid,
        last_gid:  first_gid + tiles.length - 1,
        tiles: tiles
      }
    end
  end

  # ----------------------------------------------------
  # Preprocess tile layers (render + collision)
  # ----------------------------------------------------
  def preprocess_tile_layers
    @render_layers = []

    @layers.each do |layer|
      next unless layer["type"] == "tilelayer"

      # Collision layer
      if layer["name"].downcase.include?("collision")
        layer["data"].each_with_index do |raw_gid, i|
          gid = raw_gid & 0x0FFFFFFF
          @collision[i / @width][i % @width] = true if gid != 0
        end
        next
      end

      # Visible render layer
      tiles = []
      layer["data"].each_with_index do |raw_gid, i|
        next if raw_gid == 0

        gid = raw_gid & 0x0FFFFFFF
        ts = resolve_tileset(gid)
        next unless ts

        tile_x = (i % @width) * @tile_w
        tile_y = (i / @width) * @tile_h

        tiles << {
          gid: gid,
          tileset: ts,
          x: tile_x,
          y: tile_y
        }
      end

      @render_layers << {
        tiles: tiles,
        opacity: (layer["opacity"] || 1.0)
      }
    end
  end

  # ----------------------------------------------------
  # Parse object layers (enemies, pickups, doors, etc.)
  # ----------------------------------------------------
  def parse_object_layers
    @layers.each do |layer|
      next unless layer["type"] == "objectgroup"

      layer["objects"].each do |obj|
        props = {}
        obj["properties"]&.each { |p| props[p["name"]] = p["value"] }

        # Tiled 1.11+ may use "class" instead of "type"
        raw_type =
          if obj["type"] && obj["type"] != ""
            obj["type"]
          elsif obj["class"] && obj["class"] != ""
            obj["class"]
          elsif obj["name"] && obj["name"] != ""
            obj["name"]
          elsif props["type"]
            props["type"]
          else
            ""
          end

        resolved_type = raw_type.downcase

        # Normalize to center of object (coords are in pixels)
        ox = obj["x"] + (obj["width"]  || 0) / 2
        oy = obj["y"] + (obj["height"] || 0) / 2

        entry = {
          name: (obj["name"] || "").downcase,
          type: resolved_type,
          x: ox,
          y: oy,
          props: props
        }

        @objects << entry
      end
    end

    # Extract doors AFTER objects exist
    @doors = @objects.select { |o| o[:type] == "door" }
  end

  # ----------------------------------------------------
  # Instantiate actual Door objects
  # ----------------------------------------------------
  def instantiate_doors
    @door_instances = @doors.map do |d|
      Door.new(d[:x], d[:y], d[:props]["key_id"])
    end
  end

  # ----------------------------------------------------
  # Resolve which tileset a GID belongs to
  # ----------------------------------------------------
  def resolve_tileset(gid)
    @tilesets.find { |ts| gid >= ts[:first_gid] && gid <= ts[:last_gid] }
  end

  # ----------------------------------------------------
  # Collision check
  # ----------------------------------------------------
  def solid?(px, py)
    tx = (px / @tile_w).floor
    ty = (py / @tile_h).floor
    return true unless tx.between?(0, @width - 1) && ty.between?(0, @height - 1)
    @collision[ty][tx]
  end

  # ----------------------------------------------------
  # Draw visible layers with camera culling + opacity
  # ----------------------------------------------------
  def draw(cam_x, cam_y, screen_w, screen_h)
    cam_x = cam_x.to_i
    cam_y = cam_y.to_i

    @render_layers.each do |layer|
      alpha = (layer[:opacity] * 255).to_i
      color = Gosu::Color.rgba(255, 255, 255, alpha)

      layer[:tiles].each do |t|
        # Pixel-perfect draw positions
        screen_x = (t[:x] - cam_x).to_i
        screen_y = (t[:y] - cam_y).to_i

        # Camera culling
        next if screen_x < -@tile_w || screen_x > screen_w
        next if screen_y < -@tile_h || screen_y > screen_h

        index = t[:gid] - t[:tileset][:first_gid]
        tile_img = t[:tileset][:tiles][index]
        next unless tile_img

        tile_img.draw(screen_x, screen_y, 0, 1, 1, color)
      end
    end
  end

  # ----------------------------------------------------
  # Helper: get objects by type
  # ----------------------------------------------------
  def objects_of(type)
    type = type.downcase
    @objects.select { |o| o[:type] == type }
  end
end
