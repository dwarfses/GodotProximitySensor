shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_opaque;

uniform sampler2D depth_texture : source_color, hint_depth_texture,filter_nearest;
uniform sampler2D normal_roughness_texture : source_color, hint_normal_roughness_texture,filter_nearest;
uniform sampler2D screen_texture : source_color, hint_screen_texture,filter_nearest;
uniform float camfar=7.;
varying mat4 camera;

uniform ivec2 camera_size = ivec2(2,2);

void vertex(){camera = inverse(transpose(MODEL_MATRIX));}

vec3 pixels(vec2 uv ,vec3 one, vec3 two, vec3 three, vec3 four, vec3 five, vec3 six, vec3 seven, vec3 eight, vec3 nine){
	 return	uv.y<=1.?(uv.x<=1.?one:(uv.x<=2.?two:(uv.x<=3.?three:vec3(0.)))):(uv.y<=2.?(uv.x<=1.?four:(uv.x<=2.?five:(uv.x<=3.?six:vec3(0.)))):(uv.y<=3.?(uv.x<=1.?seven:(uv.x<=2.?eight:(uv.x<=3.?nine:vec3(0.)))):vec3(0.))); }
vec3 split_value(float value) { return clamp(value*3. - vec3(0.00f, 1.00f, 2.00f), 0.00f, 1.00f); }
void fragment() {
	vec2 uv = (SCREEN_UV* 3.);//repeat texture 9 times.
	vec4 nrt =texture(normal_roughness_texture,uv);
	nrt.xyz=(camera*vec4(nrt.xyz*2.-1.,0.)).xyz ;
	nrt.xyz=(nrt.xyz+1.)/2.;
	vec3 st =( texture(screen_texture,uv)).xyz;
	float depth = texture(depth_texture, uv).x;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	const int depth_pixels=7;
	linear_depth = linear_depth / (camfar / float(depth_pixels)); // 0 to 6 range
	vec3 s[depth_pixels] ;
	for (int i = 0; i < depth_pixels; i++) {
		s[i] = split_value(max(linear_depth - float(i), 0.0));
	}
	ALBEDO=pixels(uv,
	s[0],    s[1],    s[2],
	s[3],    s[4],    s[5],
	s[6],    nrt.xyz, st   );
	ALPHA *= clamp(smoothstep(0.02, 0.0, length(VERTEX)), 0.0, 1.0);//distance fade
	ALPHA_SCISSOR_THRESHOLD= 0.5;
}