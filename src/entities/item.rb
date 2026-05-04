class Item
  attr_reader :id, :name, :kind, :props, :sprite

  def initialize(id, data)
    @id   = id
    @name = data["name"]
    @kind = data["kind"]

    # Start from top-level props (excluding meta fields)
    base_props = data.reject { |k, _| ["name", "kind", "sprite", "icon", "props"].include?(k) }

    # Merge nested "props" hash if present
    if data["props"].is_a?(Hash)
      base_props = base_props.merge(data["props"])
    end

    # Normalize to symbol keys
    @props = base_props.transform_keys(&:to_sym)

    # World-space sprite
    @sprite = Gosu::Image.new(data["sprite"], retro: true)

    # Optional UI icon
    @icon_path = data["icon"] || data["sprite"]
    @icon = nil
  end

  def icon
    @icon ||= Gosu::Image.new(@icon_path, retro: true)
  end
end
