shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D color_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_map : filter_linear_mipmap, repeat_enable;
void fragment() {
 vec3 color=texture(color_map,UV).rgb;
 vec3 orm=texture(orm_map,UV).rgb;
 ALBEDO=color;
 METALLIC=orm.b;
 ROUGHNESS=orm.g;
 NORMAL_MAP=texture(normal_map,UV).rgb;
 float band=smoothstep(.10,.28,color.r-max(color.g,color.b))*smoothstep(.12,.4,color.r);
 EMISSION=vec3(1.0,.008,.003)*band*1.3;
}
