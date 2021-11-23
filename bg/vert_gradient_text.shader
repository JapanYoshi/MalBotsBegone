shader_type canvas_item;

uniform vec4 colorBgTop: hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 colorBgBottom: hint_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 colorFgTop: hint_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform vec4 colorFgBottom: hint_color = vec4(1.0);
uniform float width = 0.5;
uniform float step_count = 8.0;

void fragment() {
	vec4 c = textureLod(TEXTURE, UV, 0.0);
	COLOR.a = c.r < 0.45 ? 0.0 : 1.0;
    COLOR.rgb = (
		mix(
			c.g < 0.5 ? colorBgBottom.rgb : colorFgBottom.rgb,
			c.g < 0.5 ? colorBgTop.rgb : colorFgTop.rgb,
			ceil(
				step_count * ((UV.y - 0.5) / width + 0.5)
			) / step_count
		)
	);
}