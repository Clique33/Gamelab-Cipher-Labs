# res://Upgrades/UpgradeData.gd
class_name UpgradeData
extends Resource

# Enum para os tipos de upgrade
enum UpgradeType {
	NEW_WEAPON,
	STAT_PLAYER,
	STAT_WEAPON_ALL,
	STAT_WEAPON_SPECIFIC # Você também precisa deste tipo
}

# Enum para as raridades
enum Rarity {
	COMMON,
	RARE,
	EPIC
}

@export var type: UpgradeType
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D

@export var rarity: Rarity = Rarity.COMMON

# Para NEW_WEAPON
@export var weapon_scene: PackedScene

# --- ESTA É A LINHA QUE ESTÁ FALTANDO ---
@export var override_stats: Dictionary = {}
# --- FIM ---

# Para STAT_PLAYER, STAT_WEAPON_ALL, STAT_WEAPON_SPECIFIC
@export var stat_key: StringName
@export var stat_value: float
@export var is_multiplier: bool = true
@export var weapon_id: StringName # Você também precisa desta
