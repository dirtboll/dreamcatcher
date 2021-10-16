extends StaticBody2D

var tile_pos = Vector2.ZERO
var tilemap: TileMap = null

func hit(dmg, hitter):
	hitter.health = hitter.max_health
	tilemap.set_cellv(tile_pos, -1)
	queue_free()