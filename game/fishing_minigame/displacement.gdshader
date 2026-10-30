shader_type canvas_item;

uniform sampler2D screen: hint_screen_texture;
uniform sampler2D mask: hint_default_white;
uniform sampler2D displacement_texture;
uniform float force: hint_range(0.0, 0.1, 0.001);

void fragment() {
	vec2 uv = SCREEN_UV;
	float weigth = texture(mask, uv).a;
	
	vec2 disp_u = fract(SCREEN_UV + vec2(TIME / 20.0));
	vec2 disp_v = fract(SCREEN_UV + vec2(TIME / 30.0));
	uv.x += texture(displacement_texture, disp_u).r * weigth * force;
	uv.y += texture(displacement_texture, disp_v).g * weigth * force;
	COLOR = texture(screen, uv);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
