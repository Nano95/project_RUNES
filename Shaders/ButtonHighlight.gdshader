shader_type canvas_item;

uniform float swirl_strength = 3.0;
uniform float swirl_speed = 1.5;

uniform vec4 color1 : source_color = vec4(0.2, 0.2, 0.4, 1.0);
uniform vec4 color2 : source_color = vec4(0.6, 0.6, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 0.8); // dark outline

// --- Your hash ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(0.1, 101.7))) * 10.0);
}

// --- Your smooth noise ---
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;

    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    // Your swirl
    angle += sin(radius * swirl_strength - TIME * swirl_speed) * 0.4;

    vec2 swirl_uv = vec2(cos(angle), sin(angle)) * radius;

    // --- Base noise ---
    float n = noise(swirl_uv * 2.0 + TIME * 0.5);

    // --- Quantize noise into chunky bands ---
    float q = floor(n * 2.0) / 2.0;

    // --- Outline detection ---
    // Slightly offset second sample
    float n2 = noise(swirl_uv * 6.0 + TIME * 0.5 + vec2(0.12, -0.08));
    float q2 = floor(n2 * 4.0) / 4.0;

    // If quantized values differ → edge
    float edge = step(0.05, abs(q - q2));

    // --- Base color blend ---
    vec4 col = mix(color1, color2, q);

    // --- Apply outline ---
    col = mix(col, outline_color, edge);

    // --- Circular mask ---
    float mask = smoothstep(1.0, 0.7, radius);
    col.a *= mask;

    COLOR = col;
}
