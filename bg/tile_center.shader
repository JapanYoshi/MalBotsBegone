shader_type canvas_item;

void fragment() {
	COLOR = texture(TEXTURE, fract(UV - vec2(0.5, 0.5)));
}