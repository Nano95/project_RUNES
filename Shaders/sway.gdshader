/*
Squish Sprite Shader by Garmelon (https://github.com/Garmelon)
Documented by Mateus-Carmo31
*/

shader_type canvas_item;
uniform float amplitude : hint_range(0, 1) = 0.1; // Adjust the amplitude of the waves
uniform float frequency_x : hint_range(0, 5) = 2.0; // Adjust the frequency of the waves in X
uniform float frequency_y : hint_range(0, 5) = 2.0; // Adjust the frequency of the waves in Y

void vertex() {
	// Calculate the wave distortion based on time
	float distortion_x = amplitude * cos(TIME * frequency_x);
	float distortion_y = amplitude * sin(TIME * frequency_y) * 1.5;

	// Calculate a factor to reduce the distortion towards the bottom
	float safe_y = clamp(VERTEX.y, 0.0, 1.0);
	float distortion_factor = 1.0 - clamp(VERTEX.y, 0.0, 1.0);

	// Apply the distortion to the X and Y coordinates of the vertex position
	VERTEX.x += distortion_x * cos(VERTEX.y * frequency_x) * clamp(distortion_factor, 0.0, 1.0);
	VERTEX.y += distortion_y * sin(VERTEX.x * frequency_y) * clamp(distortion_factor, 0.0, 1.0);
}
// To export a variable
uniform bool active = true;

void fragment () {
	// Gets original sprite colors/frame
	vec4 previous_color = texture(TEXTURE, UV);
	// This line goes through each area of the sprite and assigns them white, except for the alpha
	// the alpha is whatt makes sure only the silhouette of the character is white instead of the entire frame
	vec4 white_color = vec4(1.0, 1.0, 1.0, previous_color.a);
	
	vec4 new_color = previous_color;
	if (active == true) {
		new_color = white_color;
	}
	COLOR = new_color;
	
}