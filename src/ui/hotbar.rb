class Hotbar
  attr_reader :slots, :selected

  def initialize(size = 3)
    @slots = Array.new(size)
    @selected = 0
  end

  # Array-like access
  def [](index)
    @slots[index]
  end

  def []=(index, item)
    return unless index.between?(0, @slots.length - 1)
    @slots[index] = item
  end

  def size
    @slots.length
  end

  # Cycling
  def next
    @selected = (@selected + 1) % @slots.length
  end

  def prev
    @selected = (@selected - 1) % @slots.length
  end

  # Active item
  def current
    @slots[@selected]
  end

  # Needed by UI + Player
  def selected_index
    @selected
  end

  def selected_item
    @slots[@selected]
  end

  # UI helpers — use icon instead of sprite
  def icons
    @slots.map { |item| item&.icon }
  end
end
