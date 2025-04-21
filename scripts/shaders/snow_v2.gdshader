shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled, ambient_light_disabled;
 
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;
uniform sampler2D texture_backlight : hint_default_black, filter_nearest, repeat_enable;
 
void vertex() {
    mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
    mat_world = mat_world * mat4(vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
    MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
 
void fragment() {
    vec2 base_uv = UV;
    vec4 albedo_tex = texture(texture_albedo, base_uv);
    vec3 albedo_color = albedo.rgb * albedo_tex.rgb;
 
    float intensity = dot(albedo_color, vec3(0.3, 0.59, 0.11));
 
	ALBEDO = albedo_color;
    ALPHA *= albedo.a * albedo_tex.a;
 
    vec3 backlight_tex = texture(texture_backlight, base_uv).rgb;
 
    BACKLIGHT = backlight_tex;
	ALBEDO = albedo_color *= BACKLIGHT *2.0;
}