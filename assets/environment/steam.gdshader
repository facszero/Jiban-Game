shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float seed = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=UV*vec2(3.0,4.0)+vec2(seed,TIME*.22);
 float n=noise(p)*.6+noise(p*2.03)*.3+noise(p*4.11)*.1;
 float edge=pow(max(0.0,1.0-abs(UV.x*2.0-1.0)),1.6)*sin(UV.y*3.14159);
 ALBEDO=vec3(.40,.38,.38);
 ALPHA=smoothstep(.30,.76,n)*edge*.34;
}
