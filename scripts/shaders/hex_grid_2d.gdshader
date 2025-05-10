shader_type canvas_item;

uniform vec3 base_col : source_color = vec3(0.05098, 0.25098, 0.2784);
uniform float border_thickness : hint_range(0.0, 0.1) = 0.02;
uniform float isoline_offset : hint_range(0.0, 1.0) = 0.0;
uniform float isoline_offset2 : hint_range(0.0, 1.0) = 0.0;
uniform float pattern_scale : hint_range(0.1, 10.0) = 3.0;
uniform float animation_speed : hint_range(0.0, 1.0) = 0.25;
uniform float time_multiplier : hint_range(0.0, 2.0) = 1.0;
uniform float pixel_size : hint_range(1.0, 512.0) = 512.0;

const vec2 s = vec2(1, 1.7320508);

float calcHexDistance(vec2 p) {
    p = abs(p);
    return max(dot(p, s * 0.5), p.x);
}

float random(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 calcHexInfo(vec2 uv) {
    vec4 hexCenter = round(vec4(uv, uv - vec2(0.5, 1.0)) / s.xyxy);
    vec4 offset = vec4(uv - hexCenter.xy * s, uv - (hexCenter.zw + 0.5) * s);
    return dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw)
        ? vec4(offset.xy, hexCenter.xy)
        : vec4(offset.zw, hexCenter.zw);
}

float smoothEdge(float r, float v) {

    return step(v, r);
}

void fragment() {

    vec2 pixelated_uv = floor(UV * pixel_size) / pixel_size;

    vec2 uv = pattern_scale * pixelated_uv;
    uv.x += TIME * animation_speed * time_multiplier;

    vec4 hexInfo = calcHexInfo(uv);
    float totalDist = calcHexDistance(hexInfo.xy) + border_thickness;
    float rand = random(hexInfo.zw);

    float angle = atan(hexInfo.y, hexInfo.x) + rand * 5.0 + TIME;
    vec3 isoline = smoothEdge(isoline_offset, totalDist) * base_col * step(3.0 + rand * 0.5, mod(angle, 6.28))
        + smoothEdge(isoline_offset2, totalDist)
                    * base_col * step(4.0 + rand * 1.5, mod(angle + rand * 2.0, 6.28));

    float sinOffset = sin(TIME + rand * 8.0);


    COLOR.rgb = (step(0.51, totalDist) + pow(1.0 - max(0.0, 0.5 - totalDist), 20.0) * 1.5)
        * (base_col + rand * vec3(0.0, 0.1, 0.09)) + isoline + base_col * step(0.2 + sinOffset, totalDist);

    COLOR.a = texture(TEXTURE, UV).a;
}