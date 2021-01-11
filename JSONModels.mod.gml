#define init
//Editor Setup
chat_comp_add("import", "path to file");
global.model = "";
//Setup();
//3D Setup
#define Setup(json, modelPath, texPath)
{
global.ready = false;

if(!lq_exists(json, "textures")){
	json.textures = {};
}
if(!lq_exists(json, "elements")){
	json.elements = [];
}
while(lq_exists(json, "parent") && json.parent != ""){
	parent = json.parent;
	json.parent = "";
	wait(file_load(modelPath + parent + ".json"));
	while(!file_loaded(modelPath + parent + ".json")){wait 0}
	if(file_exists(modelPath + parent + ".json")){
		var pjson = string_load(modelPath + parent + ".json");
		if(!is_undefined(pjson) && string_length(pjson) > 0){
			pjson = json_decode(pjson);
			if(lq_exists(pjson, "parent") && pjson.parent != ""){
				json.parent = pjson.parent;
			}
			if(lq_exists(pjson, "textures")){
				for(var i = 0; i < lq_size(pjson.textures); i++){
					if(!lq_exists(json.textures, lq_get_key(pjson.textures, i))){
						lq_set(json.textures, lq_get_key(pjson.textures, i), lq_get_value(pjson.textures, i));
					}
				}
			}
			if(lq_exists(pjson, "elements")){
				array_copy(json.elements, array_length(json.elements), pjson.elements, 0, array_length(pjson.elements))
			}
		}
	}
}

// [This part of the code is from Abstractor's example, I'm stealing it thanks - GE]
var spr = [];
for(var i = 0; i < lq_size(json.textures); i++){
	while(string_char_at(lq_get_value(json.textures, i), 0) == "#"){
		lq_set(json.textures, lq_get_key(json.textures, i), lq_defget(json.textures, string_copy(lq_get_value(json.textures, i), 2, string_length(lq_get_value(json.textures, i)) - 1), "ERROR"));
	}
	array_push(spr, sprite_add(texPath + lq_get_value(json.textures, i)+".png", 1, 0, 0)); // don't use subimages, it will not work, every subimage is on its own texture page
}

// coming up is GM's default vertex buffer format, used by the default shader
vertex_format_begin();
vertex_format_add_position_3d(); // vertex 3d position
vertex_format_add_color(); // this is what image_blend and image_alpha go into
vertex_format_add_texcoord(); // UV coordinates
var vertex_format = vertex_format_end();

var vertex_buffer = [];
for(var j = 0; j < lq_size(json.textures); j++){
	// this will be our mesh
	var vbuf = vertex_create_buffer();
	vertex_begin(vbuf, vertex_format);
	wait(0);
	// these functions only work one frame later
	var spritetex = sprite_get_texture(spr[j], 0);
	var texsize = [texture_get_width(spritetex), texture_get_height(spritetex)];
	/* 
	The point of texture_get_width/height is this:
	Graphics cards only work with textures with width and height a power of 2.
	As an example, say this sprite is 48x8, it would actually be assigned to a texture of 64x8.
	So on the texture, the sprite only covers UV coordinates (0,0) to (0.75, 1).
	The latter numbers are what texture_get_width/height return.
	*/
	for(var i = 0; i < array_length(json.elements); i++){
		for(var i2 = 0; i2 < lq_size(json.elements[i].faces); i2++){
			if(is_object(lq_get_value(json.elements[i].faces, i2))){
				while(string_char_at(lq_get_value(json.elements[i].faces, i2).texture, 0) == "#"){
					lq_get_value(json.elements[i].faces, i2).texture = lq_defget(json.textures, string_copy(lq_get_value(json.elements[i].faces, i2).texture, 2, string_length(lq_get_value(json.elements[i].faces, i2).texture) - 1), "ERROR");
				}
				if(lq_get_value(json.elements[i].faces, i2).texture != lq_get_value(json.textures, j)){
					continue;
				}
				if(!lq_exists(lq_get_value(json.elements[i].faces, i2), "uv") || !is_array(lq_get_value(json.elements[i].faces, i2).uv)){
					lq_get_value(json.elements[i].faces, i2).uv = [json.elements[i].from[0], json.elements[i].from[1], json.elements[i].to[0], json.elements[i].to[1]];
				}
				var coords = [
					[0,0,0],
					[0,0,0],
					[0,0,0],
					[0,0,0]
				];
				switch(lq_get_key(json.elements[i].faces, i2)){
					case "north":
						coords[0][@0] = json.elements[i].from[0];
						coords[0][@1] = json.elements[i].from[1];
						coords[0][@2] = json.elements[i].from[2];
						
						coords[1][@0] = json.elements[i].to[0];
						coords[1][@1] = json.elements[i].from[1];
						coords[1][@2] = json.elements[i].from[2];
						
						coords[2][@0] = json.elements[i].to[0];
						coords[2][@1] = json.elements[i].to[1];
						coords[2][@2] = json.elements[i].from[2];
						
						coords[3][@0] = json.elements[i].from[0];
						coords[3][@1] = json.elements[i].to[1];
						coords[3][@2] = json.elements[i].from[2];
						break;
					case "south":
						coords[0][@0] = json.elements[i].from[0];
						coords[0][@1] = json.elements[i].from[1];
						coords[0][@2] = json.elements[i].to[2];
						
						coords[1][@0] = json.elements[i].to[0];
						coords[1][@1] = json.elements[i].from[1];
						coords[1][@2] = json.elements[i].to[2];
						
						coords[2][@0] = json.elements[i].to[0];
						coords[2][@1] = json.elements[i].to[1];
						coords[2][@2] = json.elements[i].to[2];
						
						coords[3][@0] = json.elements[i].from[0];
						coords[3][@1] = json.elements[i].to[1];
						coords[3][@2] = json.elements[i].to[2];
						break;
					case "east":
						coords[0][@0] = json.elements[i].to[0];
						coords[0][@1] = json.elements[i].from[1];
						coords[0][@2] = json.elements[i].from[2];
						
						coords[1][@0] = json.elements[i].to[0];
						coords[1][@1] = json.elements[i].to[1];
						coords[1][@2] = json.elements[i].from[2];
						
						coords[2][@0] = json.elements[i].to[0];
						coords[2][@1] = json.elements[i].to[1];
						coords[2][@2] = json.elements[i].to[2];
						
						coords[3][@0] = json.elements[i].to[0];
						coords[3][@1] = json.elements[i].from[1];
						coords[3][@2] = json.elements[i].to[2];
						break;
					default:
					case "west":
						coords[0][@0] = json.elements[i].from[0];
						coords[0][@1] = json.elements[i].from[1];
						coords[0][@2] = json.elements[i].from[2];
						
						coords[1][@0] = json.elements[i].from[0];
						coords[1][@1] = json.elements[i].to[1];
						coords[1][@2] = json.elements[i].from[2];
						
						coords[2][@0] = json.elements[i].from[0];
						coords[2][@1] = json.elements[i].to[1];
						coords[2][@2] = json.elements[i].to[2];
						
						coords[3][@0] = json.elements[i].from[0];
						coords[3][@1] = json.elements[i].from[1];
						coords[3][@2] = json.elements[i].to[2];
						break;
					default:
					case "up":
						coords[0][@0] = json.elements[i].from[0];
						coords[0][@1] = json.elements[i].to[1];
						coords[0][@2] = json.elements[i].from[2];
						
						coords[1][@0] = json.elements[i].to[0];
						coords[1][@1] = json.elements[i].to[1];
						coords[1][@2] = json.elements[i].from[2];
						
						coords[2][@0] = json.elements[i].to[0];
						coords[2][@1] = json.elements[i].to[1];
						coords[2][@2] = json.elements[i].to[2];
						
						coords[3][@0] = json.elements[i].from[0];
						coords[3][@1] = json.elements[i].to[1];
						coords[3][@2] = json.elements[i].to[2];
						break;
					case "down":
						coords[0][@0] = json.elements[i].from[0];
						coords[0][@1] = json.elements[i].from[1];
						coords[0][@2] = json.elements[i].from[2];
						
						coords[1][@0] = json.elements[i].to[0];
						coords[1][@1] = json.elements[i].from[1];
						coords[1][@2] = json.elements[i].from[2];
						
						coords[2][@0] = json.elements[i].to[0];
						coords[2][@1] = json.elements[i].from[1];
						coords[2][@2] = json.elements[i].to[2];
						
						coords[3][@0] = json.elements[i].from[0];
						coords[3][@1] = json.elements[i].from[1];
						coords[3][@2] = json.elements[i].to[2];
						break;
					default:
						trace(lq_get_key(json.elements[i].faces, i2));
				}
				if(lq_exists(json.elements[i], "rotation")){
					switch(json.elements[i].rotation.axis){
						case "x":
							for(var i3 = 0; i3 < array_length(coords); i3++){
								coords[i3][@0] -= json.elements[i].rotation.origin[0];
								coords[i3][@1] -= json.elements[i].rotation.origin[1];
								coords[i3][@2] -= json.elements[i].rotation.origin[2];
								coords[i3][@1] = coords[i3][@1] * dcos(json.elements[i].rotation.angle) - coords[i3][@2] * dsin(json.elements[i].rotation.angle);
								coords[i3][@2] = coords[i3][@1] * dsin(json.elements[i].rotation.angle) + coords[i3][@2] * dcos(json.elements[i].rotation.angle);
								coords[i3][@0] += json.elements[i].rotation.origin[0];
								coords[i3][@1] += json.elements[i].rotation.origin[1];
								coords[i3][@2] += json.elements[i].rotation.origin[2];
							}
							break;
						case "y":
							for(var i3 = 0; i3 < array_length(coords); i3++){
								coords[i3][@0] -= json.elements[i].rotation.origin[0];
								coords[i3][@1] -= json.elements[i].rotation.origin[1];
								coords[i3][@2] -= json.elements[i].rotation.origin[2];
								coords[i3][@0] = coords[i3][@0] * dcos(json.elements[i].rotation.angle) + coords[i3][@2] * dsin(json.elements[i].rotation.angle);
								coords[i3][@2] = -coords[i3][@0] * dsin(json.elements[i].rotation.angle) + coords[i3][@2] * dcos(json.elements[i].rotation.angle);
								coords[i3][@0] += json.elements[i].rotation.origin[0];
								coords[i3][@1] += json.elements[i].rotation.origin[1];
								coords[i3][@2] += json.elements[i].rotation.origin[2];
							}
							break;
						case "z":
							for(var i3 = 0; i3 < array_length(coords); i3++){
								coords[i3][@0] -= json.elements[i].rotation.origin[0];
								coords[i3][@1] -= json.elements[i].rotation.origin[1];
								coords[i3][@2] -= json.elements[i].rotation.origin[2];
								coords[i3][@0] = coords[i3][@0] * dcos(json.elements[i].rotation.angle) - coords[i3][@1] * dsin(json.elements[i].rotation.angle);
								coords[i3][@1] = coords[i3][@0] * dsin(json.elements[i].rotation.angle) + coords[i3][@1] * dcos(json.elements[i].rotation.angle);
								coords[i3][@0] += json.elements[i].rotation.origin[0];
								coords[i3][@1] += json.elements[i].rotation.origin[1];
								coords[i3][@2] += json.elements[i].rotation.origin[2];
							}
							break;
					}
				}
				
				vertex_position_3d(vbuf, coords[0][0]-8, coords[0][1]-8, coords[0][2]-8);
				vertex_color(vbuf, c_white, 1);
				vertex_texcoord(vbuf, lq_get_value(json.elements[i].faces, i2).uv[0]/16, lq_get_value(json.elements[i].faces, i2).uv[1]/16);
				vertex_position_3d(vbuf, coords[1][0]-8, coords[1][1]-8, coords[1][2]-8);
				vertex_color(vbuf, c_white, 1);
				vertex_texcoord(vbuf, lq_get_value(json.elements[i].faces, i2).uv[2]/16, lq_get_value(json.elements[i].faces, i2).uv[1]/16);
				vertex_position_3d(vbuf, coords[2][0]-8, coords[2][1]-8, coords[2][2]-8);
				vertex_color(vbuf, c_white, 1);
				vertex_texcoord(vbuf, lq_get_value(json.elements[i].faces, i2).uv[2]/16, lq_get_value(json.elements[i].faces, i2).uv[3]/16);
				vertex_position_3d(vbuf, coords[2][0]-8, coords[2][1]-8, coords[2][2]-8);
				vertex_color(vbuf, c_white, 1);
				vertex_texcoord(vbuf, lq_get_value(json.elements[i].faces, i2).uv[2]/16, lq_get_value(json.elements[i].faces, i2).uv[3]/16);
				vertex_position_3d(vbuf, coords[3][0]-8, coords[3][1]-8, coords[3][2]-8);
				vertex_color(vbuf, c_white, 1);
				vertex_texcoord(vbuf, lq_get_value(json.elements[i].faces, i2).uv[0]/16, lq_get_value(json.elements[i].faces, i2).uv[3]/16);
				vertex_position_3d(vbuf, coords[0][0]-8, coords[0][1]-8, coords[0][2]-8);
				vertex_color(vbuf, c_white, 1);
				vertex_texcoord(vbuf, lq_get_value(json.elements[i].faces, i2).uv[0]/16, lq_get_value(json.elements[i].faces, i2).uv[1]/16);
			}
		}
	}
	vertex_end(vbuf);
	array_push(vertex_buffer, vbuf);
}
var model = {};
model.spr = spr;
model.vb = vertex_buffer;
return model;
}
#define draw
if(global.model == "") exit;
//var surf = surface_create(100,100);
//surface_set_target(surf)
//drawModel(50, 50, [current_frame,0,current_frame], global.model);
//surface_reset_target()
//with(Player){draw_surface(surf, x, y);}
with(Player){drawModel(x, y, [current_frame,0,current_frame], global.model);}
#define drawModel(_x,_y,rot,model)
{
d3d_start();

//d3d_set_culling(true); // <-- if you enable this you'll see some triangles face the wrong way, so let's not turn it on
// if you don't disable it at the end, it'll also mess up drawing the rest of the game, by the way (flipped sprites for instance)

//d3d_set_projection_ortho(view_xview_nonsync, view_yview_nonsync, game_width, game_height, 0); // as far as I know this is the standard projection
for(var i = 0; i < 10; i++){
	d3d_transform_set_identity();
	d3d_transform_set_scaling(1, 1, 1); // scaling
	// try different numbers for x,y,z, for a squashed cube (or "hyperrectangle" or "rectangular cuboid" or "3-orthotope")
	
	// now some example rotation
	// note that in the default projection the z-axis is the one orthogonal to the screen, and you're looking in the positive z-direction
	// (so vertices with negative z-values appear first, just like with depth)
	d3d_transform_add_rotation_x(rot[0]);
	d3d_transform_add_rotation_y(rot[1]);
	d3d_transform_add_rotation_z(rot[2]);
	
	// note that the order in which scaling, rotation, and translation is applied is important
	// scaling and rotation are always applied relative to the origin (0,0,0)
	// generally speaking you'll want to scale first, rotate next, translate last
	
	d3d_transform_add_translation(_x, _y, 0);
	for(var i2 = 0; i2 < array_length(model.vb) && i2 < array_length(model.spr); i2++){
		vertex_submit(model.vb[i2], pr_trianglelist, sprite_get_texture(model.spr[i2], 0)); // draw
	}
}
		
d3d_transform_set_identity(); // <-- important
	
//d3d_set_culling(false);

d3d_end();
}

#define drawModelRaw(model)
{
	for(var i = 0; i < 10; i++){
		for(var i2 = 0; i2 < array_length(model.vb) && i2 < array_length(model.spr); i2++){
			vertex_submit(model.vb[i2], pr_trianglelist, sprite_get_texture(model.spr[i2], 0)); // draw
		}
	}
}

#define chat_command(command, parameter, player)
if(command == "import"){
	loadModel(parameter, array_length(string_split(parameter, "/")) > 1 ? string_split(parameter, "/")[0]+"/" : "", array_length(string_split(parameter, "/")) > 1 ? string_split(parameter, "/")[0]+"/" : "");
	return true;
}
#define loadModel(imp, modelPath, texPath)
if(fork()){
	wait(file_load(imp));
	while(!file_loaded(imp)){wait 0}
	if(file_exists(imp)){
		var json = string_load(imp);
		if(!is_undefined(json) && string_length(json) > 0){
			json = json_decode(json);
			trace(imp + " loaded.");
			global.model = Setup(json, modelPath, texPath);
		}else{
			trace(imp + " not found.");
		}
	}else{
		trace(imp + " not found.");
	}
}