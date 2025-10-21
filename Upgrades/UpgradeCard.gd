extends PanelContainer

# Este sinal imita o sinal "pressed" de um botão.
signal pressed

# --- Referências para os nós da cena ---
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var rarity_label: Label = $VBoxContainer/RarityLabel
@onready var icon_rect: TextureRect = $VBoxContainer/Icon
# (A linha do click_button foi removida)

# --- Dicionário de cores para as raridades ---
const RARITY_COLORS = {
	UpgradeData.Rarity.COMMON: Color.GRAY,
	UpgradeData.Rarity.RARE: Color("dodgerblue"),
	UpgradeData.Rarity.EPIC: Color("mediumpurple")
}
# --- Dicionário de texto para as raridades ---
const RARITY_TEXT = {
	UpgradeData.Rarity.COMMON: "Comum",
	UpgradeData.Rarity.RARE: "Raro",
	UpgradeData.Rarity.EPIC: "Épico"
}

# (A função _ready() e on_button_pressed() foram removidas)

# --- NOVO: Esta função captura cliques do mouse ---
func _gui_input(event: InputEvent) -> void:
	# Verifica se o evento é um clique do mouse, se foi o botão esquerdo, e se foi "pressionado"
	if event is InputEventMouseButton and \
	   event.button_index == MOUSE_BUTTON_LEFT and \
	   event.is_pressed():
		
		# Emite o sinal que o UpgradeScreen está ouvindo
		pressed.emit()
		# Opcional: aceita o evento para impedir que outros nós abaixo dele o recebam
		get_viewport().set_input_as_handled() 

# Esta é a função principal que o UpgradeScreen vai chamar
func set_data(upgrade: UpgradeData) -> void:
	# 1. Define os textos e o ícone
	title_label.text = upgrade.title
	description_label.text = upgrade.description
	
	if upgrade.icon:
		icon_rect.texture = upgrade.icon
	
	# 2. Define o texto da raridade
	if RARITY_TEXT.has(upgrade.rarity):
		rarity_label.text = RARITY_TEXT[upgrade.rarity]
	
	# 3. Define a cor da borda (o visual do PanelContainer)
	var style = get("theme_override_styles/panel")
	var new_style = style.duplicate() as StyleBoxFlat
	
	if new_style and RARITY_COLORS.has(upgrade.rarity):
		new_style.border_color = RARITY_COLORS[upgrade.rarity]
		set("theme_override_styles/panel", new_style)
