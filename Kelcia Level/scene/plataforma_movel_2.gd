extends TileMapLayer

@export var amplitude: float = 40.0   # distância pros lados (menor)
@export var velocidade: float = 2.5  # velocidade mais lenta
var origem: Vector2
var fase := 0.0

func _ready():
	origem = position

func _process(delta):
	fase += delta * velocidade
	position.x = origem.x + sin(fase) * amplitude
