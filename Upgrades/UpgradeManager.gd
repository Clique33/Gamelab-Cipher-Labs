extends Node

var upgrade_screen_scene: PackedScene = preload("res://Upgrades/UpgradeScreen.tscn")

# Mudei para @export, como pedimos na última conversa,
# para você poder arrastar os upgrades no Inspector.
# Sem @export! Isso é uma variável normal de script.
var MASTER_UPGRADE_POOL: Array[UpgradeData] = [
	preload("res://Upgrades/Common/upgrade_cooldown_1.tres"),
	preload("res://Upgrades/Common/upgrade_crit_chance_1.tres"),
	preload("res://Upgrades/Common/upgrade_damage_1.tres"),
	preload("res://Upgrades/Common/upgrade_health_1.tres"),
	preload("res://Upgrades/Common/upgrade_machine_gun_damage.tres"),
	preload("res://Upgrades/Common/upgrade_medkit_1.tres"),
	preload("res://Upgrades/Common/upgrade_shotgun_damage.tres"),
	preload("res://Upgrades/Epic/upgrade_crit_chance_3.tres"),
	preload("res://Upgrades/Epic/upgrade_crit_damage_2.tres"),
	preload("res://Upgrades/Epic/upgrade_damage_3.tres"),
	preload("res://Upgrades/Epic/upgrade_damage_aura.tres"),
	preload("res://Upgrades/Epic/upgrade_health_3.tres"),
	preload("res://Upgrades/Rare/upgrade_cooldown_2.tres"),
	preload("res://Upgrades/Rare/upgrade_crit_damage_1.tres"),
	preload("res://Upgrades/Rare/upgrade_damage_2.tres"),
	preload("res://Upgrades/Rare/upgrade_machine_gun.tres"),
	preload("res://Upgrades/Rare/upgrade_move_speed_2.tres"),
	preload("res://Upgrades/Rare/upgrade_player_vision.tres"),
	preload("res://Upgrades/Rare/upgrade_random_aoe.tres"),
	preload("res://Upgrades/Rare/upgrade_shotgun_cooldown.tres"),
	preload("res://Upgrades/Common/upgrade_shotgun.tres")
]

var player_node: Player

# --- MUDANÇA 2 ---
# Este array guardará os upgrades disponíveis PARA A RODADA ATUAL.
var available_pool: Array[UpgradeData] = []
# --- FIM DAS MUDANÇAS ---

# --- MUDANÇA 3 ---
# Adicione esta nova função. Ela deve ser chamada pelo seu script
# "world" ou "game_manager" toda vez que um novo jogo começa.
func start_new_run() -> void:
	# Usamos .duplicate() para criar uma CÓPIA, não uma referência.
	available_pool = MASTER_UPGRADE_POOL.duplicate()
# --- FIM DA MUDANÇA ---

# --- REMOVIDO ---
# var common_upgrades: Array[UpgradeData]
# var rare_upgrades: Array[UpgradeData]
# var epic_upgrades: Array[UpgradeData]
#
# func _ready() -> void:
#	... (toda a função foi removida)
# --- FIM DA REMOÇÃO ---


func register_player(player: Player) -> void:
	player_node = player
	if player_node.experience_node:
		player_node.experience_node.leveled.connect(on_player_leveled_up)

# --- FUNÇÃO on_player_leveled_up TOTALMENTE REESCRITA ---
func on_player_leveled_up(new_level: int) -> void:
	get_tree().paused = true

	var chosen_upgrades: Array[UpgradeData] = []
	
	# 1. Primeiro, crie um pool de upgrades válidos para ESTE sorteio
	var available_upgrades: Array[UpgradeData] = []
	
	# 2. Descobre quais armas o jogador tem
	var player_weapon_names: Array[StringName] = []
	for child in player_node.get_children():
		if child is WeaponBase:
			player_weapon_names.append(child.name)
			
	# --- MUDANÇA 4 ---
	# Filtra a partir do 'available_pool', não do 'upgrade_pool'
	for upgrade in available_pool:
		var is_valid = true
		
		if upgrade.type == UpgradeData.UpgradeType.STAT_WEAPON_SPECIFIC:
			if not player_weapon_names.has(upgrade.weapon_id):
				is_valid = false
		
		if is_valid:
			available_upgrades.append(upgrade)
			
	# 4. Sorteio Aleatório
	# Embaralha o pool de upgrades válidos
	available_upgrades.shuffle()
	
	# 5. Pega os 3 primeiros (ou menos, se não houver 3)
	var num_to_pick = min(3, available_upgrades.size())
	chosen_upgrades = available_upgrades.slice(0, num_to_pick)

	# 6. Mostra a tela
	var screen = upgrade_screen_scene.instantiate()
	add_child(screen)
	screen.set_upgrades(chosen_upgrades)
	screen.upgrade_selected.connect(on_upgrade_selected)
# --- FIM DA ATUALIZAÇÃO ---

# --- FUNÇÃO on_upgrade_selected ATUALIZADA ---
func on_upgrade_selected(upgrade: UpgradeData, ui_screen: Node) -> void:
	apply_upgrade(upgrade)
	
	# --- MUDANÇA 5 ---
	# Agora remove a arma do 'available_pool' (o pool da rodada atual)
	if upgrade.type == UpgradeData.UpgradeType.NEW_WEAPON:
		for u in available_pool:
			if u.weapon_scene == upgrade.weapon_scene:
				available_pool.erase(u)
				break

	ui_screen.queue_free()
	get_tree().paused = false
# --- FIM DA ATUALIZAÇÃO ---


# --- FUNÇÃO HELPER (Sem mudanças) ---
func _apply_stat_upgrade(base_node: Node, stat_key_string: StringName, stat_value: float, is_multiplier: bool) -> void:
	var target_node = base_node
	var property_path = str(stat_key_string)
	
	var node_path_parts = property_path.split("/")
	
	var property_key = node_path_parts[node_path_parts.size() - 1]
	var node_path_array = node_path_parts.slice(0, node_path_parts.size() - 1)

	if node_path_array.size() > 0:
		var node_path = "/".join(node_path_array)
		target_node = base_node.get_node_or_null(node_path)

	if not target_node:
		print("UpgradeManager: Não foi possível encontrar o nó em: ", property_path, " a partir de ", base_node.name)
		return

	var property_parts = property_key.split(":")
	
	var final_property_name = property_parts[property_parts.size() - 1]
	var sub_property_array = property_parts.slice(0, property_parts.size() - 1)
	
	var final_target_object = target_node
	
	if sub_property_array.size() > 0:
		for sub_prop in sub_property_array:
			if final_target_object:
				final_target_object = final_target_object.get(sub_prop)
			else:
				print("UpgradeManager: Sub-propriedade não encontrada: ", sub_prop, " em ", property_path)
				return

	if not final_target_object:
		print("UpgradeManager: Objeto final não encontrado para: ", property_key)
		return

	var current_val = final_target_object.get(final_property_name)
	if is_multiplier:
		final_target_object.set(final_property_name, current_val * stat_value)
	else:
		final_target_object.set(final_property_name, current_val + stat_value)
# --- FIM DA FUNÇÃO HELPER ---


# --- FUNÇÃO apply_upgrade (Sem mudanças) ---
func apply_upgrade(upgrade: UpgradeData) -> void:
	if not player_node: return

	match upgrade.type:
		UpgradeData.UpgradeType.NEW_WEAPON:
			if upgrade.weapon_scene:
				var new_weapon = upgrade.weapon_scene.instantiate()
				player_node.add_child(new_weapon)
				
				# Bloco para stats de override (armas básicas)
				if not upgrade.override_stats.is_empty():
					for stat_name in upgrade.override_stats.keys():
						var stat_value = upgrade.override_stats[stat_name]
						if new_weapon.has_method("set"):
							new_weapon.set(stat_name, stat_value)
				
		UpgradeData.UpgradeType.STAT_PLAYER:
			_apply_stat_upgrade(player_node, upgrade.stat_key, upgrade.stat_value, upgrade.is_multiplier)

		UpgradeData.UpgradeType.STAT_WEAPON_ALL:
			for child in player_node.get_children():
				if child is WeaponBase:
					if child.has_method("get") and not str(upgrade.stat_key).contains("/") and not str(upgrade.stat_key).contains(":"):
						var current_val = child.get(upgrade.stat_key)
						if upgrade.is_multiplier:
							child.set(upgrade.stat_key, current_val * upgrade.stat_value)
						else:
							child.set(upgrade.stat_key, current_val + upgrade.stat_value)
			
			if player_node.has_method("get") and not str(upgrade.stat_key).contains("/") and not str(upgrade.stat_key).contains(":"):
				var current_val = player_node.get(upgrade.stat_key)
				if upgrade.is_multiplier:
					player_node.set(upgrade.stat_key, current_val * upgrade.stat_value)
				else:
					player_node.set(upgrade.stat_key, current_val + upgrade.stat_value)
		
		UpgradeData.UpgradeType.STAT_WEAPON_SPECIFIC:
			if upgrade.weapon_id == &"":
				return
			
			for child in player_node.get_children():
				if child.name == upgrade.weapon_id:
					_apply_stat_upgrade(child, upgrade.stat_key, upgrade.stat_value, upgrade.is_multiplier)
					break
# --- FIM ATUALIZAÇÃO ---

# --- FUNÇÕES REMOVIDAS ---
# func _get_random_rarity() -> UpgradeData.Rarity:
# func _get_upgrade_from_pool(rarity: UpgradeData.Rarity) -> UpgradeData:
# func _fill_remaining_upgrades(chosen_upgrades: Array[UpgradeData]):
# --- FIM DA REMOÇÃO ---
