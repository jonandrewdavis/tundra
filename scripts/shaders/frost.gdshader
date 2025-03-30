/*
Copyright Nathanael C. Fritz 2024
License MIT
*/
shader_type canvas_item;

// mipmap is neaded for textureLod
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest_mipmap;

// see bottom for texture/normal FastNoiseLite generators

// used with coverage uniform to determine where to show ice
uniform sampler2D coverage_texture: repeat_enable;
// used for coloring cracks
uniform sampler2D crack_texture: repeat_enable;
// used for distorting light through cracks
uniform sampler2D crack_normal: repeat_enable;
// used for extra surface highlights
uniform sampler2D bump_normal: repeat_enable;
// used for distorting light and bumpy surface highlights
uniform sampler2D warp_normal: repeat_enable;

// mouse pointer light
uniform vec2 pointer = vec2(1.0, 1.0);

// ice coverage threshold
uniform float coverage: hint_range(0.0, 2.0) = 0.5;
// distortion behind ice
uniform float distort: hint_range(0.0, 0.3) = 0.01;
// how bumpy is the surface of the ice
uniform float bumpiness: hint_range(0.0, 1.0) = 0.8;
// emphasis of crack distortion and color
uniform float crack_intensity: hint_range(0.0, 1.0) = 0.5;
// how bright should light highlights be
uniform float diffusion: hint_range(0.0, 1.0) = 0.8;
// what color should we be tinting? usually a dark blue
uniform vec4 tint_color: source_color = vec4(0.025, 0.139, 0.36, 1.0);
// how strong should the tint be
uniform float tint_amount: hint_range(0.0, 1.0) = 0.4;

vec2 generate_normal(sampler2D in_texture, float threshold, vec2 uv, vec2 pixel_size) {
	// Sobel operator to detect edges on the thresholded texture
	pixel_size *= 3.0;
	float scale = 0.85;

	// poor man's normal, using our threshold edges
	float left = step(threshold, texture(in_texture, uv + vec2(pixel_size.x, 0.0)).r);
	float right = step(threshold, texture(in_texture, uv - vec2(pixel_size.x, 0.0)).r);
	float down = step(threshold, texture(in_texture, uv + vec2(0.0, pixel_size.y)).r);
	float up = step(threshold, texture(in_texture, uv - vec2(0.0, pixel_size.y)).r);

	float horiz = (right - left) * scale;
	float vert = (up - down) * scale;
	vec3 norm = normalize(vec3(horiz, vert, 0.4));
	return norm.xy;
}

void fragment() {
	// our UV is probably not square
	// so we correction the ratio and only use the original UV for sampling
	// the screen background
	float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec2 uv = vec2(UV.x, UV.y * ratio);

	// correct our mouse position
	vec2 shine_pos = pointer;
	shine_pos.y *= ratio;

	// get our warp normal for distorting the background
	vec2 warp = texture(warp_normal, uv).xy - 0.5;
	// we need to dynamically generate a normal for our coverage because the edges
	// are dynamicly set by "coverage"
	vec2 coverage_normal = generate_normal(coverage_texture, coverage / 2.0, uv, SCREEN_PIXEL_SIZE);
	// scale by bumpiness
	warp *= bumpiness;

	// sample the coverage texture to determin where ice will be
	float area = texture(coverage_texture, uv).r;
	// generate a threshold
	// we can now multiply our ice effects by "effects" which is a 1.0 or 0.0
	// disabling our effects for any pixel outside of the ice
	float effect = step(area, coverage / 2.0);

	// set a threshold where cracks can be
	float show_crack = mix(0.0, 1.0, step(area, coverage - 0.5));
	// set a higher threshold for where cracks are colored instance
	float color_crack = mix(0.0, 1.0, step(area, coverage - 0.7));

	// sample our bump normal

	vec2 bump = texture(bump_normal, uv).xy - 0.5;
	warp += bump * min(3.0, 6.0 * bumpiness);
	warp.x *= -1.0;

	// sample our crack normal and crack texture
	vec2 crack = texture(crack_normal, uv * 2.0).xy - 0.5;
	float crack_sample = texture(crack_texture, uv * 2.0).r;

	// make a circle of light at the mouse position
	float shine = smoothstep(0.1, 0.0, distance(uv, shine_pos));
	vec2 lightDir = -normalize(shine_pos - uv);

	// get our light diffuse value
	float diffuse = max(dot(warp + coverage_normal, lightDir), 0.0);

	// mask cracks based on diffuse value
	show_crack *= abs(diffuse - 0.5);

	// final calculation of the distortion effect
	// of ice and cracks
	vec2 uv_offset = SCREEN_UV + (warp * effect * distort)
		+ (crack * show_crack * effect * crack_intensity);

	// sample background from distorted viewpoint
	// basic LOD blur as well
	vec4 screen = textureLod(screen_texture, uv_offset, effect * distort * 5.0);

	// tint ice affected pixels
	screen = mix(screen, tint_color, tint_amount * effect);

	// apply diffusion based on intensity
	// apply a spotline shine, and increase diffusion under shine
	screen.rgb += diffuse * effect * (diffusion + shine);
	screen.rgb += shine * 0.5 * effect;

	// yarp
	COLOR = vec4(screen);
}