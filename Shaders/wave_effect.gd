extends RichTextEffect
class_name WaveJumpEffect

var bbcode := "wave_jump"

@export var amplitude: float = 35.0    # how high the letters move
@export var period: float = .3        # total seconds for one jump cycle (↑ slower)
@export var spread: float = 0.05       # delay between adjacent letters (↑ slower wave travel)
@export var sharpness: float = 1.6     # 1.0 = sine wave, >1 = sharper bounce
@export var play_once: bool = true     # only wave once instead of looping

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var t: float = char_fx.elapsed_time

	# Offset the phase per letter
	var phase: float = t - char_fx.relative_index * spread

	if play_once:
		# Stop after one full wave (phase >= period)
		if phase > period:
			char_fx.offset = Vector2.ZERO
			return true

	# Normalize phase to 0..1
	var u: float = clamp(phase / max(period, 0.001), 0.0, 1.0)

	# Parabola bump shape (quick up, slow down)
	var bump: float = 4.0 * u * (1.0 - u)
	var y: float = -amplitude * pow(bump, sharpness)

	char_fx.offset = Vector2(0.0, y)
	return true
