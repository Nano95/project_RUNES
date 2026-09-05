shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform bool enabled = true;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    if (!enabled) {
        COLOR = color;
    } else if (color.a > 0.5) {
        COLOR = color;
    } else {
        vec2 size = outline_width / vec2(textureSize(TEXTURE, 0));
        float alpha = 0.0;
        alpha = max(alpha, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
        alpha = max(alpha, texture(TEXTURE, UV - vec2(size.x, 0.0)).a);
        alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
        alpha = max(alpha, texture(TEXTURE, UV - vec2(0.0, size.y)).a);
        alpha = max(alpha, texture(TEXTURE, UV + vec2(size.x, size.y)).a);
        alpha = max(alpha, texture(TEXTURE, UV - vec2(size.x, size.y)).a);
        alpha = max(alpha, texture(TEXTURE, UV + vec2(size.x, -size.y)).a);
        alpha = max(alpha, texture(TEXTURE, UV - vec2(size.x, -size.y)).a);
        
        if (alpha > 0.5) {
            COLOR = vec4(outline_color.rgb, 1.0);
        } else {
            COLOR = color;
        }
    }
}