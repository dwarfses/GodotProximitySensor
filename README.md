# GodotProximitySensor
<p>This addon uses&nbsp;a camera to estimate collision point, normal and color.</p>
<p>Tested on Godot 4.2</p>
<p>0.2 - Fixed some errors and visualization placement mistakes.</p>
<h4>Usage:</h4>
<p>After enabling the addon and added to the scene, you can use:<br><strong></strong>-&gt;<strong>&nbsp;get_collision_point()</strong> <em>returns Vector3</em><br>-&gt; <strong>get_collision_normal()</strong> <em>returns Vector3</em></p>
<p>-&gt; <strong>get_collision_color()</strong> <em>returns Color</em></p>
<p>-&gt;&nbsp;<strong>is_colliding()</strong><em> returns bool</em></p>
<p>but if you&nbsp;uncheck&nbsp;<strong>Enabled&nbsp;</strong>property&nbsp;of ProximitySensor node then you can only use <strong>await&nbsp;cast() </strong>which returns this Array-&gt;</p>
<p>&nbsp;[last_collision_point,last_collision_normal,last_collision_color,last_distance]</p>
<p>and you can use it like this-&gt;<br></p>
<p><strong>(await cast())[</strong><em>ProximitySensor.</em><strong>COLLISION_POINT_ID]</strong> returns <em>last_collision_point</em></p>
<p><strong>(await cast())[</strong><em>ProximitySensor.</em><strong>COLLISION_NORMAL_ID]&nbsp;</strong>&nbsp;returns <em>last_collision_normal</em></p>
<p><strong>(await cast())[</strong><em>ProximitySensor.</em><strong>COLLISION_COLOR_ID]&nbsp;</strong>&nbsp;returns <em>last_collision_color</em></p>
<p><strong>(await cast())[</strong><em>ProximitySensor.</em><strong>DISTANCE_ID]&nbsp;</strong>&nbsp;returns<em> last_distance</em> (distance between proximity sensor node and collision point.)</p>
<p><br></p>
<p><strong>Target Position</strong><strong></strong> property works exactly like RayCast3D node.<br>With <strong>Cull Mask</strong> property you can discard collision for selected 3d models by changing render layer.<span></span><strong><br></strong></p>
<h4>Examples:&nbsp;</h4>
<pre>
$ProximitySensor.get_collision_point()</pre>
<p><strong>Equals to</strong> (But the upper one returns null if the node is deactivated. The below one will return the last measured value)&nbsp;:</p>
<pre>
$ProximitySensor.last_collision_point</pre>
<p>if <strong><em>Enabled </em></strong>property unchecked:</p>
<pre>
(await $ProximitySensor.cast())[ProximitySensor.COLLISION_POINT_ID]</pre>
<pre>
var results = await $ProximitySensor.cast()
results[ProximitySensor.COLLISION_COLOR_ID]
results[ProximitySensor.COLLISION_POINT_ID]
..</pre>
