require "json"
require_relative "item"

ITEM_DB = {}

raw = JSON.parse(File.read("src/entities/items.json"))

raw.each do |id, data|
  ITEM_DB[id] = data   # store raw hash, NOT Item.new
end
