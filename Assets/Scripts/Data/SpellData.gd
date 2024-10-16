class_name SpellData
extends Resource

# Displayed name of the spell
@export var display_name: String

# Texture displayed on the battle HUD for this spell
@export var icon: Texture2D

# Type shown in the spell details menu
# Based on the power types explained on the lemnsicate wiki
# https://lemniscate.fandom.com/wiki/Power_System#Magic_Types
enum SpellType {
	PROJECTILE,
	DEVICE, # weapon
	HELPER,
	MODIFIER
}
@export var spell_type: SpellType

# Element shown in the spells menu for this spell
@export var primary_element: Elements.Element

# Must have this much mana to use the spell.
@export var mana_cost: int

# Cooldown before this spell can be cast again after using
# If flagged as a burst-type spell, will be displayed as "cooldown" instead of speed or delay
@export var cast_delay: float

# If true, cooldown will be visibly displayed in the HUD, and spell menu will use the term "cooldown" instead of "speed" or "delay".
# Used for powerful spells with longer cooldown times. Recommended if cooldown is 3 seconds or longer.
@export var is_burst: bool = false

# Damage shown in the spell menu. Should in most cases reflect how much damage the main hitbox of this spell does
# If 0 or negative, damage won't be displayed
@export var damage: int = 5

# Knockback shown in the spell menu. Typically the knockback magnitude of the main hitbox
# If 0 or negative, damage won't be displayed
@export var knockback: float = 5

# Brief description for the spell shown in the spells menu.
@export var description: String = "A neat spell."

# Contains a scene. Root node is a Spell
@export var equipped_spell_scene: PackedScene

func instantiate_equipped_spell() -> EquippedSpell:
	if not equipped_spell_scene:
		printerr("Spell ", display_name, " has no equipped spell scene!")
		return
	
	return equipped_spell_scene.instantiate() as EquippedSpell


# (Helper Function) Load the data for the spell with the given name.
static func load_spell_data(name: String) -> SpellData:
	return load("res://Assets/Database/Spells/"+name+".tres")
