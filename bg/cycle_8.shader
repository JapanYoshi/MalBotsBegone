shader_type canvas_item;

uniform sampler2D palette;
uniform vec4 bg_color: hint_color = vec4(0.0);
uniform float speed = 1.0;

void fragment() {
	vec4 c = textureLod(TEXTURE, UV, 0.0);
    COLOR = mix(
		bg_color,
		texture(palette, vec2(fract(TIME * speed + c.g), 0.0)),
	c.r);
}