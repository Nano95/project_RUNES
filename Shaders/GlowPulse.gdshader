shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;
uniform vec4 glow_color : source_color = vec4(0.6, 0.8, 1.0, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Base sprite
    COLOR = tex;

    // Pulse factor (0.85 → 1.15)
    float pulse = 0.95 + 0.45 * sin(TIME * pulse_speed);

    // Glow mask: stronger at edges, softer inside
    float dist = length(UV - vec2(0.5));
    float glow = smoothstep(0.45, 0.15, dist); // inner soft glow

    // Combine glow + pulse
    float final_glow = glow * glow_strength * pulse;

    // Additive glow on top of sprite
	COLOR = glow_color * final_glow;
	
}
