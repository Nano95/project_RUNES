shader_type canvas_item;

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