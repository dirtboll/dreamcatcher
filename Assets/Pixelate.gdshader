shader_type canvas_item;

uniform int pixel_size : hint_range(1, 100) = 1;

void fragment() {
	vec2 uv = SCREEN_UV;
	float size_x = float(pixel_size) / 1000.0;
	float size_y = float(pixel_size) / 1000.0;
	uv -= mod(uv, vec2(size_x, size_y));

	COLOR.rgb = textureLod(SCREEN_TEXTURE, uv, 0.0).rgb;
}
