class_name Elements

const NEUTRAL = 1
const FIRE = 2
const SPIRIT = 4
const WATER = 8
const ICE = 16
const STONE = 32
const WIND = 64
const ELECTRIC = 128
const PLANT = 256
const COPY = 512
const METAL = 1024
const LIGHT = 2048
const DARK = 4096

enum Element {
	NEUTRAL = 1,
	FIRE = 2,
	SPIRIT = 4,
	WATER = 8,
	ICE = 16,
	STONE = 32,
	WIND = 64,
	ELECTRIC = 128,
	PLANT = 256,
	COPY = 512,
	METAL = 1024,
	LIGHT = 2048,
	DARK = 4096
}

const element_icons: Array[Texture] = [
	null,
	preload("res://Assets/Sprites/Elements/fire.png"),
	null,
	preload("res://Assets/Sprites/Elements/water.png"),
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null,
	null
]
