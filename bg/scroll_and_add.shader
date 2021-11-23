shader_type canvas_item;

// Simple scroll effect. Optionally add the background color.

uniform vec2 speed = vec2(1., 1.);
uniform bool add = false;

// called for every pixel on the screen
void fragment() {
	float time = TIME;
	vec4 back_color = add ? textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0) : vec4(0.0);
	COLOR = texture(TEXTURE, fract(UV - speed * TEXTURE_PIXEL_SIZE * time)) + back_color;
}