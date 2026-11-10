shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D color_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_map : filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float metal = 1.0;
uniform float rough = 1.0;
uniform float normal_strength = 1.0;
uniform bool has_normal = true;
uniform bool has_orm = true;
uniform float dissolve : hint_range(0.0,1.0) = 0.0;
varying vec3 surface_position;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise3(vec3 p) {
 vec3 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { surface_position=VERTEX; }
void fragment() {
 float pattern=noise3(surface_position*12.0)*.72+noise3(surface_position*31.0)*.28;
 float threshold=mix(-.1,1.1,dissolve);
 if (pattern<threshold) { discard; }
 float edge=(1.0-smoothstep(0.0,.065,pattern-threshold))*step(.001,dissolve);
 vec3 base=texture(color_map,UV).rgb*tint.rgb;
 ALBEDO=mix(base,vec3(.045,.065,.008),edge);
 vec3 orm=texture(orm_map,UV).rgb;
 METALLIC=metal*(has_orm ? orm.b : 1.0);
 ROUGHNESS=rough*(has_orm ? orm.g : 1.0);
 if (has_normal) { NORMAL_MAP=texture(normal_map,UV).rgb; NORMAL_MAP_DEPTH=normal_strength; }
 EMISSION=vec3(.45,1.0,.025)*edge*2.2;
}
