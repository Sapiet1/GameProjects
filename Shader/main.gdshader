shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX.y += sin(TIME + VERTEX.x);
	VERTEX.x += cos(TIME + 2.0 * VERTEX.y);

}

void fragment() {
	// Called for every pixel the material is visible on.
	if (UV.x > abs(sin(TIME)) / 2.0) {
		ALBEDO = vec3(abs(sin(TIME + VERTEX.y * VERTEX.x)), abs(sin(TIME + VERTEX.y)), abs(sin(TIME + VERTEX.x)));
		ROUGHNESS = 0.2;
		RIM = 1.0;
		METALLIC = abs(sin(TIME)) / 2.0;
	} else {
		ROUGHNESS = abs(cos(TIME));
		EMISSION = vec3(0, 10, 10);
		ALBEDO = vec3(abs(cos(TIME + 4.0 * VERTEX.y * VERTEX.x)), abs(cos(TIME + 2.0 * VERTEX.y)), abs(cos(TIME + 2.0 * VERTEX.x)));
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
