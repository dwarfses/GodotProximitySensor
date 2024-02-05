@tool
class_name ProximitySensor
extends Node3D
@export var enabled:bool = true
@export var target_position:Vector3 = Vector3(0,-1,0):
	set(a):
		target_position=a
		if !_is_ready:
			await ready
		
		var from= global_transform.origin
		var to = global_basis*a
		
		var dist = Vector3.ZERO.distance_to(a)
		_camera_far=dist
		_camera_3d.far=dist
		_look(_camera_3d,from+to)
@export_flags_3d_render var cull_mask:int = 1:
	set(a):
		if a > 524287 && await _check_vis():
			a -= 524288#layer 20 for visualization
		cull_mask=a
		if !_is_ready:
			await ready
		_camera_3d.cull_mask=a
@export_group("Debug Visualizer")
const VISUALIZE_ALWAYS:int = 0
const VISUALIZE_EDITOR_AND_DEBUG:int = 1
const VISUALIZE_EDITOR:int = 2
const VISUALIZE_DISABLED:int=3
@export_enum("Always","Editor&Debug(Visible Collision Shapes)","Editor","Disabled") var Visualize:int=VISUALIZE_EDITOR_AND_DEBUG:
	set(a):
		Visualize = a
		if !_is_ready:
			await ready
		if await _check_vis(a):
			if !_is_vis:
				_setup_visualization()
		else:
			if _is_vis:
				_disable_visualization()
		cull_mask=cull_mask
@export_range(10.,150.) var Visualization_Thickness:float=100.:
	set(a):
		Visualization_Thickness=a
		if !_is_ready:
			pass
		if await _check_vis()&&_is_vis:
			_disable_visualization()
			_setup_visualization()
@export_color_no_alpha var ray_color:Color=Color(0, 0.6484, 1):
	set(a):
		ray_color=a
		if !_is_ready:
			await ready
		_ray_mat.set_shader_parameter("color",a)
@export_color_no_alpha var ray_hit_color:Color=Color(0.9569, 0.2353, 0.302)
@export_color_no_alpha var pointer_color:Color=Color(0.6,0.5,0.9):
	set(a):
		pointer_color=a
		if !_is_ready:
			await ready
		_pointer_mat.set_shader_parameter("color",a)
@onready var _camera_far:float=Vector3.ZERO.distance_to(target_position)
@onready var _overlay_gdshader:Shader=preload("overlay.gdshader")
@onready var _overlay_material:ShaderMaterial
@onready var _cam_overlay_shader:Shader
@onready var _sub_viewport: SubViewport
@onready var _camera_3d: Camera3D
const _camera_near:float = 0.005

func _setup_subviewport_camera_overlay():
	_overlay_material=ShaderMaterial.new()
	_overlay_material.shader=_overlay_gdshader
	_sub_viewport=SubViewport.new()
	_sub_viewport.size=Vector2(3,3)
	_sub_viewport.render_target_update_mode= SubViewport.UPDATE_ONCE
	_sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	_sub_viewport.handle_input_locally=false
	_sub_viewport.debug_draw=Viewport.DEBUG_DRAW_UNSHADED
	
	_sub_viewport.positional_shadow_atlas_size=0
	_sub_viewport.positional_shadow_atlas_quad_0=Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	_sub_viewport.positional_shadow_atlas_quad_1=Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	_sub_viewport.positional_shadow_atlas_quad_2=Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	_sub_viewport.positional_shadow_atlas_quad_3=Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	_sub_viewport.use_occlusion_culling=true
	add_child(_sub_viewport)
	
	var env: Environment=Environment.new()
	_camera_3d=Camera3D.new()
	_camera_3d.projection=Camera3D.PROJECTION_ORTHOGONAL
	_camera_3d.size=0.005
	_camera_3d.near=_camera_near
	_camera_3d.environment=env
	_sub_viewport.add_child(_camera_3d)
	_camera_3d.position=Vector3.ZERO
	_camera_3d.rotation=Vector3.ZERO
	_camera_3d.cull_mask = cull_mask
	
	#overlay
	var cam_overlay:MeshInstance3D = MeshInstance3D.new()
	var overlay_mesh:QuadMesh = QuadMesh.new()
	cam_overlay.mesh=overlay_mesh
	overlay_mesh.material=_overlay_material
	overlay_mesh.size = Vector2.ONE*0.005
	_camera_3d.add_child(cam_overlay)
	cam_overlay.position =Vector3(0.,0., -_camera_near-0.0001)
	cam_overlay.rotation=Vector3.ZERO
	cam_overlay.layers=1048575


#region Setup_Visualization
var _body:MeshInstance3D
var _endpoint:MeshInstance3D
var _arrow:MeshInstance3D
var _startpoint:MeshInstance3D
var _arrowbody:MeshInstance3D
var _arrow_head:CSGCylinder3D
var _ray_mesh:CylinderMesh
var _sphere_mesh:SphereMesh
var _ray_mat:ShaderMaterial
var _pointer_mat:ShaderMaterial
var _vis_shader:Shader
var _is_vis:bool=false
func _disable_visualization():
	_body.queue_free()
	_endpoint.queue_free()
	_arrow.queue_free()
	_startpoint.queue_free()
	_arrowbody.queue_free()
	_arrow_head.queue_free()
	_is_vis=false
func _setup_visualization():
	
	_vis_shader=Shader.new()
	_vis_shader.code="""shader_type spatial; render_mode cull_back;uniform vec3 color: source_color= vec3(1.);void fragment() {ALBEDO = color.xyz;EMISSION=color.xyz/2.;}"""
	_body=MeshInstance3D.new()
	_endpoint=MeshInstance3D.new()
	_arrow=MeshInstance3D.new()
	_startpoint=MeshInstance3D.new()
	_arrowbody=MeshInstance3D.new()
	_arrow_head= CSGCylinder3D.new()
	_ray_mesh=CylinderMesh.new()
	_sphere_mesh=SphereMesh.new()
	
	_sphere_mesh.radial_segments=15
	_sphere_mesh.rings=15
	_sphere_mesh.radius=0.007*(Visualization_Thickness/100)
	_sphere_mesh.height=_sphere_mesh.radius*2

	
	_ray_mat=ShaderMaterial.new()
	_ray_mat.shader=_vis_shader
	_ray_mat.set_shader_parameter("color",ray_color)
	
	_pointer_mat=ShaderMaterial.new()
	_pointer_mat.shader=_vis_shader
	_pointer_mat.set_shader_parameter("color",pointer_color)


	_startpoint.mesh=_sphere_mesh
	_startpoint.set_surface_override_material(0,_ray_mat)
	_camera_3d.add_child(_startpoint)
	_startpoint.position=Vector3.ZERO-Vector3(0.,0.,_camera_near)
	_startpoint.rotation=Vector3.ZERO
	

	_endpoint.mesh=_sphere_mesh
	_endpoint.set_surface_override_material(0,_ray_mat)
	_camera_3d.add_child(_endpoint)
	_endpoint.position=Vector3.ZERO
	
	_ray_mesh.top_radius=0.003*(Visualization_Thickness/100)
	_ray_mesh.bottom_radius=0.0015*(Visualization_Thickness/100)
	_ray_mesh.height=_camera_far-_camera_near
	_ray_mesh.radial_segments=6
	_ray_mesh.rings=1
	
	_body.mesh=_ray_mesh
	_body.set_surface_override_material(0,_ray_mat)
	_camera_3d.add_child(_body)
	_body.position=Vector3.ZERO
	_body.rotation_degrees=Vector3(90,0,0)

	
	_arrow.mesh=_sphere_mesh.duplicate()
	_arrow.mesh.radius+=0.002*(Visualization_Thickness/100)
	_arrow.mesh.height=_arrow.mesh.radius*2
	_arrow.set_surface_override_material(0,_pointer_mat)
	_camera_3d.add_child(_arrow)

	_arrow.position=Vector3.ZERO
	_arrow.rotation_degrees=Vector3(90,0,0)

	_arrow_head.radius=0.02*(Visualization_Thickness/100)
	var arrow_head_size =0.04*(Visualization_Thickness/100)
	_arrow_head.height=arrow_head_size
	_arrow_head.sides=4
	_arrow_head.cone=true
	_arrow_head.smooth_faces=false
	_arrow_head.material=_pointer_mat
	_arrow.add_child(_arrow_head)
	var arrow_head_height = 0.15*(Visualization_Thickness/100)
	_arrow_head.position=Vector3(0,0,-arrow_head_height)
	_arrow_head.rotation_degrees=Vector3(-90,0,0)

	var arrowbody_height = arrow_head_height-(arrow_head_size/2)
	_arrowbody.mesh=_ray_mesh.duplicate()
	_arrowbody.mesh.height=arrowbody_height
	_arrowbody.set_surface_override_material(0,_pointer_mat)
	_arrow.add_child(_arrowbody)
	_arrowbody.position=Vector3(0,0,-(arrowbody_height/2))
	_arrowbody.rotation_degrees=Vector3(90,0,0)

	_startpoint.layers=524288
	_startpoint.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_endpoint.layers=524288
	_endpoint.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.layers=524288
	_body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arrow.layers=524288
	_arrow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arrowbody.layers=524288
	_arrowbody.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arrow_head.layers=524288
	_arrow_head.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_is_vis=true

func _update_visualization(_hitpoint,_normaldirection):
	_endpoint.position.z = -_camera_far
	var camfar=_camera_far-_camera_near
	_ray_mesh.height = camfar
	if !is_equal_approx((-_body.position.z/2.),camfar/2.+_camera_near):
		_body.position.z = -camfar/2.-_camera_near
	_arrow.global_position = _hitpoint
	if _normaldirection.is_equal_approx(Vector3.ZERO):
		_look(_arrow,_hitpoint+_camera_3d.global_basis*Vector3.FORWARD)
	else:
		_look(_arrow,_hitpoint+_normaldirection)
#endregion


func _look(it:Node3D,to:Vector3):
	if (it.position-to)!=Vector3.ZERO:
		if !abs(((it.global_position)-to).normalized()).is_equal_approx(Vector3.UP):
			it.look_at(to)
		else:
			it.look_at(to,Vector3.RIGHT)

func _check_vis(a=Visualize)->bool:
	if !_is_ready:
		await ready
	if a==0:
		return true
	else:
		if a !=3:
			if a==1:
				if Engine.is_editor_hint() || get_tree().debug_collisions_hint:
					return true
				else :
					return false
			else:
				if Engine.is_editor_hint():
					return true
				else:
					return false
		else:
			return false

var _is_ready:bool = false

func _ready() -> void:
	
	_is_ready=true
	_setup_subviewport_camera_overlay()
	if await _check_vis():
		_setup_visualization()


func _color_to_vec3(a:Color)->Vector3:
	return Vector3(a.r,a.g,a.b)
func _color_to_vec3_snap(a:Color)->Vector3:
	return Vector3(snapped(a.r,0.01),snapped(a.g,0.01),snapped(a.b,0.01))
func _add_vec3(a:Vector3)->float:
	return a.x+a.y+a.z
var _pixel_coords=[Vector2(0,0),Vector2(1,0),Vector2(2,0),Vector2(0,1),Vector2(1,1),Vector2(2,1),Vector2(0,2),Vector2(1,2),Vector2(2,2)]
func _get_pixel(a:int,texture:Image)->Color:
	return texture.get_pixel(_pixel_coords[a].x,_pixel_coords[a].y).srgb_to_linear()


var last_collision_point:Vector3
var last_collision_color:Color
var last_collision_normal:Vector3
var last_distance:float=0


const COLLISION_POINT_ID:int=0
const COLLISION_NORMAL_ID:int=1
const COLLISION_COLOR_ID:int=2
const DISTANCE_ID:int=3

func cast()->Array:
	if _camera_3d.far !=_overlay_material.get("shader_parameter/camfar"):
		_camera_3d.far=_camera_far
		_overlay_material.set("shader_parameter/camfar",_camera_far)
	_camera_3d.global_position=self.global_position+global_basis*Vector3(0,_camera_near,0)
	_look(_camera_3d,global_transform.origin+global_basis*target_position)
	_sub_viewport.render_target_update_mode= SubViewport.UPDATE_ONCE
	await  RenderingServer.frame_post_draw
	var texture:Image =_sub_viewport.get_texture().get_image()
	last_distance=0
	for i in 7:
		last_distance+= _add_vec3(_color_to_vec3(_get_pixel(i,texture)))
	last_distance = (last_distance/3.)*(_camera_far/7.)-_camera_near
	last_collision_point=global_position+_camera_3d.global_basis*Vector3(0.,0.,-last_distance)

	last_collision_color=_get_pixel(8,texture)
	last_collision_normal=_color_to_vec3_snap(_get_pixel(7,texture))*2.-Vector3.ONE
	if await _check_vis():
		_update_visualization(last_collision_point,last_collision_normal)
		if is_colliding():
			_ray_mat.set_shader_parameter("color",ray_hit_color)
		else:
			_ray_mat.set_shader_parameter("color",ray_color)
	return [last_collision_point,last_collision_normal,last_collision_color,last_distance]

func get_collision_point():
	if enabled && is_colliding():
		return last_collision_point
	else:
		return null
func get_collision_normal():
	if enabled && is_colliding():
		return last_collision_normal
	else:
		return null
func get_collision_color():
	if enabled && is_colliding():
		return last_collision_color
	else:
		return null
func is_colliding()->bool:
	if enabled:
		if is_equal_approx(last_distance,_camera_far-_camera_near):
			return false
		else:
			return true
	else:
		return false

func _process(delta: float) -> void:

	if enabled:
		cast()



