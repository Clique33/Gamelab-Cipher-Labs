# res://Upgrades/UpgradeScreen.gd
extends CanvasLayer

# Sinal que o UpgradeManager está ouvindo
signal upgrade_selected(upgrade: UpgradeData, screen: Node)

# Arraste o HBoxContainer para esta variável no Inspetor
@export var card_container: HBoxContainer
# Arraste a cena UpgradeCard.tscn para esta variável no Inspetor
@export var upgrade_card_scene: PackedScene

# Esta é a função que o UpgradeManager chama (plural)
func set_upgrades(upgrades: Array[UpgradeData]) -> void:
	# Limpa cards antigos, se houver
	for child in card_container.get_children():
		child.queue_free()

	if upgrade_card_scene == null:
		print("UpgradeScreen: A cena 'upgrade_card_scene' não foi definida!")
		return

	# Cria um card para cada upgrade
	for upgrade_data in upgrades:
		var card = upgrade_card_scene.instantiate()
		card_container.add_child(card)
		card.set_data(upgrade_data)

		# 🔗 Conecta o sinal do card à função local
		card.pressed.connect(func():
			_on_card_selected(upgrade_data)
		)


# Esta função é chamada por qualquer card que for clicado
func _on_card_selected(upgrade: UpgradeData) -> void:
	# Emite o sinal principal para o UpgradeManager
	# Passa o upgrade e uma referência a si mesmo (para o queue_free)
	upgrade_selected.emit(upgrade, self)
