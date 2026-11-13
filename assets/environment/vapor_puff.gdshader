shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float opacity = 0.0;
uniform float age = 0.0;
uniform float seed = 0.0;
uniform vec3 tint : source_color = vec3(.65,.66,.68);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=UV*4.0+vec2(seed,age*.6);
 float n=noise(p)*.60+noise(p*2.03)*.28+noise(p*4.11)*.12;
 float radial=1.0-smoothstep(.12,.50,length(UV-.5));
 ALBEDO=tint*(.78+n*.32);
 ALPHA=radial*smoothstep(.20,.73,n)*opacity;
}
