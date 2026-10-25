class_name StageConfig
extends Resource

@export_range(1, 3, 1) var max_clients: int = 1
@export_range(1, 6, 1) var max_parts_per_client: int = 2
@export var pay_multiplier: float = 1.0
@export var client_min_patience: float = 15
@export var client_max_patience: float = 20
