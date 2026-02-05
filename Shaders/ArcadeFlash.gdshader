shader_type canvas_item;

uniform float time : hint_range(-10, 10) = 0.0;
uniform bool activate = false;

void fragment() {
    // Define the colors
	
    vec3 red = vec3(1.0, 0.0, 0.0);
    vec3 white = vec3(1.0, 1.0, 1.0);
    vec3 yellow = vec3(1.0, 1.0, 0.0);
	vec3 green = vec3(0.0, 1.0, 0.0);

    // Calculate a periodic function to create the color sequence
	
	if (activate && COLOR.rgb != vec3(0.0, 0.0, 0.0)) {
	    float t = mod(TIME * 16.0, 6.0);
	    vec3 color;

	    if (t < 1.0) {
	        color = mix(red, white, t);
	    } else if (t < 2.0) {
	         color =  mix(white, yellow, t - 1.0);
	    } else if (t < 3.0) {
	        color = mix(yellow, white, t - 2.0);
		} else if (t < 4.0) {
			color = mix(white, green, t - 3.0);
	    } else if (t < 5.0) {
			color = mix(green, white, t - 4.0);
	    } else if (t < 6.0) {
			color = mix(white, red, t - 5.0);
	    } 

	    // Output the final color
	    COLOR.rgb = color;
	}
}