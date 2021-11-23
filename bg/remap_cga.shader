shader_type canvas_item;

uniform vec4 color0: hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color1: hint_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 color2: hint_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 color3: hint_color = vec4(1.0);

void fragment() {
	vec3 c = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
    COLOR = (
		c.r < 0.5 ? (
			c.g < 0.5 ? color0 : color1
		) : (
			c.g < 0.5 ? color2 : color3
		)
	);
}