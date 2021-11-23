shader_type canvas_item;

// HDMA-like wavy effect.

uniform vec2 base_speed = vec2(0., 0.);
uniform vec2 speed = vec2(12., 1.);
uniform vec2 wavelength = vec2(32.0, 1.0);
uniform vec2 amplitude = vec2(8.0, 0.);
uniform bool interlace = true;
const float PI = 3.14159265358979;

vec2 offset(vec2 uv, float time) {
	return (
		amplitude / 64. *
		sin(PI * uv.yy / wavelength + time * speed) *
		vec2(interlace && bool(int(uv.y) % 2) ? -1.0 : 1.0, 1.0)
	);
}

// called for every pixel on the screen
void fragment() {
	vec2 uv = UV * 64.;
	float time = TIME;
	COLOR = texture(TEXTURE, fract(base_speed * time + UV + offset(uv, time)));
//	COLOR = vec4(offset(uv, time) + vec2(0.5, 0.5), 0, 1);
}