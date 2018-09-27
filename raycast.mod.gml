#define init
#macro UNIFORMSTART 7
#macro VERSION 2.0

global.FOV = 120;
global.view_dist = 300;
// note: the view is not a frustrum or a triangle: it is a sector (of a circle)
// this makes some things harder, but it improves the fog effect
global.batch_size = 16;

global.camera = 0;
global.camera_x = 10016;
global.camera_y = 10016;
global.camera_angle = 0;
global.camera_angle_v = 0;
global.camera_height = 20;
global.grav = 1.3;
global.jump_height = 10;
global.jump_invincibility = false;
global.wall_height = 1.5;
global.popo_shield_height = 1.5;

global.surfFloor = -1;
global.surfFloorW = 2000;
global.surfFloorH = 2000;
global.surfShadows = -1;

global.surfCeil = -1;
global.surfCeilW = 2000;
global.surfCeilH = 2000;

// in lieu of automatically scaling surfaces
global.display_res = [1920/5, 1080/5];
game_set_size(global.display_res[0], global.display_res[1]);

// surfaces
global.drawsurf = -1; // the paintbrush
global.viewsurf = -1; // the canvas
global.planesurf = -1; // plane optimization

//vertex shader
global.sh_vertex = "
	struct VertexShaderInput
	{
		float4 vPosition : POSITION;
		float2 vTexcoord : TEXCOORD0;
	};

	struct VertexShaderOutput
	{
		float4 vPosition : SV_POSITION;
		float2 vTexcoord : TEXCOORD0;
	};

	float4x4 matrix_world_view_projection;
	
	VertexShaderOutput main(VertexShaderInput INPUT)
	{
		VertexShaderOutput OUT;

		OUT.vPosition = mul(matrix_world_view_projection, INPUT.vPosition); // (x,y,z,w)
		OUT.vTexcoord = INPUT.vTexcoord;
		
		return OUT;
	}
";

// shared fragment shader code
global.sh_includes = "
	struct PixelShaderInput {
		float2 vTexcoord : TEXCOORD0;
	};
	
	sampler2D s0; // unmodifiable
	sampler2D sampleTex : register(ps, s[1]); // thing to be drawn
	sampler2D renderTex : register(ps, s[2]); // canvas
	
	uniform float3 cameraLoc : register(ps, c[0]);
	uniform float2 cameraDir : register(ps, c[1]);
	uniform float cameraFOV : register(ps, c[2]);
	uniform float cameraAspect : register(ps, c[3]);
	uniform float3 fogColor : register(ps, c[4]);
	uniform float viewDist : register(ps, c[5]);
	
	uniform float2 texSize : register(ps, c[6]);
	
	float3 rotateZ(float3 vec, float anglez, float angley) {
		float csy = cos(angley);
		float sny = sin(angley);
		float3 tvec = float3(vec.x * csy - vec.z * sny, vec.y, vec.x * sny + vec.z * csy);
		float csz = cos(anglez);
		float snz = sin(anglez);
		return float3(tvec.x * csz - tvec.y * snz, tvec.x * snz + tvec.y * csz, tvec.z);
	}
	
	// okay, so emulating a z-buffer is going to be tricky, because we don't have access to the right texture format
	// we'll have to manually embed floats in the pixels of a normalized-integer RGBA texture
	// these two functions should be exact inverses
	
	float4 depthToPixel(float depth) {
		float d = (depth/viewDist);
		d *= 256;
		float rInt = min(255, floor(d));
		d = (d - rInt) * 256;
		float gInt = min(255, floor(d));
		d = (d - gInt) * 256;
		float bInt = min(255, floor(d));
		// there might not be enough precision in a float for this, but it shouldn't hurt
		return float4(rInt/255,gInt/255,bInt/255, 1.0);
	}
	
	float pixelToDepth(float4 pixel) {
		return viewDist*(pixel.r * 256 + pixel.g + pixel.b/256) / (256 + 1 + (1/256));
	}
";

// shader for surfaces (floors)
global.sh_frag = "
	
	$INCLUDES
	
	uniform float2 surfaceSize : register(ps, c[7]);
	uniform float3 location : register(ps, c[8]);
	
	const static float3 normal = float3(0, 0, 1);
	
	float4 main(PixelShaderInput INPUT) : SV_TARGET {
		float actualY = frac(2 * INPUT.vTexcoord.y);
		// rectilinear perspective
		float3 rayDir = normalize(rotateZ(float3(1.0, tan(cameraFOV) * 2 * (INPUT.vTexcoord.x - 0.5), tan(cameraFOV) * 2 * (0.5 - actualY) / cameraAspect), -cameraDir.x, -cameraDir.y));
		float rayDist = (location.z - cameraLoc.z) / rayDir.z;
		if (rayDist > 0 && rayDist < pixelToDepth(tex2D(renderTex, float2(INPUT.vTexcoord.x, (0.5 + actualY/2))))) {
			float3 intersect = cameraLoc + rayDist * rayDir;
			float2 coords = (intersect.xy - location.xy) / surfaceSize; // 0-1 coordinates in surface
			
			if(coords.x >= 0 && coords.x <= 1 && coords.y >= 0 && coords.y <= 1) {
				float4 sample = tex2D(sampleTex, coords * texSize);
				if(sample.a == 1){
					sample = float4(lerp(sample.rgb, fogColor, rayDist/viewDist), 1);
				}else if(sample.a > 0){
					sample = float4(lerp(sample.rgb, fogColor, abs(rayDist/viewDist))*sample.a, 1);
				}
				return (INPUT.vTexcoord.y > 0.5 && sample.a > 0) ? depthToPixel(rayDist) : sample;
			}
		}
		return float4(0.0, 0.0, 0.0, 0.0);
	}
";

// batch shader for "walls" (upright plane sections)
global.sh_frag_batch = "
	
	$INCLUDES
	
	struct TexPlane
	{
		float4 uvs;
		float4 uvData;
		float4 location; // w is angle
	};
	
	const static float3 defaultNormal = float3(0.0, 1.0, 0.0);
	const static float3 defaultXAxis = float3(1.0, 0.0, 0.0);
	const static float3 defaultYAxis = float3(0.0, 0.0, -1.0);
	
	uniform int BATCH_SIZE : register(ps, c[7]);
	
	uniform TexPlane planes[$MAX_BATCH_SIZE] : register(ps, c[8]);
	
	float4 main(PixelShaderInput INPUT) : SV_TARGET {
		float actualY = frac(2 * INPUT.vTexcoord.y);
		// rectilinear perspective
		float3 rayDir = normalize(rotateZ(float3(1.0, tan(cameraFOV) * 2 * (INPUT.vTexcoord.x - 0.5), tan(cameraFOV) * 2 * (0.5 - actualY) / cameraAspect), -cameraDir.x, -cameraDir.y));
		
		float depth = pixelToDepth(tex2D(renderTex, float2(INPUT.vTexcoord.x, (0.5 + actualY/2))));
		float4 color = tex2D(renderTex, float2(INPUT.vTexcoord.x, actualY/2));
		
		for(int i = 0; i < BATCH_SIZE; i++) {
			float3 normal = rotateZ(defaultNormal, planes[i].location.w, 0);
			float3 xAxis = rotateZ(defaultXAxis, planes[i].location.w, 0);
			float3 yAxis = defaultYAxis;
			float rayDist = dot(planes[i].location.xyz - cameraLoc, normal) / dot(rayDir, normal);
			if (rayDist > 0 && rayDist < depth) {
				float3 intersect = cameraLoc + rayDist * rayDir;
				float2 planeCoords = float2(dot(xAxis, intersect - planes[i].location.xyz), dot(yAxis, intersect - planes[i].location.xyz));
				
				float2 spriteCoords = (planeCoords + planes[i].uvData.xy) / planes[i].uvData.zw; // 0-1 coordinates in trimmed sprite
				// for comprehension's sake, this was the original line:
				// float2 spriteCoords = (planeCoords/scale + sprOffset - uvData.xy) / (sprSize * uvData.zw);
				// recognizing the variables can be combined improves performance
				
				if(spriteCoords.x >= 0 && spriteCoords.x <= 1 && spriteCoords.y >= 0 && spriteCoords.y <= 1) {
					float2 uvCoords = planes[i].uvs.xy + spriteCoords * (planes[i].uvs.zw - planes[i].uvs.xy);
					float4 sample = tex2D(sampleTex, uvCoords * texSize);
					color.rgb = lerp(color.rgb, lerp(sample.rgb, fogColor, rayDist/viewDist), sample.a);
					depth = sample.a > 0 ? rayDist : depth;
				}
			}
		}
		return (INPUT.vTexcoord.y > 0.5) ? depthToPixel(depth) : color;
	}
";

compile_shaders();

trace("Type /globalset to set global variables, and /localset to set player variables. Type the commands by themselves to get help");

#define compile_shaders
	global.sh_comp = shader_create(global.sh_vertex, string_replace_all(global.sh_frag, "$INCLUDES", global.sh_includes));
	global.sh_comp_batch = shader_create(global.sh_vertex, string_replace_all(string_replace_all(global.sh_frag_batch, "$INCLUDES", global.sh_includes), "$MAX_BATCH_SIZE", string(global.batch_size)));

// PLANE API
//setup -> draw -> raycast
#define plane_setup
	surface_set_target(global.planesurf);
	draw_clear_alpha(c_black, 0);

#define plane_draw(sprite, subimage, _x, _y, _xscale, _yscale, _rot)
	draw_sprite_ext(sprite, subimage, _x - floor(global.camera_x - global.view_dist), _y - floor(global.camera_y - global.view_dist), _xscale, _yscale, _rot, c_white, 1)
	
#define plane_raycast(height)
	var tex = surface_get_texture(global.planesurf);
	var tex_size = [texture_get_width(tex), texture_get_height(tex)];
	
	texture_set_stage(1, tex);
	texture_set_stage(2, surface_get_texture(global.viewsurf));
	
	shader_set_fragment_constant_f(6, tex_size);
	shader_set_fragment_constant_f(7, [surface_get_width(global.planesurf), surface_get_height(global.planesurf)]);
	shader_set_fragment_constant_f(8, [floor(global.camera_x - global.view_dist), floor(global.camera_y - global.view_dist), height]);
	
	shader_set(global.sh_comp);
	surface_set_target(global.viewsurf);
	draw_surface(global.drawsurf, 0, 0);
	surface_reset_target();
	shader_reset();

// BATCH API
// init -> add -> finalize
#define batch_init(tex)
	global.batch_now = 0;
	global.uniform_index = UNIFORMSTART+1;
	texture_set_stage(1, tex);
	shader_set_fragment_constant_f(6, [texture_get_width(tex), texture_get_height(tex)]);

#define batch_add(sprite, subimage, _x, _y, _z, _rot, isWall, heightMult)
	var uvs = sprite_get_uvs(sprite, subimage);
	var spr_size = [sprite_get_width(sprite), sprite_get_height(sprite)*heightMult];
	var spr_offset = [sprite_get_xoffset(sprite), sprite_get_yoffset(sprite)];
	
	if (isWall) {
		uvs[0] = (uvs[0] + uvs[2]) / 2; 
		uvs[1] = (uvs[1] + uvs[3]) / 2;
	}
	
	shader_set_fragment_constant_f(global.uniform_index++, [uvs[0], uvs[1], uvs[2], uvs[3]]);
	shader_set_fragment_constant_f(global.uniform_index++, [spr_offset[0] - uvs[4], spr_offset[1] - uvs[5], spr_size[0] * uvs[6], spr_size[1] * uvs[7]]);
	shader_set_fragment_constant_f(global.uniform_index++, [_x, _y, _z*heightMult, degtorad(_rot)]);
	
	global.batch_now++;
	if global.batch_now == global.batch_size batch_raycast()
	
#define batch_raycast
	//trace("RAYCASTING", global.batch_now)
	texture_set_stage(2, surface_get_texture(global.viewsurf));
	shader_set_fragment_constant_i(UNIFORMSTART, [global.batch_now]);
	shader_set(global.sh_comp_batch);
	surface_set_target(global.viewsurf);
	draw_surface(global.drawsurf, 0, 0);
	surface_reset_target();
	shader_reset();
	
	global.batch_now = 0;
	global.uniform_index = UNIFORMSTART+1;
	
#define batch_finalize
	if global.batch_now > 0 batch_raycast()
	
#define chat_command
if(argument0 == "globalset") {
	switch(string_split(argument1, " ")[0]){
		case "FOV":
			global.FOV = real(string_split(argument1, " ")[1]);
			trace("FOV set to "+string_split(argument1, " ")[1]);
			break;
		case "view_dist":
			global.view_dist = real(string_split(argument1, " ")[1]);
			trace("view_dist set to "+string_split(argument1, " ")[1]);
			break;
		case "display_res":
			global.display_res = [real(string_split(argument1, " ")[1]),real(string_split(argument1, " ")[2])];
			game_set_size(global.display_res[0], global.display_res[1]);
			trace("display_res set to [" + global.display_res[0] + ", " + global.display_res[1] + "]");
			break;
		case "batch_size":
			global.batch_size = real(string_split(argument1, " ")[1]);
			trace("batch_size set to "+string_split(argument1, " ")[1]);
			break;
		case "camera_height":
			global.camera_height = real(string_split(argument1, " ")[1]);
			trace("camera_height set to "+string_split(argument1, " ")[1]);
			break;
		case "grav":
			global.grav = real(string_split(argument1, " ")[1]);
			trace("grav set to "+string_split(argument1, " ")[1]);
			break;
		case "jump_height":
			global.jump_height = real(string_split(argument1, " ")[1]);
			trace("jump_height set to "+string_split(argument1, " ")[1]);
			break;
		case "jump_invincibility":
			global.jump_invincibility = !global.jump_invincibility;
			trace("jump_invincibility " + (global.jump_invincibility ? "enabled" : "disabled"));
			break;
		case "wall_height":
			global.wall_height = real(string_split(argument1, " ")[1]);
			trace("wall_height set to "+string_split(argument1, " ")[1]);
			break;
		case "popo_shield_height":
			global.popo_shield_height = real(string_split(argument1, " ")[1]);
			trace("popo_shield_height set to "+string_split(argument1, " ")[1]);
			break;
		default:
		trace("Set a global variable. (format:[/globalset name value])
		Variables are:
		FOV (default: 120)
		view_dist (default: 300)
		display_res (default: 384, 216) (takes two variables separated by a space)
		batch_size (default: 16)
		camera_height (default: 20)
		grav (default: 0.3)
		jump_height (default: 2.5)
		jump_invincibility (default:false)
		wall_height (default: 3)
		popo_shield_height (default: 1.5)");
	}
	return 1;
}
if(argument0 == "localset") {
	switch(string_split(argument1, " ")[0]){
		case "jumping":
			player_find(argument2).jumping = !player_find(argument2).jumping;
			trace("jumping " + (player_find(argument2).jumping ? "enabled" : "disabled"));
			break;
		case "jump_button":
			player_find(argument2).jump_button = string_split(argument1, " ")[1];
			trace("jump_button set to "+string_split(argument1, " ")[1]);
			break;
		case "vertical":
			player_find(argument2).vertical = !player_find(argument2).vertical;
			trace("vertical looking " + (player_find(argument2).vertical ? "enabled" : "disabled"));
			break;
		case "control_style":
			player_find(argument2).control_style = !player_find(argument2).control_style;
			trace("control_style: " + (player_find(argument2).control_style ? "new" : "old"));
			break;
		case "base_turn_speed":
			player_find(argument2).base_turn_speed = real(string_split(argument1, " ")[1]);
			trace("base_turn_speed set to "+string_split(argument1, " ")[1]);
			break;
		case "edge_turn_speed":
			player_find(argument2).edge_turn_speed = real(string_split(argument1, " ")[1]);
			trace("edge_turn_speed set to "+string_split(argument1, " ")[1]);
			break;
		case "vertical_turn_speed":
			player_find(argument2).vertical_turn_speed = real(string_split(argument1, " ")[1]);
			trace("vertical_turn_speed set to "+string_split(argument1, " ")[1]);
			break;
		case "crosshair":
			player_find(argument2).crosshair = real(string_split(argument1, " ")[1]);
			trace("crosshair set to "+string_split(argument1, " ")[1]);
			break;
		default:
		trace("Set a local variable. (format:[/localset name value])
		Variables are:
		jumping (default: true)
		jump_button (default: horn)
		vertical (default: true) (looking up/down)
		control_style (default: new)
		base_turn_speed (default: 1)
		edge_turn_speed (default: 15)
		vertical_turn_speed (default: 1)
		crosshair (default: 0)");
	}
	return 1;
}
#define magiczbullet
	with (instances_matching(projectile, "magic_z_check", null)) {
		magic_z_check = true
		if (team == 2) {
			var p = instance_nearest(x, y, Player)
			if (point_distance(x, y, p.x, p.y) < 16) {
				z = ((sprite_height / image_yscale) / 2) + p.z + 4;
				magic_z = true
				speedz = lengthdir_y(speed, global.camera_angle_v)
				speed = lengthdir_x(speed, global.camera_angle_v)
				t = 0
			}
		}
	}
	var magic_bounce = [BouncerBullet, Grenade, BloodGrenade, ClusterNade, MiniNade, Bullet2, FlameShell, UltraShell, Slug, FlakBullet]
	var magic_grav = [Grenade, BloodGrenade, ClusterNade, MiniNade]
	with (instances_matching(projectile, "magic_z", true)) {
		t = t + 1
		if t > 500 {
			instance_destroy()
			continue
		}
		if (z > global.wall_height * 16)
			mask_index = mskNone
		else
			mask_index = -1
		if (array_find_index(magic_grav, object_index) >= 0) {
			if (place_meeting(x, y, Wall)) {
				mask_index = mskNone
				z = global.wall_height * 16
			} else {
				speedz = speedz - 0.55
			}
		} else {
			if (friction > 0 && speedz != 0) {
				speedz = speedz - friction * sign(speedz)
				if abs(speedz) < friction
					speedz = 0
			}
		}
		z+=speedz
		if z < 0 {
			if (array_find_index(magic_bounce, object_index) >= 0) {
				speedz = speedz * -0.5
			} else {
				if ("spr_dead" in self) {
					with instance_create(x, y, BulletHit) z = other.z + 7
				}
				instance_destroy()
			}
		}
	}
	instance_destroy()
	
#define step
	script_bind_step(magiczbullet, 0);
    var _paus = false;
    for(var i = 0; i < 4; i++){
        for(var j = 0; j < maxp; j++){
            player_set_show_cursor(i, j, 0);
        }
        if(button_pressed(i, "paus")) _paus = true;
    }
    for(var i = 0; i < maxp; i++){
        if(player_is_local_nonsync(i)) global.camera = i;
        if(!instance_exists(Player) || _paus || button_check(i, "key1")){
            player_set_show_cursor(i, i, 1);
        }
    }

	with TopCont {darkness = 0; fog = -1;}

	if(instance_exists(Player)){
	    with(Player){
    		if (!instance_exists(PlayerSit)){
    			//Z-Axis!
    			if("z" not in self){
                    z = 0;
    				fall = 0;
    				jumphp = my_health;
    				jumping = true;
    				jump_button = "horn";
					onWalls = false
                }
				var onground = false;
    			z += fall;
    			if(z>0){
    				fall -= global.grav;
    				//optional invincibility code
    				if(global.jump_invincibility){my_health = jumphp;}
    			}else{
					onground = true
    				z=0;
    				fall = 0;
    			}
    			if(z>global.wall_height * 16) {
					mask_index = mskNone
					onWalls = true
				} else if(onWalls){
						mask_index = mskPlayer
					if (place_meeting(x, y, Wall) || !place_meeting(x, y, Floor)) {
						fall = 0
						z = global.wall_height * 16
						mask_index = mskNone
						onground = true
					} else {
						onWalls = false
					}
				}
				
				
    			if(button_check(index, jump_button)  && onground){
    				fall = global.jump_height;
    				jumphp = my_health;
    			}
    			
                // Aiming:
                canaim = false;
                turn_border = (game_width / 24);
                if("turn_mouse_x" not in self){
                    turn_mouse_x = 0;
                    turn_mouse_y = 0;
                    turn_xview = 0;
                    turn_yview = 0;
    				control_style = true;
    				base_turn_speed = 1;
    				edge_turn_speed = 15;
    				vertical_turn_speed = 1;
    				vertical = true;
    				crosshair = 0;
                }
    
                var _x = ((mouse_x[index] - turn_xview) mod game_width);
                var _y = (-(mouse_y[index] - turn_yview) mod game_width);
    			var yTurn = (turn_mouse_y - _y) * vertical_turn_speed * (control_style?1:0.2);
                gunangle += (turn_mouse_x - _x) * base_turn_speed * (control_style?1:0.2);
                if(_x < turn_border || _x > game_width - turn_border){
                    gunangle += edge_turn_speed * (((game_width / 2) - _x) / game_width); 
                }
    			gunangle = (gunangle + 360) mod 360;
    			if(control_style){
    				turn_mouse_x = _x;
    				turn_mouse_y = _y;
    			}
                turn_xview = view_xview[index]; // Delay view check by a frame
                turn_yview = view_yview[index];
    
                 // Movement:
                canwalk = false;
                var _dir = ["nort", "west", "sout", "east"];
                for(var i = 0; i < array_length(_dir); i++){
                    if(button_check(index, _dir[i])){
                        motion_add(gunangle + (90 * i), maxspeed);
                    }
                }

                 // Local Camera (thanks Yokin, I never quite understood how this worked before reading this)
                 // though this implies we need to render other Players as well
                 // the new multiplayer FPS sensation is here
                if(player_find(index) == id && index == global.camera){
                    global.camera = index;
                    global.camera_x = x;
                    global.camera_y = y - 1;
                    global.camera_angle = gunangle;
    				if(vertical){
    					global.camera_angle_v+=yTurn;
    					global.camera_angle_v = clamp(global.camera_angle_v, -90, 90);
    				}
                }
            }else{
                global.camera_x = x;
                global.camera_y = y + 64;
                global.camera_angle = point_direction(global.camera_x,global.camera_y,x,y);
    			global.camera_angle_v = 0;
                global.camera_height = 20 + (max(0,64 * TopCont.fade));// + (12 * sin(current_time / 400));
            }
	    }
    	with(PlayerSit){
    		if(player_find(index) == id && player_is_local_nonsync(index)){
    			global.camera_x = x;
    			global.camera_y = y + 64;
    			global.camera_angle = point_direction(global.camera_x,global.camera_y,x,y);
    			global.camera_height = 32;
    		}
    	}
	}
	else with(Campfire){
        var _x = x,
            _y = y;

        global.camera_angle = 90;
        global.camera_angle_v = 10;

        var n = player_get_race_id(global.camera);
        if(n > 0) with(instances_matching(CampChar, "num", n)){
            _x = x;
            _y = y;
        }

        global.camera_x += (_x - global.camera_x) / 3;
        global.camera_y += ((_y + 30) - global.camera_y) / 3;
    }

	script_bind_draw(draw_all, -14);


	
#define draw_all
	instance_destroy();
	
	//trace_time();
	
	var fog_color = merge_color(background_color, c_black, 0.5);
	
	if !surface_exists(global.drawsurf) global.drawsurf = surface_create(game_width, game_height);
	if !surface_exists(global.viewsurf) global.viewsurf = surface_create(global.display_res[0], 2 * global.display_res[1]);
	if !surface_exists(global.planesurf) global.planesurf = surface_create(2*global.view_dist, 2*global.view_dist);
	
	surface_set_target(global.viewsurf);
	draw_clear(c_white); // depth buffer far color
	draw_set_color(fog_color);
	draw_rectangle(0, 0, global.display_res[0], global.display_res[1], 0);
	surface_reset_target();
	
	var _camZ = 0;
	with(Player) if(global.camera == index){
		_camZ = z;
	}
	
	draw_set_projection(0);	
	shader_set_vertex_constant_f(0, matrix_multiply(matrix_multiply(matrix_get(matrix_world), matrix_get(matrix_view)), matrix_get(matrix_projection)));
	shader_set_fragment_constant_f(0, [global.camera_x, global.camera_y, global.camera_height + _camZ]);
	shader_set_fragment_constant_f(1, [degtorad(global.camera_angle), degtorad(global.camera_angle_v)]);
	shader_set_fragment_constant_f(2, [0.5*degtorad(global.FOV)]);
	shader_set_fragment_constant_f(3, [global.display_res[0]/global.display_res[1]]); // camera aspect ratio
	shader_set_fragment_constant_f(4, [color_get_red(fog_color) / 255, color_get_green(fog_color) / 255, color_get_blue(fog_color) / 255]);
	shader_set_fragment_constant_f(5, [global.view_dist]);

	 // Floors:
    plane_setup();
    	
    	 // Draw Floors to Surface:
        var _surf = global.surfFloor,
            _surfW = global.surfFloorW,
            _surfH = global.surfFloorH,
            _surfX = (10000 - (_surfW / 2)),
            _surfY = (10000 - (_surfH / 2)),
            _draw = false,
            f = instances_matching([Floor, CharredGround, Scorch, ScorchGreen, ScorchTop], "floor_surface_3D", null);

        if(!instance_exists(Player) && instance_exists(Campfire)){
            _surfX = Campfire.x - (_surfW / 2);
            _surfY = Campfire.y - (_surfH / 2);
        }
    
        if(!surface_exists(_surf)){
            _draw = true;
            global.surfFloor = surface_create(global.surfFloorW, global.surfFloorH);
            _surf = global.surfFloor;
        }
        else if(array_length(f) > 0) _draw = true;
        if(_draw){
            surface_set_target(_surf);
            draw_clear_alpha(0, 0);
    
        	with(instances_matching(Floor, "depth", 10)){
        	    floor_surface_3D = true;
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
        	with(instances_matching_lt(Floor, "depth", 10)){
        	    floor_surface_3D = true;
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
        	with(Detail){
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
        	with(CharredGround){
        	    floor_surface_3D = true;
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
        	with(Scorch){
        	    floor_surface_3D = true;
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
        	with(ScorchGreen){
        	    floor_surface_3D = true;
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
        	with(ScorchTop){
        	    floor_surface_3D = true;
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
    
            surface_reset_target();
	        surface_set_target(global.planesurf);
        }

         // Draw Floor Surface:
        draw_surface(_surf, _surfX - floor(global.camera_x - global.view_dist), _surfY - floor(global.camera_y - global.view_dist));

//    plane_raycast(0);
	
		/*
         // Shadows:
        var _surf = global.surfShadows;
        if(!surface_exists(_surf)){
            global.surfShadows = surface_create(_surfW, _surfH);
            _surf = global.surfShadows;
        }

        if(instance_exists(BackCont)){
            var w = instances_matching(Wall, "shadows_3D", null);
            if(instance_exists(GenCont)){
                surface_set_target(_surf);
                draw_clear_alpha(0, 0);
                surface_reset_target();
            }
            if(array_length(w) > 0){
                surface_set_target(_surf);
                draw_clear_alpha(0, 0);

                d3d_set_fog(1, BackCont.shadcol, 0, 0);
                with(Wall){
                    shadows_3D = true;

                    var _x = x - _surfX,
                        _y = y - _surfY,
                        _ox = 16,
                        _oy = 16;
        
                    draw_primitive_begin(pr_trianglestrip);
                    draw_vertex(_x, _y);
                    draw_vertex(_x + 16, _y + 16);
                    draw_vertex(_x - 1 + _ox, _y - 1 - _oy);
                    draw_vertex(_x + 17 + _ox, _y + 17 - _oy);
                    draw_primitive_end();
                    draw_sprite(outspr, image_index, _x - sprite_get_xoffset(outspr) + 4 + _ox, _y + sprite_get_yoffset(outspr) - 4 - _oy);
                }
                /*with(Player){
                    var _x = x - _surfX,
                        _y = y - _surfY - 12,
                        _ox = sprite_xoffset,
                        _oy = sprite_yoffset,
                        w = sprite_width,
                        h = sprite_height;

                    draw_sprite_pos(sprite_index, image_index, _x - _ox, _y - _oy, _x + (w - _ox), _y - _oy, _x + (w - _ox), _y + (h - _oy), _x - _ox, _y + (h - _oy), 1);
                }*//*
                d3d_set_fog(0, 0, 0, 0);

                surface_reset_target();
    	        surface_set_target(global.planesurf);
            }

            draw_surface_ext(_surf, _surfX - floor(global.camera_x - global.view_dist), _surfY - floor(global.camera_y - global.view_dist), 1, 1, 0, c_white, BackCont.shadalpha);
        }
*/
    plane_raycast(0);
	
    plane_setup();
   	
    	 // Draw Floors to Surface:
        var _surf = global.surfCeil,
            _surfW = global.surfCeilW,
            _surfH = global.surfCeilH,
            _surfX = (10000 - (_surfW / 2)),
            _surfY = (10000 - (_surfH / 2));
		
    
        if(!surface_exists(_surf)){
            _draw = true;
            global.surfCeil = surface_create(global.surfCeilW, global.surfCeilH);
            _surf = global.surfCeil;
        }
        if(_draw){
            surface_set_target(_surf);
            draw_clear_alpha(0, 0);
    
        	with(TopSmall){
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
        	with(Top){
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
        	with(Wall){
                draw_sprite(topspr, topindex, x - _surfX, y - _surfY);
        	}
        	with(TopPot){
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
        	with(Bones){
                draw_sprite(sprite_index, image_index, x - _surfX, y - _surfY);
        	}
    
            surface_reset_target();
	        surface_set_target(global.planesurf);
        }

         // Draw Floor Surface:
        draw_surface(_surf, _surfX - floor(global.camera_x - global.view_dist), _surfY - floor(global.camera_y - global.view_dist));

    plane_raycast(global.wall_height * 16);

	//for ()
	plane_setup();

         // Bolt Trails:
    	with(instances_viewbounds(40, BoltTrail)){
    	    plane_draw(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle);
    	}
    
    	 // Melee/Lasers/Lightning:
    	with instances_viewbounds(40, instances_matching(projectile, "typ", 0)) {
    		plane_draw(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle);
    	}
    	with instances_viewbounds(40, LaserCannon) {
    		plane_draw(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle);
    	}
    
    	 // Projectiles:
    	var _planeProj = [Bullet1, Bullet2, Bolt, Disc, EnemyBullet2, BouncerBullet, FlameShell, Seeker, HeavyBolt, Splinter, UltraBolt, UltraBullet, UltraShell, HeavyBullet, IDPDBullet, ThrownWep, Slug, HeavySlug, HyperSlug, Rocket, Nuke];
    	with instances_matching(instances_viewbounds(40, _planeProj), "magic_z", null) {
    		var _yscale = dcos(global.camera_angle - image_angle) * image_yscale;
    		if(abs(_yscale) > 0.5){
    			plane_draw(sprite_index, image_index, x, y, image_xscale, _yscale, image_angle);
    		}
	    }

	plane_raycast(global.camera_height / 2 + _camZ);
	
	plane_setup();
	
    	// Other Stuff:
    	with instances_viewbounds(40, [Tangle, RogueStrike, Portal]) {
    		plane_draw(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle);
    	}
	
	plane_raycast(3);

	batch_init(sprite_get_texture(sprWall0Bot, 0));
	with instances_viewbounds(23, Wall) {
		if position_meeting(x-8, y+8, Floor) && global.camera_x <= x
			batch_add(sprite_index, image_index, x, y, 16, 90, true, global.wall_height);
		if position_meeting(x+8, y+24, Floor) && global.camera_y >= y+16
			batch_add(sprite_index, image_index, x, y+16, 16, 0, true, global.wall_height);
		if position_meeting(x+24, y+8, Floor) && global.camera_x >= x+16
			batch_add(sprite_index, image_index, x+16, y+16, 16, -90, true, global.wall_height);
		if position_meeting(x+8, y-8, Floor) && global.camera_y <= y
			batch_add(sprite_index, image_index, x+16, y, 16, 180, true, global.wall_height);
	}
	
	with instances_viewbounds(40, IDPDPortalCharge) {
        var _z =  alarm0;
        batch_add(sprite_index, image_index, x, y, _z, -global.camera_angle+90, false, 1);
    }

	with instances_viewbounds(40, chestprop) {
		batch_add(sprite_index, image_index, x, y, (sprite_height / 2), -global.camera_angle+90, false, 1);
	}

	with instances_viewbounds(40, Corpse) {
        var _z = (image_index / (image_number - 1)) * (speed + 1) * ((sprite_height / 4) + 1);
		batch_add(sprite_index, image_index, x, y, _z, -global.camera_angle+90, false, 1);
	}

	with instances_viewbounds(40, [hitme, Revive]) {
		if(object_index != Player || !player_is_local_nonsync(index)){
		    batch_add(sprite_index, image_index, x, y, sprite_height/3, -global.camera_angle+90, false, 1);
		}

		 // Weapon:
	    if(object_index == Player){
            var _wep = [{
                    "wep"  : wep,
                    "kick" : wkick,
                    "wang" : wepangle,
                    "load" : reload,
                    "x" : 4,
                    "y" : 14
                }];

            if(race == "steroids"){
                var w = _wep[0];
                array_push(_wep, {
                        "wep"  : bwep,
                        "kick" : bwkick,
                        "wang" : bwepangle,
                        "load" : breload,
                        "x" : w.x,
                        "y" : w.y
                    });
                w.y *= -1;
            }

            for(var i = 0; i < array_length(_wep); i++){
                var w = _wep[i],
                    _spr = weapon_get_sprt(w.wep),
                    _melee = (weapon_is_melee(w.wep)),
                    _ox = w.x - (w.kick * 2),
                    _oy = 0,
                    _oz = (global.camera_height / 2) + (2 * _melee) - min(global.camera_angle_v / 4, 4);

                if(!_melee || race == "steroids") _oy = w.y;

                 // Firing:
                if(w.load > 0 || w.kick > 0 || button_check(index, ["fire", "spec"][i]) || (i == 0 && clicked)){
                    _ox += sprite_get_xoffset(_spr);
                    _oy /= 3;
                }

	            batch_add(_spr, 0, x + lengthdir_x(_ox, gunangle) + lengthdir_x(_oy, gunangle - 90), y + lengthdir_y(_ox, gunangle) + lengthdir_y(_oy, gunangle - 90), z+_oz+5, -(gunangle + w.wang), false, 1);
            }
		}
		else if("gunspr" in self){
			batch_add(gunspr, 0, x, y, sprite_height/3, -gunangle, false, 1);
		}
	}

	with instances_viewbounds(40, instances_matching_ne(projectile, "typ", 0)) {
		if(array_find_index(_planeProj, object_index) >= 0){
    	    var _yscale = abs(dsin(global.camera_angle - image_angle) * image_yscale);
    	    if(abs(_yscale) > 0){
        	    var _spr = sprite_index,
        	        u = sprite_get_uvs(_spr, image_index),
        	        h = (global.camera_height / 2);
    
                batch_add(_spr, image_index, x, y, (h - ((((u[3] - u[1]) * 2048) / 2) * (1 - _yscale))) / _yscale, -image_angle, false, _yscale);
    	    }
	    }
	    else{
	        var _img = image_index;
            if(team == 2){
                if(image_speed == 0 || speed > 10) _img = 0;
            }
    		batch_add(sprite_index, _img, x, y, ((sprite_height / image_yscale) / 2), -global.camera_angle+90, false, 1);
	    }
	}


	with instances_viewbounds(40, instances_matching(projectile, "magic_z", true)) {
    	batch_add(sprite_index, image_index, x, y,z, -global.camera_angle+90, false, 1);
	}

	with instances_viewbounds(40, BulletHit) {
		var _z
		if ("z" in self) _z = z else _z = (sprite_height / 2)
	    batch_add(sprite_index, image_index, x, y, _z, -global.camera_angle+90, false, 1);
    }

	with instances_viewbounds(40, Pickup) {
		batch_add(sprite_index, image_index, x, y, (sprite_height / 2), -global.camera_angle+90, false, 1);
	}

	with instances_viewbounds(40, [Explosion, MeatExplosion, PlasmaImpact]) {
		batch_add(sprite_index, image_index, x, y, (sprite_height / 4) + ((sprite_height / 16) * (image_index * abs(1.5 * sin(x + y)))), -global.camera_angle+90, false, 1);
	}

	with instances_viewbounds(40, Portal) {
		batch_add(sprite_index, image_index, x+5, y, (sprite_height / 2), -global.camera_angle+90, false, 1);
		batch_add(sprite_index, image_index, x-5, y, (sprite_height / 2), -global.camera_angle+90, false, 1);
		batch_add(sprite_index, image_index, x, y+5, (sprite_height / 2), -global.camera_angle+90, false, 1);
		batch_add(sprite_index, image_index, x, y-5, (sprite_height / 2), -global.camera_angle+90, false, 1);
	}
	with instances_viewbounds(40, PopoShield) {
        var _ang = point_direction(x, y, global.camera_x, global.camera_y);
        batch_add(sprite_index, image_index, x + lengthdir_x(12, _ang), y + lengthdir_y(12, _ang), 8, -_ang + 90, false, global.popo_shield_height);
    }
	
	batch_finalize();

	batch_init(sprite_get_texture(sprFishMenuSelected, 0));

	with instances_viewbounds(40, CampChar) {
		if(num < 17) batch_add(sprite_index, image_index, x, y, 12, -global.camera_angle+90, false, 1);
	}
	
	batch_finalize();
	
	draw_set_projection(0);
	draw_surface_ext(global.viewsurf, 0, 0, game_width / global.display_res[0], game_height / global.display_res[1], 0, c_white, 1);
	// small depth image
	//draw_surface_part_ext(global.viewsurf, 0, global.display_res[1], global.display_res[0], global.display_res[1], 0, 50, game_width * 0.2 / global.display_res[0], game_height * 0.2 / global.display_res[1], c_white, 1);

	with(player_find(global.camera)){
		if(crosshair > 0){draw_sprite(sprCrosshair, crosshair - 1, game_width / 2, game_height / 2);}
	    var _x = turn_mouse_x,
	        _border = turn_border;

        draw_set_alpha(0.4);
    	draw_set_color(c_silver);
        draw_rectangle(0, game_height - 4, game_width, game_height, 0);
        draw_set_alpha(0.6);
    	draw_set_color(c_white);
        draw_rectangle(mouse_x[index] - view_xview[index], game_height - 4, turn_mouse_x, game_height, 0);
        draw_set_alpha(1);

         // Border:
        for(var i = 0; i <= game_width; i += game_width){
            var _side = ((i < (game_width / 2)) ? -1 : 1),
                _x1 = i,
                _x2 = _x1 - (_side * _border);

            draw_primitive_begin(pr_trianglestrip);
            draw_set_alpha(_side * ((_x - _x2) / _border));
            draw_vertex(_x1, 0);
            draw_vertex(_x1, game_height);
            draw_set_alpha(0);
            draw_vertex(_x2, 0);
            draw_vertex(_x2, game_height);
            draw_primitive_end();
        }
        draw_set_alpha(1);
	}
	
	draw_reset_projection();
	
	//trace_time("Everything")
	
#define in_fov(_x, _y, margin)
	var pullback = margin / dsin(global.FOV / 2)
	return abs(angle_difference(global.camera_angle, 
		point_direction(global.camera_x - lengthdir_x(pullback, global.camera_angle), global.camera_y - lengthdir_y(pullback, global.camera_angle), _x, _y)
	)) <= global.FOV / 2
	// the math guarantees that this method returns true only if a circle with size margin at (_x, _y) would be visible
	// hence, choose margin to be the diameter of the object of which visibility is to be determined

#define instances_viewbounds(margin, _obj)
	// so, to be fair, this method would be simpler if the view were a frustrum or triangle
	var farleft_x = global.camera_x + lengthdir_x(global.view_dist, global.camera_angle - global.FOV/2)
	var farleft_y = global.camera_y + lengthdir_y(global.view_dist, global.camera_angle - global.FOV/2)
	var farright_x = global.camera_x + lengthdir_x(global.view_dist, global.camera_angle + global.FOV/2)
	var farright_y = global.camera_y + lengthdir_y(global.view_dist, global.camera_angle + global.FOV/2)
	// we have to account for the circular part of the view
	return instances_rectangle(
		min(global.camera_x - (abs(angle_difference(180, global.camera_angle)) < global.FOV/2) * global.view_dist, farleft_x, farright_x) - margin,
		min(global.camera_y - (abs(angle_difference(90, global.camera_angle)) < global.FOV/2) * global.view_dist, farleft_y, farright_y) - margin,
		max(global.camera_x + (abs(angle_difference(0, global.camera_angle)) < global.FOV/2) * global.view_dist, farleft_x, farright_x) + margin,
		max(global.camera_y + (abs(angle_difference(270, global.camera_angle)) < global.FOV/2) * global.view_dist, farleft_y, farright_y) + margin,
		_obj
	)

#define instances_rectangle(_x1, _y1, _x2, _y2, _obj)
	return instances_matching_le(instances_matching_ge(instances_matching_le(instances_matching_ge(_obj, "x", _x1), "x", _x2), "y", _y1), "y", _y2);
	
#define cleanup
	surface_destroy(global.drawsurf);
	surface_destroy(global.planesurf);
	surface_destroy(global.drawsurf);
	shader_destroy(global.sh_comp);
	shader_destroy(global.sh_comp_batch);
