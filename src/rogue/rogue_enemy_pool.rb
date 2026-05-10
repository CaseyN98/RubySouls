# src/rogue/rogue_enemy_pool.rb
class RogueEnemyPool
  EnemyTemplate = Struct.new(:type, :base_hp, :base_atk)

  NORMAL_ENEMIES = [
    EnemyTemplate.new("slime",    20,  5),
    EnemyTemplate.new("default",   25,  7),
	EnemyTemplate.new("skeleton", 30,  8),
    EnemyTemplate.new("Bskeleton", 70,  15)
  ]

  BOSS_NAMES = {
    "slime"    => ["Slime King", "Toxic Slime", "Gelatin Titan"],
    "default"   => ["Goblin Warlord", "Goblin Champion", "Goblin Berserker"],
    "skeleton" => ["Bone Lord", "Skeleton Knight", "Death Rattler"],
	"Bskeleton" => ["Dark Lord", "Skeleton Bruiser", "Cursed Rattler"]
  }

  def self.random_enemy_for_floor(floor)
    template = NORMAL_ENEMIES.sample

    hp  = template.base_hp + floor * 6 + rand(0..8)
    atk = template.base_atk + floor * 2 + rand(0..3)

    {
  type: template.type,
  props: {
    "hp" => hp,
    "atk" => atk,
    "xp" => 5 + floor * 2   # or whatever scaling you want
  }
}

  end

  def self.random_boss_for_floor(floor)
    template = NORMAL_ENEMIES.sample
    boss_name = BOSS_NAMES[template.type].sample

    hp  = template.base_hp + floor * 40 + rand(20..40)
    atk = template.base_atk + floor * 5  + rand(3..6)

    {
  type: template.type,
  props: {
    "hp"   => hp,
    "atk"  => atk,
    "boss" => true,
    "name" => boss_name,
    "xp"   => 20 + floor * 5
  }
}

  end
end
