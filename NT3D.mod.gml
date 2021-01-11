//TODO custom models/rendering files - use asset_get_index
//TODO finish the custom model implementation - including animations
//TODO skybox for more areas
//TODO animated skyboxes
//DONE Option for turning off skyboxes
					 
//DONE Strong Spirit indicator
//DONE NTTE Strong Spirits (bonus_spirit or something)
							 
//TODO? when the player is on walls, turn them into inviswalls or whatever they're called
//TODO? make homing projectiles home in the Z axis
//TODO? make rads use the Z axis

//TE inlets in labs don't render properly
//trench
//coast
//t2 add spiral (check for NothingSpiral)
//projectiles going out of bounds and lagging
//WantTurret is visible
//van portals look like idpd portals - make idpd portals visible
//3d vans draw 2d vans behind them
//add shadows?
//vault needs to show rads

//changelog:
// Strong Spirit indicator added (also bonus spirits from NTTE!)
// Aim correction for projectile and player height being different
// Fixed some default mouse settings
// Added coyote time to jumping
#define init
#macro VERSION 3.5
#macro CORPSE_TIME 20

global.backup = 0;
mod_sideload();

global.options = {
	autoceiling : false, wall_height : 30, player_height : 18, projectile_height : 12, camera_height : 18, enemy_indicator : true, danger_indicator : true,
	FOV : 120, view_dist : 400, mousesensx : [1,1,1,1], mousesensmultx : [0.1,0.1,0.1,0.1], mousesensy : [0.65,0.65,0.65,0.65], mousesensmulty : [0.1,0.1,0.1,0.1], fancy_projectile_max : 20, faster_projectile_max : 40, corpse_max : 100, Models : false, RecoilMult : [2,2,2,2], CapRecoil : true, shakefactor : 5, reticle : "@(sprCrosshair:1)", reticleScale : 1, skybox : true,
	ControlSettings : true, Widescreen : true, Scaling : "native", MouseSens : 1,
	True3D: true, CanJump : false, jump_invincibility : false, jump_height : 7, grav : 0.7, jump_button : "key7", debug_button : false
};
if (fork()){
	file_load('settings'+string(VERSION)+'.json');
	while (!file_loaded('settings'+string(VERSION)+'.json')) wait 0;
	if (!is_undefined(string_load('settings'+string(VERSION)+'.json'))) {
		global.options = json_decode(string_load('settings'+string(VERSION)+'.json'));
	}
	update_visual_settings();
	exit;
}
global.models = [{}];
if (fork()){
	var arr = [];
	wait file_find_all("NT3D/", arr);
	for (var i = 0; i < array_length(arr); i++) {
		//if it's from the data directory, don't bother
		if(arr[i].is_data){
			continue;
		}
		//if it is a .json, add to models
		else if(arr[i].ext == ".json"){
			wait(file_load(arr[i].path));
			while(!file_loaded(arr[i].path)){wait 0}
			var json = string_load(arr[i].path);
			if(!is_undefined(json) && string_length(json) > 0){
				json = json_decode(json);
			}
			if(string_split(arr[i].name, " ")[0] == "enemy"){
				lq_set(global.models[0], real(string_split(string_split(arr[i].name, " ")[1], ".json")[0]), mod_script_call_nc("mod", "JSONModels", "Setup", json, "NT3D/", "NT3D/"));
			}
		}
	}
	exit;
}

if (fork()){
  while (!mod_script_exists("mod", "options", "option_add_page")){
    wait(0);
  }
	mod_script_call("mod", "options", "option_add_page", "mod", mod_current, "options", "NTIIID", "VISUAL GLOBAL", {
	  sync: {name: "GLOBAL OPTIONS", type: "title", desc: "These options are for all players"},
	  //autoceiling: {name: "Automatic Ceiling", type: "bool", desc: "Adds an automatically generated ceiling.#Not recommended to have on at the same time as jumping.", display: ["OFF", "ON"]},
	  wall_height: {name: "Wall Height", type: "slider", desc: "Changes the height of the walls", steps: 1, fine_steps: 1, range:[2, 40], suffix: "", display: 1, decimal: 0},
	  player_height: {name: "Player Height", type: "slider", desc: "Changes the height of the players", steps: 1, fine_steps: 1, range:[2, 40], suffix: "", display: 1, decimal: 0},
	  projectile_height: {name: "Projectile Height", type: "slider", desc: "Changes the height of the projectiles", steps: 1, fine_steps: 1, range:[2, 40], suffix: "", display: 1, decimal: 0},
	  enemy_indicator: {name: "Enemy Indicator", type: "bool", desc: "Shows the last few enemies for each level.#Highly recommended.", display: ["OFF", "ON"]},
	  mousesensx: {name: "Horizontal Sens.", type: "slider", desc: "How fast you look left to right", steps: 0.01, fine_steps: 0.05, range:[0, 1], suffix: "", display: 1, decimal: 2, fake_nonsync: true},
	  mousesensmultx: {name: "Horizontal Sens. Mult", type: "cycle", desc: "Multiplier for HSens", choices: [1, 10, 100, 1000, 0.1], fake_nonsync: true},
	  mousesensy: {name: "Vertical Sens.", type: "slider", desc: "How fast you look up and down", steps: 0.01, fine_steps: 0.05, range:[0, 1], suffix: "", display: 1, decimal: 2, fake_nonsync: true},
	  mousesensmulty: {name: "Vertical Sens. Mult", type: "cycle", desc: "Multiplier for VSens", choices: [1, 10, 100, 1000, 0.1], fake_nonsync: true},
	  //danger_indicator: {name: "Danger Indicator", type: "bool", desc: "Shows the direction of projectiles#that hit or barely miss you.", display: ["OFF", "ON"]},
	});
	mod_script_call("mod", "options", "option_add_page", "mod", mod_current, "options", "NTIIID", "VISUAL LOCAL", {
	  nonsync: {name: "LOCAL OPTIONS", type: "title", desc: "These options are just for you"},
	  FOV: {name: "FOV", type: "slider", desc: "Changes your Field Of View", steps: 1, fine_steps: 0.1, range:[80, 160], suffix: "", display: 1, decimal: 0, nonsync: true},
	  view_dist: {name: "View Distance", type: "slider", desc: "How far you can see#Lower to speed the game up slightly", steps: 1, fine_steps: 20, range:[40, 800], suffix: "", display: 1, decimal: 0, nonsync: true},
	  fancy_projectile_max: {name: "Fancy Proj. Max", type: "slider", desc: "How many fancy projectiles render at once,#before switching to faster rendering#Lower to speed the game up slightly", steps: 1, fine_steps: 10, range:[0, 200], suffix: "", display: 1, decimal: 0, nonsync: true},
	  faster_projectile_max: {name: "Faster Proj. Max", type: "slider", desc: "How many faster projectiles render at once,#before switching to fastest rendering#Lower to speed the game up slightly", steps: 1, fine_steps: 10, range:[0, 200], suffix: "", display: 1, decimal: 0, nonsync: true},
	  corpse_max: {name: "Corpse Max", type: "slider", desc: "How many corpses you see#Lower to speed the game up slightly", steps: 1, fine_steps: 20, range:[0, 400], suffix: "", display: 1, decimal: 0, nonsync: true},
	  Models : {name: "3D Models", type: "bool", desc: "Lets 3D models display (May increase lag)", display: ["OFF", "ON"], nonsync: true},
	  RecoilMult: {name: "Recoil Multiplier", type: "cycle", desc: "Increases how much recoil the guns have.#Purely visual.", choices: [0, 0.5, 1, 2, 3, 5, 10, 20, 40, 200, 2000], nonsync: true},
	  CapRecoil : {name: "Cap Recoil", type: "bool", desc: "Caps the recoil of guns to stop them from doing spins", display: ["OFF", "ON"], nonsync: true},
	  shakefactor : {name: "Shake Factor", type: "slider", desc: "Screenshake Multiplier", steps: 0.1, fine_steps: 1, range:[0, 10], suffix: "", display: 1, decimal: 1, nonsync: true},
	  reticle : {name: "Reticle", type: "cycle", desc: "The onscreen reticle", choices: ["@(sprCrosshair:0)", "@(sprCrosshair:1)", "@(sprCrosshair:2)", "@(sprCrosshair:3)", "@(sprCrosshair:4)", ""], nonsync: true},
	  reticleScale : {name: "Reticle Scale", type: "slider", desc: "How large the reticle is", steps: 0.1, fine_steps: 0.1, range:[0, 5], suffix: "", display: 1, decimal: 1, nonsync: true},
	  skybox : {name: "Skybox", type: "bool", desc: "Show custom skyboxes", display: ["OFF", "ON"], nonsync: true},
	});
	mod_script_call("mod", "options", "option_add_page", "mod", mod_current, "options", "NTIIID", "OVERRIDES", {
	  nonsync: {name: "OVERRIDES", type: "title", desc: "These options override the game options"},
	  ControlSettings: {name: "Control Settings", type: "bool", desc: "Do these options take effect?", display: ["OFF", "ON"], nonsync: true},
	  Widescreen: {name: "Widescreen", type: "bool", desc: "Widescreen", display: ["OFF", "ON"], nonsync: true},
	  Scaling: {name: "Scaling", type: "cycle", desc: "Pixel Scaling.", choices: [1, 2, 3, 4, "Native"], nonsync: true},
	  MouseSens: {name: "Mouse Sensitivity", type: "cycle", desc: "This is a setting within the base game,#it's recommended to keep it on 1000 when playing NT3D.", choices: [1, 5, 10, 100, 1000, 10000, "Don't Change"], nonsync: true},
	});
	mod_script_call("mod", "options", "option_add_page", "mod", mod_current, "options", "NTIIID", "MECHANICS", {
	  sync: {name: "GLOBAL OPTIONS", type: "title", desc: "These options are for all players"},
	  True3D: {name: "True 3D", type: "bool", desc: "Makes projectiles move in 3D", display: ["OFF", "ON"]},
	  CanJump: {name: "Jumping", type: "bool", desc: "Lets the players jump#Mix with True 3D for jumping on walls", display: ["OFF", "ON"]},
	  jump_invincibility: {name: "Jump Invincibility", type: "bool", desc: "Whether you are invincible while in the air", display: ["OFF", "ON"]},
	  jump_height: {name: "Jump Height", type: "slider", desc: "How high you jump", steps: 1, fine_steps: 1, range:[1, 25], suffix: "", display: 1, decimal: 0},
	  grav: {name: "Gravity", type: "slider", desc: "How fast you fall", steps: 0.1, fine_steps: 0.1, range:[0.1, 3], suffix: "", display: 1, decimal: 1},
	  jump_button: {name: "Jump Button", type: "cycle", desc: "Button to jump", choices: ["horn", "swap", "pick", "okay", "fire", "spec", "key1", "key2", "key3", "key4", "key5", "key6", "key7", "key8", "key9"]},
	  debug_button: {name: "Debug Button", type: "bool", desc: "Enables the debug button#(lets you see normally)#Button is set to horn", display: ["OFF", "ON"]},
	});
  exit;
}

global.camera_index = 0;
global.camera_shake = [0,0,0,0];
global.camera_x = 160;
global.camera_y = 120;
global.camera_angle = 0;
global.smoothed_camera_angle = 0;
global.camera_vangle = 0;
global.smoothed_camera_vangle = 0;

global.indicator_timer = 0;

global.wasPaused = false;

// surface for Floors
global.surf_floors = -1;
global.surf_floors_x = 0;
global.surf_floors_y = 0;

//with(script_bind_draw(floorgrab, object_get_depth(BackCont) - 1)){
//	persistent = true;
//}

// surface for Tops
global.surf_top = -1;
global.surf_top_x = 0;
global.surf_top_y = 0;

global.wallNum = instance_number(Wall);

global.zbullet = noone;

// render list
global.render_non_default = [];
global.render_billboard = [];
global.render_floor = [];
global.render_custom = [];
global.render_auto3d = [];
global.render_model = [];

// "default" vertex buffer format
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_colour();
vertex_format_add_texcoord();
global.wall_vertex_format = vertex_format_end();

global.wall_vertex_buffer = null;

global.custom = ds_map_create();

global.sprVan = sprite_add_base64("iVBORw0KGgoAAAANSUhEUgAAAKIAAAAsCAYAAADmSGOzAAAABmJLR0QA/wD/AP+gvaeTAAACI0lEQVR42u2dP0/CQByGDwPGDlK7IHFy8s+ECYmbi3FDXZgcnPw88jVcZAJGWdxMHBxxUgeDLE1xYHDAwdSYcqRQ++fu+jyJKZLQ+5W++b33tvUsnDcupwIgYwrWWhkhLoBjV7Wq1/WGWtW7gsQAIQIgRECIAAgRVKTIVxCd949nJerY2tyhIwIgRECIALHOEVd7nhBCCO9Y34OwLJszaUJY0VmEsDhRb1O63lD62XnvL7I/rDnn+CIIbsME7HrDmZ8wES4zVlEIIew+XTFvXTG4TaKbLjNWcaP388LfJsHrNQKAkDnieNBOdIBSpS4sqxbrPicTb+Z3AosBYSVJvkaPYv3iSXze1Iz78g72TpSoY+S+IcQ8Y4IAVEHL1Cyz4aBdA0Kca88ARnVEQIjYM+gdVnRPz7r9VRwdEUDljpiUPUe9uH1/No61lqNOOdVjD6s/7Xq06oikZzCyI/6H/auYd9hRrP6OXudD+zki6dkMCvbddJrkI2DO6exDFaVKPdb0LBNe2Dxxd/sw1uMcvDykeuLC6pfVo8r6PbIrELm15rSFQ/0hc8SVVls4rQTV321Ku6Iq6RlyPEckPYNxYQUQ4sJhxe02Sc+gZkfEngFrhnwKMUt79leyAISIPQPWDAgxM3u2+9izDH+pEBXHz7wjJm3PLKXypxnY1d91bLIQoT++DGPvNQe7IkRfvSvuGmQUnMZtqv95SnbvOe6ncUA/vgFm0tw0kl2fRgAAAABJRU5ErkJggg==",
1, 0, 0);

sprite_replace_base64(sprPortalIndicator,"iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAACXBIWXMAAAsSAAALEgHS3X78AAAAG3RFWHRTb2Z0d2FyZQBDZWxzeXMgU3R1ZGlvIFRvb2zBp+F8AAAAFElEQVQI12P8//8/AwMDAwMjjAEAROgF/WVpmpsAAAAASUVORK5CYII=",1,0,0)

#define step
	if(global.options.True3D){
		script_bind_step(magiczbullet, 0);
	}else{
		with(hitme){
			if("z" not in self){z = 0;}
		}
	}
	for(var i = 0; i < maxp; i++) {
		if(player_is_local_nonsync(i)) {
			global.camera_index = i;
			break;
		}
	}
	
	if(instance_number(GenCont) == 0){
		script_bind_draw(draw_all, -15);
	}
	
	for(var i = 0; i < maxp; i++) {for(var i2 = 0; i2 < maxp; i2++) {player_set_show_cursor(i, i2, 1);player_set_show_marker(i, i2, 1);player_set_show_prompts(i, i2, 1);}}
	mouse_unlock(); // unlocks the mouse on player death?
	
	with TopCont {if(darkness == 0){darkness = 1;}fog = mskNone;}
	
	with Player {
		
		//Z-Axis!
		if("jumping" not in self){
			z = 0;
			fall = 0;
			jumphp = my_health;
			jumping = true;
			onWalls = false;
			onground = 0;
		}
		onground--;
		z += fall;
		if("z" in instance_nearest(x,y,Floor) && z>instance_nearest(x,y,Floor).z){
			fall -= global.options.grav;
			//optional invincibility code
			if(global.options.jump_invincibility){my_health = jumphp;}
		}else if(z>0){
			fall -= global.options.grav;
			//optional invincibility code
			if(global.options.jump_invincibility){my_health = jumphp;}
		}else{
			onground = 5;
			if("z" in instance_nearest(x,y,Floor)){z=instance_nearest(x,y,Floor).z;}else{z=0;}
			fall = 0;
		}
		if(z>global.options.wall_height && global.options.True3D && global.options.CanJump) {
			mask_index = mskNone
			onWalls = true
		} else if(onWalls && global.options.True3D){
				mask_index = mskPlayer
			if (place_meeting(x, y, Wall) || !place_meeting(x, y, Floor)) {
				fall = 0
				z = global.options.wall_height
				mask_index = mskNone
				onground = 5;
			} else {
				onWalls = false
			}
		}
		
		
		if(button_check(index, global.options.jump_button) && onground > 0 && global.options.CanJump){
			fall = global.options.jump_height;
			jumphp = my_health;
			onground = 0;
		}
		
		if(!instance_exists(Menu) && !instance_exists(menubutton) && !("questshotted" in self and "GiveMeAQuest" not in self) && !(button_check(index, "horn") && global.options.debug_button) && !global.wasPaused){
			for(var i = 0; i < maxp; i++) {for(var i2 = 0; i2 < maxp; i2++) {player_set_show_cursor(i, i2, 0);player_set_show_marker(i, i2, 0);player_set_show_prompts(i, i2, 0);}}
		}
		//candie = 0; // debug
		if "vertangle" not in self vertangle = 0;
		
		if(!instance_exists(menubutton) && !instance_exists(GenCont) && !("questshotted" in self and "GiveMeAQuest" not in self)) {
			canaim = 0;
			canwalk = 0;
			
			gunangle = (gunangle - global.options.mousesensx[index] * global.options.mousesensmultx[index] * mouse_delta_x[index] * (room_speed / 30) + 360) mod 360;
			vertangle = clamp(vertangle - global.options.mousesensy[index] * global.options.mousesensmulty[index] * mouse_delta_y[index] * (room_speed / 30), -90, 90);
			if(!(button_check(index, "horn") && global.options.debug_button)){
				mouse_lock();
				if button_check(index, 'nort') motion_add(gunangle, maxspeed);
				if button_check(index, 'east') motion_add(gunangle-90, maxspeed);
				if button_check(index, 'west') motion_add(gunangle+90, maxspeed);
				if button_check(index, 'sout') motion_add(gunangle+180, maxspeed);
			}
		}
	}
	
	with(Player){
		if(!(button_check(index, "horn") && global.options.debug_button)){
			var dist = min(global.options.view_dist, max(1/dtan(-self.vertangle) * (global.options.camera_height - 3), 1));
			if(dist == 1 && self.vertangle > 0){
				dist = global.options.view_dist;
			}
			var aimPos = hitscan(x, y, gunangle, dist);
			
			aimPos[0] -= lengthdir_x(8, gunangle);
			aimPos[1] -= lengthdir_y(8, gunangle);
			move_camera(index, aimPos[0] - (mouse_x[index] - view_xview[index])+game_width/2, aimPos[1] - (mouse_y[index] - view_yview[index])+game_height/2);
			view_pan_factor[index] = 999999;
		}else{
			view_pan_factor[index] = 4;
		}
	}
	
	with instances_matching(Corpse, "nt3d_collapse", undefined) {
		nt3d_collapse = 0;
	}
	
	with instances_matching_lt(Corpse, "nt3d_collapse", CORPSE_TIME) {
		nt3d_collapse = min(nt3d_collapse + current_time_scale, CORPSE_TIME);
	}

#define update_level_geometry()
	// Part I: Floors
	var minx, miny, maxx, maxy;
	with Floor {
		minx = bbox_left;
		miny = bbox_top;
		maxx = bbox_right;
		maxy = bbox_bottom;
		break;
	}
	with Floor {
		minx = min(minx, bbox_left);
		miny = min(miny, bbox_top);
		maxx = max(maxx, bbox_right);
		maxy = max(maxy, bbox_bottom);
		nt3d_geometry_updated = true; // this script is run upon detection of a Floor lacking this property
	}
	//trace_time();
	if surface_exists(global.surf_floors) {
		surface_destroy(global.surf_floors);
	}
	global.surf_floors = surface_create(maxx+1-minx, maxy+1-miny);
	surface_set_target(global.surf_floors);
	draw_clear_alpha(c_black, 0);
	with instances_matching(Floor, "depth", 10) {
		draw_sprite_ext(sprite_index, image_index, x - minx, y - miny, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with instances_matching_lt(Floor, "depth", 10) {
		draw_sprite(sprite_index, image_index, x-minx, y-miny);
	}
	surface_reset_target();
	global.surf_floors_x = minx;
	global.surf_floors_y = miny;
	var w = game_width;
	var h = game_height;
	//trace_time("Floor drawing");
	
	// Part II: Walls
	// using a vertex buffer for this one
	if instance_number(Wall) > 0 {
		//trace_time();
		if global.wall_vertex_buffer != null {
			vertex_delete_buffer(global.wall_vertex_buffer);
		}
		var vbuf = vertex_create_buffer();
		// the format will have to be triangles instead of a triangle strip, because I want to fit all walls in a single buffer
		// theoretically contiguous sections of wall could be a triangle strip, but then you'd have to spend time determining which walls those are
		vertex_begin(vbuf, global.wall_vertex_format);
		with Wall {
			if(!sprite_exists(sprite_index)){
				continue;
			}
			try{
				var uvs = sprite_get_uvs(sprite_index, image_index);
			}catch(err){
				continue;
			}
			if(array_length(uvs) == 0){
				continue;
			}
			// cut away the green bits (top half)
			uvs[0] = (uvs[0] + uvs[2]) / 2;
			uvs[1] = (uvs[1] + uvs[3]) / 2;
			if position_meeting(x-8, y+8, Floor) { // x-
				// triangle 1 (top-left, bottom-left, top-right)
				vertex_position_3d(vbuf, x, y, 1);
				vertex_color(vbuf, c_gray, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[1]);
				vertex_position_3d(vbuf, x, y, 0);
				vertex_color(vbuf, c_gray, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[3]);
				vertex_position_3d(vbuf, x, y+16, 1);
				vertex_color(vbuf, c_gray, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[1]);
				// triangle 2 (top-right, bottom-left, bottom-right)
				vertex_position_3d(vbuf, x, y+16, 1);
				vertex_color(vbuf, c_gray, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[1]);
				vertex_position_3d(vbuf, x, y, 0);
				vertex_color(vbuf, c_gray, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[3]);
				vertex_position_3d(vbuf, x, y+16, 0);
				vertex_color(vbuf, c_gray, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[3]);
			}
			if position_meeting(x+8, y+24, Floor) { // y-
				// triangle 1
				vertex_position_3d(vbuf, x, y+16, 1);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[1]);
				vertex_position_3d(vbuf, x, y+16, 0);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[3]);
				vertex_position_3d(vbuf, x+16, y+16, 1);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[1]);
				// triangle 2
				vertex_position_3d(vbuf, x+16, y+16, 1);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[1]);
				vertex_position_3d(vbuf, x, y+16, 0);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[3]);
				vertex_position_3d(vbuf, x+16, y+16, 0);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[3]);
			}
			if position_meeting(x+24, y+8, Floor) { // x+
				// triangle 1
				vertex_position_3d(vbuf, x+16, y+16, 1);
				vertex_color(vbuf, c_white, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[1]);
				vertex_position_3d(vbuf, x+16, y+16, 0);
				vertex_color(vbuf, c_white, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[3]);
				vertex_position_3d(vbuf, x+16, y, 1);
				vertex_color(vbuf, c_white, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[1]);
				// triangle 2
				vertex_position_3d(vbuf, x+16, y, 1);
				vertex_color(vbuf, c_white, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[1]);
				vertex_position_3d(vbuf, x+16, y+16, 0);
				vertex_color(vbuf, c_white, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[3]);
				vertex_position_3d(vbuf, x+16, y, 0);
				vertex_color(vbuf, c_white, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[3]);
			}
			if position_meeting(x+8, y-8, Floor) { // y+
				// triangle 1
				vertex_position_3d(vbuf, x+16, y, 1);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[1]);
				vertex_position_3d(vbuf, x+16, y, 0);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[3]);
				vertex_position_3d(vbuf, x, y, 1);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[1]);
				// triangle 2
				vertex_position_3d(vbuf, x, y, 1);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[1]);
				vertex_position_3d(vbuf, x+16, y, 0);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[0], uvs[3]);
				vertex_position_3d(vbuf, x, y, 0);
				vertex_color(vbuf, c_ltgray, 1.0);
				vertex_texcoord(vbuf, uvs[2], uvs[3]);
			}
		}
		vertex_end(vbuf);
		vertex_freeze(vbuf);
		global.wall_vertex_buffer = vbuf;
		//trace_time("Wall update");
	}
	
	// Part III: Tops
	var minx, miny, maxx, maxy;
	with Top {
		minx = bbox_left;
		miny = bbox_top;
		maxx = bbox_right;
		maxy = bbox_bottom;
		break;
	}
	with Top {
		minx = min(minx, bbox_left);
		miny = min(miny, bbox_top);
		maxx = max(maxx, bbox_right);
		maxy = max(maxy, bbox_bottom);
	}
	with TopSmall {
		minx = min(minx, bbox_left);
		miny = min(miny, bbox_top);
		maxx = max(maxx, bbox_right);
		maxy = max(maxy, bbox_bottom);
	}
	//trace_time();
	if surface_exists(global.surf_top) {
		surface_destroy(global.surf_top);
	}
	global.surf_top = surface_create(maxx+1-minx, maxy+1-miny);
	surface_set_target(global.surf_top);
	draw_clear_alpha(c_black, 0);
	with instances_matching(Top, "depth", 10) {
		draw_sprite_ext(sprite_index, image_index, x - minx, y - miny, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with instances_matching_lt(Top, "depth", 10) {
		draw_sprite(sprite_index, image_index, x-minx, y-miny);
	}
	with instances_matching(TopSmall, "depth", 10) {
		draw_sprite_ext(sprite_index, image_index, x - minx, y - miny, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with instances_matching_lt(TopSmall, "depth", 10) {
		draw_sprite(sprite_index, image_index, x-minx, y-miny);
	}
	with instances_matching_lt(Wall, "depth", 10) {
		draw_sprite(topspr, 0, x-minx, y-miny);
	}
	surface_reset_target();
	global.surf_top_x = minx;
	global.surf_top_y = miny;
	
	/*if(global.options.autoceiling){
		if surface_exists(global.surf_top) {
			surface_destroy(global.surf_top);
		}
		global.surf_top = global.surf_floors;
		global.surf_top_x = global.surf_floors_x;
		global.surf_top_y = global.surf_floors_y;
	}*/
	//trace_time("Top drawing");
	
#define draw_dark_begin
	draw_set_projection(0);
	draw_set_alpha(0);
	draw_set_color(c_black);
	draw_rectangle(0, 0, game_width, game_height, 0);
	draw_reset_projection();
	
#define draw_dark
	draw_set_projection(0);
	draw_set_alpha(0);
	draw_set_color(c_black);
	draw_rectangle(0, 0, game_width, game_height, 0);
	draw_reset_projection();
	
#define draw_dark_end
	draw_set_projection(0);
	draw_set_alpha(0);
	draw_set_color(c_black);
	draw_rectangle(0, 0, game_width, game_height, 0);
	var eyes = 1;
	with Player if (player_find(global.camera_index) == id && race == char_eyes){eyes = 2.5;}
	draw_set_alpha(0.35);
	draw_circle(game_width/2 + ((global.smoothed_camera_angle) - (global.camera_angle)) * game_height / 50, game_height/2 + ((global.smoothed_camera_vangle) - (global.camera_vangle)) * game_height / 50, game_height * 1.5 * eyes, 0);
	draw_set_alpha(0.6);
	draw_circle(game_width/2 + ((global.smoothed_camera_angle) - (global.camera_angle)) * game_height / 100, game_height/2 + ((global.smoothed_camera_vangle) - (global.camera_vangle)) * game_height / 100, game_height*0.7 * eyes, 0);
	draw_set_alpha(1);
	draw_circle(game_width/2 + ((global.smoothed_camera_angle) - (global.camera_angle)) * game_height / 200, game_height/2 + ((global.smoothed_camera_vangle) - (global.camera_vangle)) * game_height / 200, game_height*0.25 * eyes, 0);
	if(TopCont.fog == mskNone){
		draw_set_alpha(1);
		draw_rectangle(0, 0, game_width, game_height, 0);
	}
	draw_reset_projection();

#define draw_all
	instance_destroy();
	
	with Player if (button_check(index, "horn") && global.options.debug_button) exit;
	
	var draw_gun = true;
	
	if instance_exists(Player) {
		if !instance_exists(PlayerSit) {
			with Player if (player_find(global.camera_index) == id) {
				global.camera_x = x;
				global.camera_y = y;
				global.camera_angle = gunangle;
				if(global.camera_angle < 90 && global.smoothed_camera_angle > 270){global.smoothed_camera_angle -= 360;}
				if(global.camera_angle > 270 && global.smoothed_camera_angle < 90){global.smoothed_camera_angle += 360;}
				global.smoothed_camera_angle = (global.smoothed_camera_angle*(100/max(1,abs(global.camera_angle - global.smoothed_camera_angle))) + global.camera_angle) / (100/max(1,abs(global.camera_angle - global.smoothed_camera_angle))+1)
				global.camera_vangle = vertangle;
				global.smoothed_camera_vangle = (global.smoothed_camera_vangle*(100/max(1,abs(global.camera_vangle - global.smoothed_camera_vangle))) + global.camera_vangle) / (100/max(1,abs(global.camera_vangle - global.smoothed_camera_vangle))+1)
				global.camera_shake[index] = (global.camera_shake[index]*3 + sqrt(abs(view_shake[index]))/10)*(global.options.shakefactor/30);
				global.options.camera_height = global.options.player_height + z;
			}
		} else {
			draw_gun = false;
			with PlayerSit {
				global.camera_x = x;
	            global.camera_y = y + 64;
	            global.camera_angle = point_direction(global.camera_x,global.camera_y,x,y);
				global.camera_vangle = 0;
	            global.options.camera_height = global.options.player_height + (max(0, 64 * TopCont.fade));
			}
		}
	} else if instance_exists(CampChar) {
		global.camera_angle = 90;
		global.camera_vangle = 0;
		global.options.camera_height = 12;
		
		var _x, _y;
		with Campfire {
			_x = x;
			_y = y;
		}
		
		var n = player_get_race_id(global.camera_index);
		if(n > 0) with(instances_matching(CampChar, "num", n)){
			_x = x;
			_y = y;
		}
		global.camera_x += (_x - global.camera_x) * (current_time_scale / 3);
		global.camera_y += ((_y + 20) - global.camera_y) * (current_time_scale / 3);
	}
	
	var fog_color = merge_color(background_color, c_black, 0.5);
	draw_clear(fog_color);
	
	
	var new_floors = instances_matching_ne(Floor, "nt3d_geometry_updated", true);
	if(instance_exists(SpiralCont)){
		global.wasPaused = true;
	}
	if (!instance_exists(GenCont) && ((array_length(new_floors) > 0 || !surface_exists(global.surf_floors)) || global.wasPaused || 
global.wallNum != instance_number(Wall))) {
		global.wallNum = instance_number(Wall);
		global.wasPaused = false;
		update_level_geometry();
		// in a non-modded game, Floors are never destroyed, and Walls are created only when new Floors (FloorExplos) are created
		// except for Throne II replacing all Walls by InvisiWalls, but that's already handled below
		// It also checks if the game was paused because that destroys surfaces
	}
	
	d3d_start();
	draw_set_alpha_test(true); // this is necessary
	d3d_set_hidden(true);
	
	//Skybox
	if(!file_loaded("NT3D/Skybox " + string(GameCont.area) + ".png")){
		file_load("NT3D/Skybox " + string(GameCont.area) + ".png");
	}else if(!ds_map_exists(global.custom, "Skybox " + string(GameCont.area))){
		if(file_exists("NT3D/Skybox " + string(GameCont.area) + ".png")){
			ds_map_set(global.custom, "Skybox " + string(GameCont.area), sprite_add("NT3D/Skybox " + string(GameCont.area) + ".png", 1, 0, 0));
		}else{
			ds_map_set(global.custom, "Skybox " + string(GameCont.area), null);
		}
	}
	var vd = global.options.view_dist;
	if(global.options.skybox && ds_map_exists(global.custom, "Skybox " + string(GameCont.area)) && ds_map_find_value(global.custom, "Skybox " + string(GameCont.area)) != null && instance_exists(player_find(global.camera_index))){
		d3d_set_projection_ext(global.camera_x, global.camera_y, global.options.camera_height,
			global.camera_x + dcos(global.camera_vangle) * dcos(-global.camera_angle), global.camera_y + dcos(global.camera_vangle) * dsin(-global.camera_angle), global.options.camera_height + dsin(global.camera_vangle),
			dsin(-global.camera_vangle) * dcos(-global.camera_angle), dsin(-global.camera_vangle) * dsin(-global.camera_angle), dcos(global.camera_vangle),
			2*darctan(dtan(global.options.FOV/2) * (game_height/game_width)), game_width/game_height, 0.01, vd * 2); // FOV argument is vertical, not horizontal
		d3d_transform_set_translation(player_find(global.camera_index).x - vd, player_find(global.camera_index).y - vd, global.options.camera_height + vd);
		//draw_sprite_part_ext(sprite:index, subimg:number, left:number, top:number, width:number, height:number, x:number, y:number, xscale:number, yscale:number, :color, alpha:number)
		var skybox = ds_map_find_value(global.custom, "Skybox " + string(GameCont.area));
		draw_sprite_part_ext(skybox, 0, sprite_get_width(skybox) / 3, sprite_get_height(skybox) / 3, sprite_get_width(skybox)/3, sprite_get_height(skybox)/3, 0,0, (vd*2)/(sprite_get_width(skybox)/3),(vd*2)/(sprite_get_height(skybox)/3), c_white, 1);

		d3d_transform_set_rotation_x(90);
		//d3d_transform_add_rotation_z(90);
		d3d_transform_add_translation(player_find(global.camera_index).x - vd, player_find(global.camera_index).y - vd, global.options.camera_height + vd);
		draw_sprite_part_ext(skybox, 0, sprite_get_width(skybox)*2/3, sprite_get_height(skybox) / 3, sprite_get_width(skybox)/3, sprite_get_height(skybox)/3, 0,0, (vd*2)/(sprite_get_width(skybox)/3),(vd*2)/(sprite_get_height(skybox)/3), c_white, 1);
		
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(player_find(global.camera_index).x - vd, player_find(global.camera_index).y + vd, global.options.camera_height + vd);
		draw_sprite_part_ext(skybox, 0, 0, sprite_get_height(skybox) / 3, sprite_get_width(skybox)/3, sprite_get_height(skybox)/3, 0,0, (vd*2)/(sprite_get_width(skybox)/3),(vd*2)/(sprite_get_height(skybox)/3), c_white, 1);
		
		d3d_transform_set_rotation_y(-90);
		d3d_transform_add_translation(player_find(global.camera_index).x - vd, player_find(global.camera_index).y - vd, global.options.camera_height + vd);
		draw_sprite_part_ext(skybox, 0, sprite_get_width(skybox) / 3, sprite_get_height(skybox)*2/3, sprite_get_width(skybox)/3, sprite_get_height(skybox)/3, 0,0, (vd*2)/(sprite_get_width(skybox)/3),(vd*2)/(sprite_get_height(skybox)/3), c_white, 1);
		
		d3d_transform_set_rotation_y(-90);
		d3d_transform_add_translation(player_find(global.camera_index).x + vd, player_find(global.camera_index).y - vd, global.options.camera_height + vd);
		draw_sprite_part_ext(skybox, 0, sprite_get_width(skybox) / 3,0, sprite_get_width(skybox)/3, sprite_get_height(skybox)/3, 0,0, (vd*2)/(sprite_get_width(skybox)/3),(vd*2)/(sprite_get_height(skybox)/3), c_white, 1);
		
		d3d_transform_set_rotation_y(180);
		d3d_transform_add_translation(player_find(global.camera_index).x + vd, player_find(global.camera_index).y - vd, global.options.camera_height - vd);
		draw_sprite_part_ext(skybox, 0, 0,0, sprite_get_width(skybox)/3, sprite_get_height(skybox)/3, 0,0, (vd*2)/(sprite_get_width(skybox)/3),(vd*2)/(sprite_get_height(skybox)/3), c_white, 1);
	}
	
	d3d_set_projection_ext(global.camera_x, global.camera_y, global.options.camera_height - global.camera_shake[global.camera_index],
		global.camera_x + dcos(global.camera_vangle) * dcos(-global.camera_angle), global.camera_y + dcos(global.camera_vangle) * dsin(-global.camera_angle), global.options.camera_height + dsin(global.camera_vangle),
		dsin(-global.camera_vangle) * dcos(-global.camera_angle), dsin(-global.camera_vangle) * dsin(-global.camera_angle), dcos(global.camera_vangle),
		2*darctan(dtan(global.options.FOV/2) * (game_height/game_width)), game_width/game_height, 0.02, global.options.view_dist*4); // FOV argument is vertical, not horizontal
		// I can't quite tell, but it seems projection far plane and fog far plane don't 100% match up? Adding a factor of 4 just in case
	
	d3d_set_fog(true, fog_color, 0, global.options.view_dist); // <-- this sucks, I want my correct distance fog back (apparently called "range-based" in DirectX)
	// there's just no way to enable that in GML
	// but GM fog is apparently shader-based, so... why?
	
	d3d_transform_set_identity();
	d3d_transform_set_translation(0, 0, 0);
	if(global.surf_floors != -1){draw_surface(global.surf_floors, global.surf_floors_x, global.surf_floors_y);}
	
	/*with(surface_setup("FloorGrab", game_width, game_height, game_screen_get_width_nonsync() / game_width)){
		draw_set_blend_mode_ext(bm_one, bm_zero);
		draw_surface(surf, view_xview[0], view_yview[0]);
		//draw_surface_scale(surf, 0, 0, 0.5 * (1 / scale));
		draw_set_blend_mode(bm_normal);
	}*/
	
	/*with(Floor){
		if("z" not in self){
			fl1 = instance_nearest(x+1,y,Floor);
			fl2 = instance_nearest(x-1,y,Floor);
			fl3 = instance_nearest(x,y+1,Floor);
			fl4 = instance_nearest(x,y-1,Floor);
			z1 = 0;
			z2 = 0;
			z3 = 0;
			z4 = 0;
			if("z" in fl1){z1 = fl1.z}
			if("z" in fl2){z2 = fl2.z}
			if("z" in fl3){z3 = fl3.z}
			if("z" in fl4){z4 = fl4.z}
			z = (z1+z2+z3+z4)/4 + random(5);
			z=0;
		}
		d3d_transform_set_translation(0, 0, z);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}*/
		
	d3d_transform_set_identity();
	if instance_number(Wall) > 0 && !is_undefined(global.wall_vertex_buffer) {
		d3d_transform_set_scaling(1, 1, global.options.wall_height);
		vertex_submit(global.wall_vertex_buffer, pr_trianglelist, sprite_get_texture(instance_nearest(10000,10000,Wall).sprite_index, instance_nearest(10000,10000,Wall).image_index)); // who knew that GPUs are actually blazing fast
	}
	
	d3d_transform_set_identity();
	d3d_transform_add_translation(0,0,global.options.wall_height * (instance_number(Wall) > 0));
	if(global.surf_top != -1){draw_surface(global.surf_top, global.surf_top_x, global.surf_top_y);}
	
	// cache global variables
	var cx = global.camera_x;
	var cy = global.camera_y;
	var cz = global.options.camera_height;
	var ca = global.camera_angle;
	var projz = global.options.projectile_height;
	// using matrix_set with this pre-built matrix instead of doing the 2 d3d_transforms saves about 2.5 microseconds. AMAZING
	var transform_facing = matrix_build(0, 0, 0, global.camera_vangle+90, 0, ca-90, 1, 1, 1); 
	
	//indicator for the last few enemies
	if(global.options.enemy_indicator){
		with instances_viewbounds(enemy, 100) {
			if(instance_number(enemy) < 5 && object_index != Mimic && object_index != SuperMimic && !("name" in self && is_string(name) && string_count("mimic", name) > 0)){
				matrix_set(matrix_world, transform_facing);
				d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
				d3d_transform_add_translation(0, 0, global.options.wall_height);
				draw_sprite_ext(sprEmoteIndicator, 0, 0, 0, 2, 2, 0, c_red, global.indicator_timer / 120);
				global.indicator_timer++;
			}
		}
		if(instance_number(enemy) > 5 && global.indicator_timer > 0){
			global.indicator_timer = 0;
		}
	}
	with instances_viewbounds(instances_matching_ne(instances_matching_ne(enemy, "object_index", ScrapBossMissile), "object_index", DogMissile), 100) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist){continue;}
		if("z" in self){visz = (abs(z) / 8) * global.options.wall_height}
		matrix_set(matrix_world, transform_facing);
		if(object_index == Nothing){
			d3d_transform_set_rotation_x(30);
			if("visz" not in self){visz = 0;}
			visz -= (sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index)) / 2;
		}
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		if("visz" in self){d3d_transform_add_translation(0, 0, visz);}
		if(global.options.Models && lq_exists(global.models[0], object_index)){mod_script_call_nc("mod", "JSONModels", "drawModelRaw", lq_get(global.models[0], object_index));}
		else if("drawspr" in self && "drawimg" in self){draw_sprite_ext(drawspr, drawimg, 0, 0, image_xscale * right, image_yscale, image_angle, image_blend, image_alpha);}
		else{draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale * right, image_yscale, image_angle, image_blend, image_alpha);}
	}
	with(instances_viewbounds(Nothing, 100)){
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(x - sprite_width/2, y-10, sprite_get_bbox_bottom(sprNothingLeg) - sprite_get_yoffset(sprNothingLeg) - 20);
		draw_sprite_ext(sprNothingLeg, footstep * 3, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(x - sprite_width/2, y+10, sprite_get_bbox_bottom(sprNothingLeg) - sprite_get_yoffset(sprNothingLeg) - 30);
		draw_sprite_ext(sprNothingLeg, footstep * 3 + 4, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(x - sprite_width/2, y+30, sprite_get_bbox_bottom(sprNothingLeg) - sprite_get_yoffset(sprNothingLeg) - 40);
		draw_sprite_ext(sprNothingLeg, footstep * 3 + 8, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(x + sprite_width/2, y-10, sprite_get_bbox_bottom(sprNothingLeg) - sprite_get_yoffset(sprNothingLeg) - 20);
		draw_sprite_ext(sprNothingLeg, footstep * 3 + 4, 0, 0, -image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(x + sprite_width/2, y+10, sprite_get_bbox_bottom(sprNothingLeg) - sprite_get_yoffset(sprNothingLeg) - 30);
		draw_sprite_ext(sprNothingLeg, footstep * 3 + 8, 0, 0, -image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(x + sprite_width/2, y+30, sprite_get_bbox_bottom(sprNothingLeg) - sprite_get_yoffset(sprNothingLeg) - 40);
		draw_sprite_ext(sprNothingLeg, footstep * 3, 0, 0, -image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with instances_viewbounds(becomenemy, 100) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist || !visible){continue;}
		if("z" in self){visz = (abs(z) / 8) * global.options.wall_height}
		if("right" not in self){right = 1;}
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		if("visz" in self){d3d_transform_add_translation(0, 0, visz);}
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale * right, image_yscale, image_angle, image_blend, image_alpha);
	}
	with instances_viewbounds(SnowTankExplode, 100) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist){continue;}
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale * right, image_yscale, image_angle, image_blend, image_alpha);
	}
	with instances_viewbounds(Van, 100) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist){continue;}
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(right > 0 ? bbox_left : bbox_right+1, bbox_top, bbox_bottom - bbox_top + 1);
		draw_sprite_part_ext(global.sprVan, 0, 0, 0, 74, 44, 0, 0, right, 1, image_blend, 1);
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(right > 0 ? bbox_left : bbox_right+1, bbox_bottom+1, bbox_bottom - bbox_top + 1);
		draw_sprite_part_ext(global.sprVan, 0, 0, 0, 74, 44, 0, 0, right, 1, image_blend, 1);
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_rotation_z(-90);
		d3d_transform_add_translation(bbox_left, bbox_top, bbox_bottom - bbox_top + 1);
		draw_sprite_part_ext(global.sprVan, 0, right > 0 ? 74 + 44 : 74, 0, 44, 44, 0, 0, 1, 1, image_blend, 1);
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_rotation_z(-90);
		d3d_transform_add_translation(bbox_right + 1, bbox_top, bbox_bottom - bbox_top + 1);
		draw_sprite_part_ext(global.sprVan, 0, right < 0 ? 74 + 44 : 74, 0, 44, 44, 0, 0, 1, 1, image_blend, 1);
	}
	with instances_viewbounds(instances_matching_ne(enemy, "hasgunspr", 1), 100) {
		hasgunspr = 1;
		switch(object_index){
			case BanditBoss:
				gunspr = sprBanditBossGun;
			break;
			case Raven:
				gunspr = sprRavenGun;
			break;
			case Sniper:
				gunspr = sprSniperGun;
			break;
			case Gator:
				gunspr = sprShotgun; //?
			break;
			case BuffGator:
				gunspr = sprBuffGatorFlakCannon;
			break;
			case Grunt:
				gunspr = sprPopoGun;
			break;
			case Inspector:
				gunspr = sprPopoSlugger;
			break;
			case EliteGrunt:
				gunspr = sprElitePopoGun;
			break;
			case EliteInspector:
				gunspr = sprEnergyBaton;
			break;
			case MeleeBandit:
				gunspr = sprPipe;
			break;
			case JungleBandit:
				gunspr = sprJungleBanditGun;
			break;
		}
	}
	with instances_viewbounds(instances_matching(enemy, "object_index", Shielder, EliteShielder), 100) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist){continue;}
		switch(object_index){
			case Shielder:
				gunspr = sprPopoHeavyGun;
			break;
			case EliteShielder:
				gunspr = sprPopoPlasmaMinigun
			break;
			default:
				gunspr = 0;
			break;
		}
		with(instances_matching(PopoShield, "creator", self)){
			var dir = point_direction(x,y,global.camera_x, global.camera_y);
			matrix_set(matrix_world, transform_facing);
			//lengthdir_*(1,dir) is for the purpose of ensuring that the shield sprites are drawn in *front* of the shielders)
			d3d_transform_add_translation(x + lengthdir_x(1,dir), y + lengthdir_y(1, dir), sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
			var spr = sprite_index, ind = image_index;
			draw_sprite_ext(spr, ind, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		}
	}
	
	with instances_viewbounds(instances_matching_ge(enemy, "gunspr", 0), 100) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist){continue;}
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(sprite_get_xoffset(gunspr)-wkick - sprite_get_width(gunspr)/3, sprite_get_width(sprite_index)/4, sprite_get_height(sprite_index)*2/5); // forward-backward, left-right, up-down
		if("visz" in self){d3d_transform_add_translation(0, 0, visz);}
		d3d_transform_add_rotation_z(gunangle + ("wepangle" in self ? wepangle : 0));
		d3d_transform_add_translation(x, y, 0);
		draw_sprite_ext(gunspr, 0, 0, 0, 1, 1, 0, c_white, 1);
	}
	
	with(instances_matching(Sniper, "gonnafire", true)){
		d3d_transform_set_identity();
		d3d_transform_add_translation(x, y, sprite_get_height(sprite_index)*2/5);
		draw_sprite_ext(sprLaserSight, 0, 0, 0, distance_to_object(target)/sprite_get_width(sprLaserSight) + 12, 1, gunangle, c_white, 1);
	}
	with(instances_matching_ge(SnowTank, "ammo", 1)){
		d3d_transform_set_identity();
		d3d_transform_add_translation(x, y, sprite_get_height(sprite_index)/5+1);
		draw_sprite_ext(sprLaserSight, 0, 0, 0, distance_to_object(target)/sprite_get_width(sprLaserSight) + 12, 1, gunangle, c_white, 1);
	}
	with instances_viewbounds(Trap, 100) {
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(0, -1, sprite_height); // forward-backward, left-right, up-down
		d3d_transform_add_rotation_z(0);
		d3d_transform_add_translation(x, y, 0);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, image_alpha);
		
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(0, 17, sprite_height); // forward-backward, left-right, up-down
		d3d_transform_add_rotation_z(0);
		d3d_transform_add_translation(x, y, 0);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, image_alpha);
		
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(-16, 17, sprite_height); // forward-backward, left-right, up-down
		d3d_transform_add_rotation_z(90);
		d3d_transform_add_translation(x, y, 0);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, image_alpha);
		
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(-16, -1, sprite_height); // forward-backward, left-right, up-down
		d3d_transform_add_rotation_z(90);
		d3d_transform_add_translation(x, y, 0);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, image_alpha);
	}
	
	with instances_viewbounds(prop, 200) {
		if("z" in self){visz = (abs(z) / 8) * global.options.wall_height}
		if (object_index != NothingIntroMask) {
			matrix_set(matrix_world, transform_facing);
			if(object_index == Generator || object_index == GeneratorInactive || object_index == NothingInactive){
				d3d_transform_set_rotation_x(30);
				if("visz" not in self){visz = 0;}
				visz -= (sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index)) / 2;
			}
			if(object_index == BigTV || object_index == VenuzTV || object_index == VenuzCouch){
				d3d_transform_set_rotation_x(90);
			}
			if("visz" in self){d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1 + visz);}
			else{d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);}
			if object_index == Campfire d3d_transform_add_translation(0, 0, -8);
			if object_index == LogMenu d3d_transform_add_translation(0, -4, 0);
			draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		}
	}
	
	with (BecomeNothing) {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_set_rotation_x(30);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprNothingOn) - sprite_get_yoffset(sprNothingOn) + 1 - 
			(sprite_get_bbox_bottom(sprNothingOn) - sprite_get_yoffset(sprNothingOn)) / 2);
		draw_sprite_ext(sprNothingOn, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, 1);
		draw_self();
	}
	
	with instances_viewbounds(NothingDeath, 200) {
		matrix_set(matrix_world, transform_facing);
		visz = 0;
		if("z" in self){visz = (abs(z) / 8) * global.options.wall_height}
		d3d_transform_set_rotation_x(30);
		visz -= (sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index)) / 2;
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1 + visz);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with instances_viewbounds(LastDie, 200) {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with instances_viewbounds(TopPot, 200) {
		if("z" in self){visz = (abs(z) / 8) * global.options.wall_height}
		matrix_set(matrix_world, transform_facing);
		if("visz" in self){d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) - 12 + global.options.wall_height + visz);}
		else{d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) - 12 + global.options.wall_height);}
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with instances_viewbounds(Bones, 200) {
		if("z" in self){visz = (abs(z) / 8) * global.options.wall_height}
		d3d_transform_set_rotation_x(90);
		if("visz" in self){d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) - 1 + global.options.wall_height + visz);}
		else{d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) -1  + global.options.wall_height);}
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with YungCuz {
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(x, y+1, 15);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with NothingSpiral {
		with(Floor){
			d3d_transform_set_rotation_x(90);
			//d3d_transform_add_translation(x, y, -10);
			//draw_sprite_ext(sprBackFloor, 0, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
			d3d_transform_add_translation(x-sprite_width/2, y+sprite_height/2, -0.5);
			draw_sprite_part(sprBackFloor2, 0, 0, 55, sprite_get_width(sprBackFloor2), sprite_get_height(sprBackFloor2), 0, 0);
		}
	}
	
	with Nothing2Death {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with CrownPed {
		d3d_transform_set_translation(x, y, 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with CrownPickup {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with Campfire {
		matrix_set(matrix_world, transform_facing);
		var boom = 1 + 0.2 * (0.5 + 0.5*dsin(current_frame*2.1));
		d3d_transform_add_scaling(3*boom, 3*boom, 3*boom);
		d3d_transform_add_translation((x + global.camera_x) / 2, (y + global.camera_y)/2 -100, 90);
		draw_set_halign(fa_center);
		draw_set_font(4);
		draw_text(0, 0, "NT3D");
		matrix_set(matrix_world, transform_facing);
		draw_set_halign(fa_left);
		draw_set_font(3);
	}
	
	//corpse max
	var i = 0;
	
	with instances_viewbounds(Corpse, 100) {
		var rot = 90 - ("nt3d_collapse" in self ? nt3d_collapse : 0) * (75/CORPSE_TIME);
		d3d_transform_set_rotation_x(rot);
		d3d_transform_add_rotation_z(ca - 90);
		d3d_transform_add_translation(x, y, dsin(rot) * (bbox_bottom-y+1) + 0.5 + (global.options.wall_height * (distance_to_object(instance_nearest(x, y, Floor)) > distance_to_object(instance_nearest(x, y, Floor)) > distance_to_object(instance_nearest(x, y, Wall)) + 16))); // +0.5 fixes some slight z-fighting with the floor
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
		if(i < global.options.corpse_max){i++;}
		else{break;}
	}
	
	//lag reducer for projectile
	i = 0;
	var sca = dsin(-ca);
	var cca = dcos(-ca);
	with instances_viewbounds(projectile, 40) {
		var sprite;
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist && sprite_height < global.options.view_dist/2 && sprite_width < global.options.view_dist/2){continue;}
		if(sprite_index >= 0){
			sprite = sprite_index;
		}else{
			continue;
		}
		var tempz = projz;
		if("z" in self){
			tempz = z;
		}
		if(i > global.options.faster_projectile_max || object_index == Flame || object_index == TrapFire){
			matrix_set(matrix_world, transform_facing);
			d3d_transform_add_translation(x, y, (sprite_get_bbox_bottom(sprite) - sprite_get_yoffset(sprite))/2 + 1 + tempz);
			draw_sprite(sprite, image_index, 0, 0);
		}else if(dcos(-ca) * (x - cx) + dsin(-ca) * (y - cy) > 1500 || i > global.options.fancy_projectile_max){
			i++;
			//old method for speed
			matrix_set(matrix_world, transform_facing);
			d3d_transform_add_translation(x, y, (sprite_get_bbox_bottom(sprite) - sprite_get_yoffset(sprite))/2 + 1 + tempz);
			// math incoming
			var horizpos = -sca * (x - cx) + cca * (y - cy);
			var odepth = cca * (x - cx) + sca * (y - cy);
			var horizposderiv = -sca * hspeed + cca * vspeed;
			var odepthderiv = cca * hspeed + sca * vspeed;
			//var horizscreenpos = horizpos / odepth;
			var horizscreenposderiv = ((odepth * horizposderiv) - (odepthderiv * horizpos)) / (odepth * odepth);
			//var vertscreenpos = (cz - tempz) / odepth;
			var vertscreenposderiv = -(cz - tempz) * odepthderiv / (odepth * odepth);
			draw_sprite_ext(sprite, image_index, 0, 0, image_xscale, image_yscale, point_direction(0, 0, horizscreenposderiv, vertscreenposderiv), image_blend, image_alpha);
		}else if("speed_z" in self){
			i++;
			d3d_transform_set_identity()
			var t = sprite_get_texture(sprite,image_index);
			var w = texture_get_width(t);
			var h = texture_get_height(t);
			var uvs = sprite_get_uvs(sprite,image_index);
			var sprite_w = (uvs[2] - uvs[0])*w*image_xscale;
			var sprite_h = (uvs[3] - uvs[1])*h*image_yscale;
            for(var i2 = 0; i2<4;i2++){
                d3d_transform_set_rotation_x((arctan(sprite_h/sprite_w)/pi) * 180);
                d3d_transform_add_translation(0, 0, -lengthdir_y(sprite_width*(sprite_xoffset/sprite_width-0.5), (arctan(sprite_h/sprite_w)/pi) * 180));
                d3d_transform_add_rotation_y(90+i2*(360/4));//+current_frame*40);
				d3d_transform_add_rotation_x(-point_direction(0, 0, speed, speed_z));
                d3d_transform_add_rotation_z(image_angle-90);//global.camera_angle+90);
                d3d_transform_add_translation(x, y, tempz);
                draw_sprite_ext(sprite, image_index, 0, 0,image_xscale,image_yscale,90,image_blend,image_alpha);

            }
		}else{
			i++;
			d3d_transform_set_identity()
			var t = sprite_get_texture(sprite,image_index);
			var w = texture_get_width(t);
			var h = texture_get_height(t);
			var uvs = sprite_get_uvs(sprite,image_index);
			var sprite_w = (uvs[2] - uvs[0])*w*image_xscale;
			var sprite_h = (uvs[3] - uvs[1])*h*image_yscale;
            for(var i2 = 0; i2<4;i2++){
                d3d_transform_set_rotation_x((arctan(sprite_h/sprite_w)/pi) * 180);
                d3d_transform_add_translation(0, 0, -lengthdir_y(sprite_width*(sprite_xoffset/sprite_width-0.5), (arctan(sprite_h/sprite_w)/pi) * 180));
                d3d_transform_add_rotation_y(90+i2*(360/4));//+current_frame*40);
                d3d_transform_add_rotation_z(image_angle-90);//global.camera_angle+90);
                d3d_transform_add_translation(x, y, tempz);
                draw_sprite_ext(sprite, image_index, 0, 0, image_xscale,image_yscale,90,image_blend,image_alpha);
            }
		}
	}
	with instances_viewbounds([DogMissile, ScrapBossMissile], 40) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist && sprite_height < global.options.view_dist/2 && sprite_width < global.options.view_dist/2){continue;}
		var tempz = projz;
		if("z" in self){
			tempz = z;
		}
		d3d_transform_set_identity()
		if(!sprite_exists(sprite_index)){continue;}
		var t = sprite_get_texture(sprite_index,image_index);
		var w = texture_get_width(t);
		var h = texture_get_height(t);
		var uvs = sprite_get_uvs(sprite_index,image_index);
		var sprite_w = (uvs[2] - uvs[0])*w*image_xscale;
		var sprite_h = (uvs[3] - uvs[1])*h*image_yscale;
		for(var i2 = 0; i2<4;i2++){
			d3d_transform_set_rotation_x((arctan(sprite_h/sprite_w)/pi) * 180);
			d3d_transform_add_translation(0, 0, -lengthdir_y(sprite_width*(sprite_xoffset/sprite_width-0.5), (arctan(sprite_h/sprite_w)/pi) * 180));
			d3d_transform_add_rotation_y(90+i2*(360/4));//+current_frame*40);
			d3d_transform_add_rotation_z(image_angle-90);//global.camera_angle+90);
			d3d_transform_add_translation(x, y, global.options.projectile_height);
			draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale,image_yscale,90,image_blend,image_alpha);
		}
	}
	d3d_transform_set_translation(0, 0, projz);
	
	with instances_viewbounds([chestprop, ChestOpen], 40) {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, bbox_bottom - y + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
	}
	
	with instances_viewbounds([HPPickup, AmmoPickup, RoguePickup], 20) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist){continue;}
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, bbox_bottom - y + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
	}
	
	with instances_viewbounds(WepPickup, 50) {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_height);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
	}
	
	//lag reducer for effects
	var i = 0;
	var effectmax = 50;
	
	with instances_viewbounds(instances_matching_ne(Effect, "object_index", BoltStick, BoltTrail, DiscTrail, PlasmaTrail, /*CrystTrail,*/PopupText, Scorchmark, TrapScorchMark, MeltSplat, BloodStreak, AcidStreak, PhantomBolt), 50) {
		if(object_index == BoltStick && target.object_index == Player){continue;}
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist){continue;}
		var xoff = 0, yoff = 0;
        if "addx" in self{
            xoff = addx;
            yoff = addy;
        }
        matrix_set(matrix_world, transform_facing);
        d3d_transform_add_translation(x, y, sprite_height/2);
		if("z" in self){d3d_transform_add_translation(0, 0, z);}
        draw_sprite_ext(sprite_index, image_index, xoff, -yoff, image_xscale, image_yscale, 0, image_blend, 1);
        if(i < effectmax){i++;}
        else{break;}
	}
	
	with instances_viewbounds(instances_matching(Effect, "object_index", BoltStick, BoltTrail, DiscTrail, PlasmaTrail, CrystTrail, PhantomBolt), 50) {
		if(object_index == BoltStick && instance_exists(target) && target.object_index == Player){continue;}
		d3d_transform_set_translation(x, y, global.options.projectile_height);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, 1);
		if(object_index == BoltStick){
			d3d_transform_set_rotation_x(90);
			d3d_transform_add_rotation_z(image_angle);
			d3d_transform_add_translation(x, y, global.options.projectile_height);
			draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
		}
		if(i < effectmax){i++;}
		else{break;}
	}
	
	with instances_viewbounds(instances_matching(Effect, "object_index", PopupText), 50) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist){continue;}
		matrix_set(matrix_world, transform_facing);
		y = ystart;
		d3d_transform_add_translation(x, y, 100 - time*5);
		draw_set_halign(1)
		if(text != ""){_text = text;}
		text = "";
		draw_text_nt(0,0,_text);
		draw_set_halign(0);
		if(i < effectmax){i++;}
		else{break;}
	}
	
	with(Player){
		if(skill_get(mut_strong_spirit) > 0 && canspirit == true && !array_length(instances_matching(StrongSpirit, "creator", id))){
			matrix_set(matrix_world, transform_facing);
			d3d_transform_add_translation(x + lengthdir_x(15,gunangle), y + lengthdir_y(15,gunangle), global.options.camera_height-5);
			draw_sprite_ext(sprStrongSpirit, 1, 0, 0, 2, 2, 0, c_white, 0.5);
		}
	}
	with(instances_matching(instances_matching_ne(Player, "bonus_spirit", null), "visible", true)){
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x + lengthdir_x(15,gunangle), y + lengthdir_y(15,gunangle), global.options.camera_height-5);
		for(var i = 0; i < array_length(bonus_spirit); i++){
			d3d_transform_add_translation(0,0,14);
			draw_sprite_ext(sprStrongSpirit, 1, 0, 0, 2, 2, 0, c_white, 0.5);
		}
	}
	
	with instances_viewbounds(PizzaEntrance, 50) {
		if("z" in self){visz = (abs(z) / 8) * global.options.wall_height}
		if(depth > 2){
			d3d_transform_set_rotation_z(0);
			d3d_transform_set_translation(x, y, 1);
		}else{
			matrix_set(matrix_world, transform_facing);
			d3d_transform_add_translation(x, y, bbox_bottom - y + 1);
		}
		if("visz" in self){d3d_transform_add_translation(0, 0, visz);}
		if("grapple_sprite" in self){
			draw_sprite_ext(grapple_sprite, 1, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
			d3d_transform_set_rotation_z(direction + lendir);
			d3d_transform_add_translation(x-5, y, projz);
			draw_sprite_ext(mod_variable_get("race", "grappler", "sprite").hand, grapple_hasitem, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
		}else if("spr_air" in self){draw_sprite_ext(spr_air, 1, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);}
		else{draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);}
	}
	
	with instances_viewbounds(CustomObject, 50) {
		if("z" in self){visz = (abs(z) / 8) * global.options.wall_height}
		if(depth > 2){
			d3d_transform_set_rotation_z(0);
			d3d_transform_set_translation(x, y, 1);
		}else{
			matrix_set(matrix_world, transform_facing);
			d3d_transform_add_translation(x, y, bbox_bottom - y + 1);
		}
		if("visz" in self){d3d_transform_add_translation(0, 0, visz);}
		if("grapple_sprite" in self){
			draw_sprite_ext(grapple_sprite, 1, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
			d3d_transform_set_rotation_z(direction + lendir);
			d3d_transform_add_translation(x-5, y, projz);
			draw_sprite_ext(mod_variable_get("race", "grappler", "sprite").hand, grapple_hasitem, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
		}else if("spr_air" in self){draw_sprite_ext(spr_air, 1, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);}
		else{draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);}
	}
	with instances_viewbounds(CustomHitme, 50) {
		if("z" in self){visz = (abs(z) / 8) * global.options.wall_height}
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, bbox_bottom - y + 1);
		if("visz" in self){d3d_transform_add_translation(0, 0, visz);}
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);
	}
	
	//counting this seperately
	i = 0;
	var detailmax = 50;
	with instances_viewbounds(instances_matching(Effect, "object_index", Detail, Scorchmark, TrapScorchMark, MeltSplat, BloodStreak, AcidStreak), 50) {
		if(distance_to_point(global.camera_x, global.camera_y) > global.options.view_dist){continue;}
		d3d_transform_set_translation(0, 0, 2);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle - 90, image_blend, image_alpha);
		if(i < detailmax){i++;}
		else{break;}
	}
	
	with EmoteIndicator {
		if("setx" not in self || "sety" not in self){
			var temp = mouseaim(player_find(p));
			setx = temp[0];
			sety = temp[1];
			wave2 = wave;
		}
		wave = maxwave - current_time_scale * 1.001;
		if(wave2 >= maxwave){
			wave = maxwave;
		}
		wave2 += current_time_scale;
		x = setx;
		y = sety;
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_height/2);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, 0, image_blend, 1);

		//d3d_transform_set_translation(0, 0, 2);
		//draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle + ca - 90, image_blend, image_alpha);
	}
	
	d3d_transform_set_translation(0, 0, 3);
	
	with instances_viewbounds([Explosion, MeatExplosion, PlasmaImpact, MineExplosion], 50) {
		//matrix_set(matrix_world, transform_facing);
		//d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		//draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		d3d_transform_set_identity()
		if(!sprite_exists(sprite_index)){continue;}
		var t = sprite_get_texture(sprite_index,image_index);
		var w = texture_get_width(t);
		var h = texture_get_height(t);
		var uvs = sprite_get_uvs(sprite_index,image_index);
		var sprite_w = (uvs[2] - uvs[0])*w*image_xscale;
		var sprite_h = (uvs[3] - uvs[1])*h*image_yscale;
		for(var i2 = 0; i2<4;i2++){
			d3d_transform_set_rotation_x((arctan(sprite_h/sprite_w)/pi) * 180);
			d3d_transform_add_translation(0, 0, -lengthdir_y(sprite_width*(sprite_xoffset/sprite_width-0.5), (arctan(sprite_h/sprite_w)/pi) * 180));
			d3d_transform_add_rotation_y(90+i2*(360/4));//+current_frame*40);
			d3d_transform_add_rotation_z(image_angle-90);//global.camera_angle+90);
			d3d_transform_add_translation(x, y, global.options.projectile_height);
			draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale,image_yscale,90,image_blend,image_alpha);
		}
	}
	
	with instances_viewbounds(BulletHit, 40) {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, bbox_bottom - y + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with Portal {
		d3d_transform_set_translation(0, 0, 1);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		for(var i = 1000; i > 40; i-=20){
			d3d_transform_set_translation(0, 0, i);
			draw_sprite_ext(sprite_index, image_index, x, y, image_xscale/(sqrt(i)/20), image_yscale/(sqrt(i)/20), image_angle, image_blend, image_alpha);
		}
		if endgame < 100
            with Player{
                z = min(max(1,z*1.2),1000)
                fall = 0    
            }
	}
	
	with instances_viewbounds([Rad, BigRad], 20) {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, projz);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with instances_matching_ne(Player, "id", player_find(global.camera_index)) {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, (angle_difference(ca, gunangle) > 0 ? 1 : -1) * image_xscale, image_yscale, image_angle + angle, image_blend, image_alpha);
		
		var wepsprt = weapon_get_sprite(wep);
		for(var i = 1; i > 0; i-=(1/8)){
			d3d_transform_set_rotation_x(90);
			d3d_transform_add_translation(sprite_get_xoffset(wepsprt)-wkick - sprite_get_width(wepsprt)/3, i + sprite_get_width(sprite_index)/4, global.options.camera_height - sprite_get_height(wepsprt)/2 - 5); // forward-backward, left-right, up-down
			d3d_transform_add_rotation_z(gunangle + wepangle);
			d3d_transform_add_translation(x, y, 0);
			draw_sprite_ext(wepsprt, 0, 0, 0, 1, 1, 0, image_blend, 1);
		}
		
		if(race == "steroids") {
			var wepsprt = weapon_get_sprite(bwep);
			for(var i = 1; i > 0; i-=(1/8)){
				d3d_transform_set_rotation_x(90);
				d3d_transform_add_translation(sprite_get_xoffset(wepsprt)-wkick - sprite_get_width(wepsprt)/3, i - sprite_get_width(sprite_index)/4, projz + sprite_get_height(wepsprt)/2); // forward-backward, left-right, up-down
				d3d_transform_add_rotation_z(gunangle + wepangle);
				d3d_transform_add_translation(x, y, 0);
				draw_sprite_ext(wepsprt, 0, 0, 0, 1, 1, 0, image_blend, 1);
			}
		}
	}
	
	with PlayerSit {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with instances_matching_ne([CrystalShield, CrystalShieldDisappear], "creator", player_find(global.camera_index)) {
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(0, 5, 0);
		d3d_transform_add_rotation_z(ca-90);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with instances_matching([CrystalShield, CrystalShieldDisappear], "creator", player_find(global.camera_index)) {
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(0, 5, 0);
		d3d_transform_add_rotation_x(-global.camera_vangle/2);
		d3d_transform_add_rotation_z(90+ca);
		d3d_transform_add_translation(x+lengthdir_x(1, ca), y+lengthdir_y(1, ca), sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, 0.2);
	}
	
	with Tangle {
		d3d_transform_set_translation(0, 0, 2 + ((distance_to_object(instance_nearest(x,y,Floor)) > distance_to_object(instance_nearest(x,y,Wall))) * global.options.wall_height));
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with RogueStrike {
		d3d_transform_set_translation(0, 0, 4 + ((distance_to_object(instance_nearest(x,y,Floor)) > distance_to_object(instance_nearest(x,y,Wall))) * global.options.wall_height));
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with Carpet {
		d3d_transform_set_translation(0, 0, 1.25);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with Scorch {
		d3d_transform_set_translation(0, 0, 2);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with ScorchGreen {
		d3d_transform_set_translation(0, 0, 2);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with ScorchTop {
		d3d_transform_set_translation(0, 0, 2);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	with NothingBeam {
		d3d_transform_set_translation(0, 0, 4);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		d3d_transform_set_translation(0, 0, 24);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		d3d_transform_set_translation(0, 0, 14);
		d3d_transform_add_rotation_y(90);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with Sapling {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	with instances_viewbounds(Ally, 68) {
		matrix_set(matrix_world, transform_facing);
		d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		
		d3d_transform_set_rotation_x(90);
		d3d_transform_add_translation(sprite_get_xoffset(gunspr)-wkick, 4, projz); // forward-backward, left-right, up-down
		d3d_transform_add_rotation_z(gunangle);
		d3d_transform_add_translation(x, y, 0);
		draw_sprite_ext(gunspr, 0, 0, 0, 1, 1, 0, image_blend, 1);
	}
	
	with Crown {
		matrix_set(matrix_world, transform_facing);
		// Crowns are drawn at 80% size so that they don't get in the way as much
		d3d_transform_add_translation(x, y, 0.8 * (sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1));
		draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale * 0.8, image_yscale * 0.8, image_angle, image_blend, image_alpha);
	}
	
	with CampChar {
		if(is_real(num) && num < 17) {
			d3d_transform_set_rotation_x(90);
			d3d_transform_add_translation(x, y, sprite_get_bbox_bottom(sprite_index) - sprite_get_yoffset(sprite_index) + 1);
			draw_sprite_ext(sprite_index, image_index, 0, 0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		}
	}
	// seperate weapon viewmodel
	if draw_gun with player_find(global.camera_index) {
		d3d_set_hidden(false); // never obscured
		
		if(race == "steroids") {
			for(var i = 0; i < 1; i+=(1/8)){
				d3d_transform_set_rotation_x(90);
				var sprt = weapon_get_sprt(wep);
				var xoffset = (wepangle == 0) ? sprite_get_xoffset(sprt) : sprite_get_yoffset(sprt)-sprite_get_width(sprt)/2;
				var yoffset = (wepangle == 0) ? sprite_get_yoffset(sprt) : sprite_get_xoffset(sprt)-sprite_get_height(sprt)/2;
				d3d_transform_add_translation(xoffset + (wepangle < 0) * 0.85,i - (wepangle > 0) * 5 + (wepangle < 0) * 5,yoffset/2-4);
				d3d_transform_add_translation(-wkick+weapon_is_melee(wep)*-8, -10, (weapon_is_melee(wep) ? wkick-4 : -4)); // forward-backward, left-right, up-down
				d3d_transform_add_rotation_y(0.5*abs(wepangle));
				d3d_transform_add_rotation_x(0.2);
				if(global.options.True3D){
					d3d_transform_add_rotation_y(global.camera_vangle);
				}
				d3d_transform_add_rotation_z(gunangle);
				d3d_transform_add_translation(cx, cy, cz);
				var reloadSpin = reload*global.options.RecoilMult[index];
				if(global.options.CapRecoil){reloadSpin = min(120, reloadSpin);}
				draw_sprite_ext(weapon_get_sprt(wep), 0, 0, 0, 1, 1, (reloadSpin * (reload/weapon_get_load(wep))) * (weapon_is_melee(wep) ? -1 : 1), image_blend, 1);
			}
		
			for(var i = 1; i > 0; i-=(1/8)){
				d3d_transform_set_rotation_x(90);
				var sprt = weapon_get_sprt(bwep);
				var xoffset = (bwepangle == 0) ? sprite_get_xoffset(sprt) : sprite_get_yoffset(sprt)-sprite_get_width(sprt)/2;
				var yoffset = (bwepangle == 0) ? sprite_get_yoffset(sprt) : sprite_get_xoffset(sprt)-sprite_get_height(sprt)/2;
				d3d_transform_add_translation(xoffset + (wepangle < 0) * 0.85,i - (wepangle > 0) * 5 + (wepangle < 0) * 5,yoffset/2-4);
				d3d_transform_add_translation(-bwkick+(weapon_is_melee(bwep))*-8, 10, weapon_is_melee(bwep) ? bwkick-4 : -4); // forward-backward, left-right, up-down
				d3d_transform_add_rotation_y(0.5*abs(bwepangle));
				d3d_transform_add_rotation_x(0.2);
				if(global.options.True3D){
					d3d_transform_add_rotation_y(global.camera_vangle);
				}
				d3d_transform_add_rotation_z(gunangle);
				d3d_transform_add_translation(cx, cy, cz);
				var reloadSpin = reload*global.options.RecoilMult[index];
				if(global.options.CapRecoil){reloadSpin = min(120, reloadSpin);}
				draw_sprite_ext(weapon_get_sprt(bwep), 0, 0, 0, 1, 1, (reloadSpin * (breload/weapon_get_load(bwep))) * (weapon_is_melee(bwep) ? -1 : 1), image_blend, 1);
			}
			d3d_set_hidden(true);
		}
		else{
			for(var i = (wepangle >= 0); i * (wepangle >= 0) + (wepangle < 0) > i * (wepangle < 0); i+=(1/8) * ((wepangle >= 0) ? -1 : 1)){
				d3d_transform_set_rotation_x(90);
				var sprt = weapon_get_sprt(wep);
				var xoffset = (wepangle == 0) ? sprite_get_xoffset(sprt) : sprite_get_yoffset(sprt)-sprite_get_width(sprt)/2;
				var yoffset = (wepangle == 0) ? sprite_get_yoffset(sprt) : sprite_get_xoffset(sprt)-sprite_get_height(sprt)/2;
				d3d_transform_add_translation(xoffset + (wepangle < 0) * 0.85,i - (wepangle > 0) * 5 + (wepangle < 0) * 5,yoffset/2-4);
				d3d_transform_add_translation(-wkick, (weapon_is_melee(wep)) ? 0.1*wepangle : 6, (weapon_is_melee(wep) ? wkick-4 : -4)); // forward-backward, left-right, up-down
				d3d_transform_add_rotation_y(0.5*abs(wepangle));
				d3d_transform_add_rotation_x(0.2*wepangle);
				if(global.options.True3D){
					d3d_transform_add_rotation_y(global.camera_vangle);
				}
				d3d_transform_add_rotation_z(gunangle);
				d3d_transform_add_translation(cx, cy, cz);
				var reloadSpin = reload*global.options.RecoilMult[index];
				if(global.options.CapRecoil){reloadSpin = min(120, reloadSpin);}
				draw_sprite_ext(weapon_get_sprt(wep), 0, 0, 0, 1, 1, (reloadSpin * (reload/weapon_get_load(wep))) * (weapon_is_melee(wep) ? -1 : 1), image_blend, 1);
			}
		}
	}

	d3d_transform_set_identity();
	d3d_set_hidden(false);
	d3d_set_fog(false, 0, 0, 0);
	d3d_end();
	draw_set_alpha_test(false);
	draw_reset_projection();
	
	draw_set_projection(0);
	if draw_gun with player_find(global.camera_index) {
		if(global.options.reticle != ""){
			draw_sprite_stretched(sprCrosshair, real(string_split(string_split(global.options.reticle, ")")[0], ":")[1]), game_width / 2 - (sprite_get_width(sprCrosshair) * global.options.reticleScale)/2, game_height / 2 - (sprite_get_height(sprCrosshair) * global.options.reticleScale)/2, sprite_get_width(sprCrosshair) * global.options.reticleScale, sprite_get_height(sprCrosshair) * global.options.reticleScale);
		}
	}
	draw_reset_projection();

#define instances_viewbounds(_obj, _margin)
	// as a consequence of D3D fog being depth-based instead of range-based,
	// the maximum distance at which an object can be visible is a function of
	// not just the "view distance" but also the diagonal FOV
	var halfFOV = global.options.FOV/2;
	var diagFOVhalf = darctan(point_direction(0, 0, dtan(halfFOV), dtan(halfFOV) * (game_height/game_width)));
	var offset = global.options.view_dist / dcos(diagFOVhalf);
	var farleft_x = global.camera_x + lengthdir_x(offset, global.camera_angle - halfFOV)
	var farleft_y = global.camera_y + lengthdir_y(offset, global.camera_angle - halfFOV)
	var farright_x = global.camera_x + lengthdir_x(offset, global.camera_angle + halfFOV)
	var farright_y = global.camera_y + lengthdir_y(offset, global.camera_angle + halfFOV)
	// the "margin" should be the diagonal
	return instances_rectangle(
		min(global.camera_x, farleft_x, farright_x) - _margin,
		min(global.camera_y, farleft_y, farright_y) - _margin,
		max(global.camera_x, farleft_x, farright_x) + _margin,
		max(global.camera_y, farleft_y, farright_y) + _margin,
		_obj
	);

#define instances_rectangle(_x1, _y1, _x2, _y2, _obj)
	return instances_matching_le(instances_matching_ge(instances_matching_le(instances_matching_ge(_obj, "x", _x1), "x", _x2), "y", _y1), "y", _y2);
	
#define cleanup
undo_visual_settings();
for(var i = 0; i < maxp; i++) {for(var i2 = 0; i2 < maxp; i2++) {player_set_show_cursor(i, i2, 1);player_set_show_marker(i, i2, 1);player_set_show_prompts(i, i2, 1);}}
if surface_exists(global.surf_floors) surface_destroy(global.surf_floors);
vertex_format_delete(global.wall_vertex_format);
if global.wall_vertex_buffer != null vertex_delete_buffer(global.wall_vertex_buffer);

#define draw_pause
for(var i = 0; i < maxp; i++) {for(var i2 = 0; i2 < maxp; i2++) {player_set_show_cursor(i, i2, 1);player_set_show_marker(i, i2, 1);player_set_show_prompts(i, i2, 1);}}
global.wasPaused = true;

#define draw_gui
draw_set_projection(2, global.camera_index);
var player = player_find(global.camera_index);
var _y = 50;
if(player != noone){
	with(WepPickup){
		if(distance_to_point(player.x,player.y) <= 0){
			draw_text_nt(7.5,_y,"@(sprEPickup:0) " + name);
			_y+=10;
		}
	}
	with(PopupText){
		if(distance_to_point(player.x,player.y) < 100 && "_text" in self){
			draw_text_nt(0,_y,_text);
			_y+=10;
		}
	}
}

#define mouseaim(player)
var maxdist = 200;
dist = (global.options.camera_height/(-dsin(player.vertangle) + (-dsin(player.vertangle) == 0))) * dcos(player.vertangle);
if(dist > maxdist || dist < 0){
	dist = maxdist;
}
var retVal = collision_line_first( player.x, player.y, global.camera_x+dcos(-player.gunangle) * dist, global.camera_y+dsin(-player.gunangle) * dist, Wall, 0, 0 );
retVal[0] -= dcos(-player.gunangle)*8;
retVal[1] -= dsin(-player.gunangle)*8;
return retVal;

#define collision_line_first(x1,y1,x2,y2,object,prec,notme)
/// collision_line_first(x1,y1,x2,y2,object,prec,notme)
//
//  Returns the instance id of an object colliding with a given line and
//  closest to the first point, or noone if no instance found.
// yo whats up jsburg here, made this shit return the point of collison as the first two indexes of the array, and the instance as the third
//  The solution is found in log2(range) collision checks.
//
//      x1,y2       first point on collision line, real
//      x2,y2       second point on collision line, real
//      object      which objects to look for (or all), real
//      prec        if true, use precise collision checking, bool
//      notme       if true, ignore the calling instance, bool
//
/// GMLscripts.com/license
{
    var ox,oy,dx,dy,object,prec,notme,sx,sy,inst,i;
    ox = argument0;
    oy = argument1;
    dx = argument2;
    dy = argument3;
    object = argument4;
    prec = argument5;
    notme = argument6;
    sx = dx - ox;
    sy = dy - oy;
    inst = collision_line(ox,oy,dx,dy,object,prec,notme);
    if (inst != noone) {
        while ((abs(sx) >= 1) || (abs(sy) >= 1)) {
            sx *= .5;
            sy *= .5;
            i = collision_line(ox,oy,dx,dy,object,prec,notme);
            if (i) {
                dx -= sx;
                dy -= sy;
                inst = i;
            }else{
                dx += sx;
                dy += sy;
            }
        }
    }
    return [dx, dy, inst];
}
#define magiczbullet
	var magic_bounce = [BouncerBullet, Grenade, BloodGrenade, ClusterNade, MiniNade, PopoNade, Bullet2, FlameShell, UltraShell, Slug, FlakBullet, Disc]
	var magic_grav = [Grenade, BloodGrenade, ClusterNade, MiniNade, PopoNade, ToxicGrenade, ThrownWep, TangleSeed]
	var magic_except = []
	with(instances_matching_ne(hitme, "magic_z_check", 1)){
		magic_z_check = 1;
		if("z" not in self){z = 0;}
	}
	with (instances_matching(projectile, "magic_z_check", null)) {
		magic_z_check = true;
		if(object_index == Laser){
			magic_z = false;
			continue;
		}
		speed_z = 0;
		if(speed == 0){speed = 0.1;}
		if (team == 2) {
			var base = -4;
			if(instance_exists(creator)){
				base = creator;
			}else if(distance_to_object(instance_nearest(x, y, Player)) < 8){
				base = instance_nearest(x, y, Player);
			}
			if (instance_exists(base)) {
				if("z" not in base){
					base.z = 0;
				}
				if("vertangle" in base){
					z = base.z + global.options.projectile_height;
					magic_z = true
					backupspeed = speed;
					speed_z = lengthdir_y(speed, -base.vertangle + (global.options.projectile_height-global.options.player_height)/2)
					speed = lengthdir_x(speed, -base.vertangle + (global.options.projectile_height-global.options.player_height)/2)
					if(speed == 0){speed = 0.1;}
					zmask = mask_index;
				}else{
					z = base.z + global.options.projectile_height;
					magic_z = true
					backupspeed = speed;
					speed_z = 0;
					if(speed == 0){speed = 0.1;}
					zmask = mask_index;
				}
			}
		}else{
			magic_z_enemy = true;
			z = global.options.projectile_height;
			speed_z = 0;//TODO: Make this target players
			backupspeed = speed;
			if(array_find_index(magic_grav, object_index) >= 0){
				speed_z = lengthdir_y(speed, -10)
				speed = lengthdir_x(speed, -10)
				if(speed == 0){speed = 0.1;}
			}
		}
	}
	with (instances_matching(projectile, "magic_z", true)) {
		if(speed == 0 && array_find_index(magic_grav, object_index) < 0){speed_z = 0;}
		if z > 200 || distance_to_object(instance_nearest(x, y, Floor)) > 200 {
			instance_destroy()
			continue
		}
		if(z+min(sprite_height/2, global.options.wall_height/2) > global.options.wall_height){
			if (mask_index != mskNone){
				zmask = mask_index;
				mask_index = mskNone
			}
			var hit = 0;
			with(instances_matching_ge(instances_matching_le(instances_matching(CustomObject,"name","TopEnemy"), "visz", z+sprite_get_height(zmask)), "visz", z-sprite_get_height(zmask))){
				if(rectangle_in_rectangle(other.x+sprite_get_width(other.zmask)/2, other.y+sprite_get_height(other.zmask)/2, other.x-sprite_get_width(other.zmask)/2, other.y-sprite_get_height(other.zmask)/2, x+sprite_width/2, y+sprite_height/2, x-sprite_width/2, y-sprite_height/2)){
					if(lq_get(object, "object_index") == Corpse){continue;}
					var objind = lq_get(object, "object_index");
					var punchingbag = (is_undefined(objind) ? [] : mod_script_call_nc("mod", "telib", "obj_create", x, y, objind));//don't care, I'mma spaghetti this compatibility
					if(is_array(punchingbag)){
						with(punchingbag){
							if(id != punchingbag[0].id){instance_destroy()}
						}
						punchingbag = punchingbag[0];
					}
					if(punchingbag <= 0){continue;}
					if("my_health" in self){punchingbag.my_health = my_health + 100000;}
					if("raddrop" in self){punchingbag.raddrop = raddrop;}
					var tempspd2 = other.speed;
					with(other){
						instance_exists(self);
						event_perform(ev_collision, punchingbag);
					}
					other.speed = tempspd2;
					my_health = punchingbag.my_health - 100000;
					raddrop = punchingbag.raddrop;
					lq_set(object, "my_health", my_health);
					lq_set(object, "raddrop", raddrop);
					
					sprite_index = punchingbag.spr_hurt;
					if(objind == Cactus){sprite_index = -1;}
					if(my_health <= 0){
						if("raddrop" in self && raddrop > 0){
							repeat(punchingbag.raddrop){
								instance_create(x,y,Rad);//TODO make rads fly
							}
						}
						spr_idle = punchingbag.spr_dead;
						if(objind == Cactus){spr_idle = -1;}
						image_index = 4;
						image_speed = 0;
						lq_set(object, "object_index", Corpse);
						speed = 0;
						zspeed = 0;
						zfriction = 1;
						walk = 0;
						walkspeed = 0;
					}
					with(punchingbag){instance_destroy();}
					hit = true;
					break;
				}
			}
			with(instances_matching_ne(instances_matching_ge(instances_matching_le(hitme, "z", z+sprite_get_height(zmask)), "z", z-sprite_get_height(zmask)), "team", team)){
				if(rectangle_in_rectangle(other.x+sprite_get_width(other.zmask)/2, other.y+sprite_get_height(other.zmask)/2, other.x-sprite_get_width(other.zmask)/2, other.y-sprite_get_height(other.zmask)/2, x+sprite_width/2, y+sprite_height/2, x-sprite_width/2, y-sprite_height/2)){
					var tempspd2 = other.speed;
					other.mask_index = other.zmask;
					with(other){instance_exists(self);event_perform(ev_collision, hitme);}
					if(instance_exists(other)){
						other.mask_index = mskNone;
						other.speed = tempspd2;
					}if(instance_exists(self)){
						hit = true;
					}
					break;
				}
			}
			if(hit){continue;}
			with(instances_matching_ge(instances_matching_le(becomenemy, "z", z+sprite_get_height(zmask)), "z", z-sprite_get_height(zmask))){
				if(rectangle_in_rectangle(other.x+sprite_get_width(other.zmask), other.y+sprite_get_height(other.zmask), other.x-sprite_get_width(other.zmask), other.y-sprite_get_height(other.zmask), x+sprite_width, y+sprite_height, x-sprite_width, y-sprite_height)){
					var tempspr = sprite_index;
					var tempind = image_index;
					var tempspd = speed;
					var tempdir = direction;
					var tempspd2 = other.speed;
					with(other){instance_exists(self);event_perform(ev_collision, hitme);}
					if(instance_exists(self)){
						hit = true;
						sprite_index = tempspr;
						image_index = tempind;
						speed = tempspd;
						direction = tempdir;
					}if(instance_exists(other)){
						other.speed = tempspd2;
					}
					break;
				}
			}
			if(hit){continue;}
			with(instances_matching_ge(instances_matching_le(becomenemy, "z", -z+sprite_get_height(zmask)), "z", -z-sprite_get_height(zmask))){
				if(rectangle_in_rectangle(other.x+sprite_get_width(other.zmask), other.y+sprite_get_height(other.zmask), other.x-sprite_get_width(other.zmask), other.y-sprite_get_height(other.zmask), x+sprite_width, y+sprite_height, x-sprite_width, y-sprite_height)){
					var tempspr = sprite_index;
					var tempind = image_index;
					var tempspd = speed;
					var tempdir = direction;
					with(other){instance_exists(self);event_perform(ev_collision, hitme);}
					if(instance_exists(self)){
						hit = true;
						sprite_index = tempspr;
						image_index = tempind;
						speed = tempspd;
						direction = tempdir;
					}if(instance_exists(other)){
						other.speed = tempspd2;
					}
					break;
				}
			}
			if(hit){continue;}
		}else if(mask_index == mskNone){
			mask_index = zmask;
			zmask = mskNone;
		}
		if (array_find_index(magic_except, object_index) >= 0) {
			speed_z = 0;
			speed = backupspeed;
		}
		if (array_find_index(magic_grav, object_index) >= 0) {
			speed_z = speed_z - 0.55*current_time_scale;
		} else {
			if (friction > 0 && speed_z != 0) {
				speed_z = speed_z - friction * sign(speed_z)
				if abs(speed_z) < friction
					speed_z = 0
			}
		}
		z+=speed_z*current_time_scale
		z = max(-sprite_height, z);
		if z+(sprite_height * !(array_find_index(magic_bounce, object_index) >= 0)) <= 0 || distance_to_object(instance_nearest(x, y, Floor)) > distance_to_object(instance_nearest(x, y, Wall)) + 16 && z+sprite_height-2 < global.options.wall_height {
			if (array_find_index(magic_bounce, object_index) >= 0) {
				speed_z = speed_z * -0.5
				z=-(sprite_height * !(array_find_index(magic_bounce, object_index) >= 0));
			} else {
				z=-(sprite_height * !(array_find_index(magic_bounce, object_index) >= 0));
				instance_exists(self);
				event_perform(ev_collision, Wall);
			}
		}
	}
	with (instances_matching(projectile, "magic_z_enemy", true)) {
		if(speed == 0 && array_find_index(magic_grav, object_index) < 0){speed_z = 0;}
		if z > 200 || distance_to_object(instance_nearest(x, y, Floor)) > 200 {
			instance_destroy()
			continue
		}
		if (array_find_index(magic_except, object_index) >= 0) {
			speed_z = 0;
			speed = backupspeed;
		}
		if (array_find_index(magic_grav, object_index) >= 0) {
			if (place_meeting(x, y, Wall) || !place_meeting(x, y, Floor)) {
				mask_index = mskNone
				z = global.options.wall_height
			} else {
				speed_z = speed_z - 0.55;
			}
		} else {
			if (friction > 0 && speed_z != 0) {
				speed_z = speed_z - friction * sign(speed_z)
				if abs(speed_z) < friction
					speed_z = 0
			}
		}
		z+=speed_z*current_time_scale
		z = max(0, z);
		if z+(sprite_height * !(array_find_index(magic_bounce, object_index) >= 0)) <= 0 || distance_to_object(instance_nearest(x, y, Floor)) > distance_to_object(instance_nearest(x, y, Wall)) + 16 && z+sprite_height-2 < global.options.wall_height {
			if (array_find_index(magic_bounce, object_index) >= 0) {
				speed_z = speed_z * -0.5
			} else {
				instance_exists(self);
				event_perform(ev_collision, Wall);
				/*if ("spr_dead" in self) {
					with instance_create(x, y, BulletHit){ z = other.z + 7;}
				}
				instance_destroy()*/
			}
		}
	}
instance_destroy();

//Stolen from blaac's hardmode
#define move_camera(_index, _x, _y)
    with(player_find(_index)){
        var _vo = view_object[_index];
         // Snap Camera:
        if(fork()){
            with(instance_create(_x, _y, GameObject)){
                view_object[_index] = id;
                wait 1;
                if(instance_exists(self)) instance_destroy();
            }
            exit;
        }
    }
	
//yoinked from NTTE by team TE
#define hitscan(_x, _y, _dir, _maxDistance)
    var _sx = _x,
        _sy = _y,
        _lx = _sx,
        _ly = _ly,
        _md = _maxDistance,
        d = _md,
        m = 0; // Minor hitscan increment distance
		

    while(d > 0){
         // Major Hitscan Mode (Start at max, go back until no collision line):
        if(m <= 0){
            _lx = _sx + lengthdir_x(d, _dir);
            _ly = _sy + lengthdir_y(d, _dir);
            d -= sqrt(_md);

             // Enter minor hitscan mode:
            if(!collision_line(_sx, _sy, _lx, _ly, Wall, false, false)){
                m = 2;
                d = sqrt(_md);
            }
        }

         // Minor Hitscan Mode (Move until collision):
        else{
            if(position_meeting(_lx, _ly, Wall)) {
				_lx -= lengthdir_x(m, _dir);
				_ly -= lengthdir_y(m, _dir);
				break;
			}
            _lx += lengthdir_x(m, _dir);
            _ly += lengthdir_y(m, _dir);
            d -= m;
        }
    }

    return [_lx, _ly];
	
/*#define floorgrab
	depth++;
	depth--;
	
	 // Screenshot Floors:
	with(surface_setup("FloorGrab", game_width, game_height, game_screen_get_width_nonsync() / game_width)){
		surface_screenshot(surf);
	}
*/

#define surface_setup(_name, _w, _h, _scale)
	/*
		Assigns a surface to the given name and stores it in 'global.surf' for future calls
		Automatically recreates the surface it doesn't exist or match the given width/height
		Destroys the surface if it hasn't been used for 30 frames, to free up memory
		Returns a LWO containing the surface itself and relevant vars
		
		Args:
			name  - The name used to store & retrieve the shader
			w/h   - The width/height of the surface
			        Use 'null' to not update the surface's width/height
			scale - The scale or quality of the surface
			        Use 'null' to not update the surface's scale
			
		Vars:
			name  - The name used to store & retrieve the surface
			surf  - The surface itself
			time  - # of frames until the surface is destroyed, not counting when the game is paused
			        Is set to 30 frames by default, set -1 to disable the timer
			free  - Set to 'true' if you aren't going to use this surface anymore (removes it from the list when 'time' hits 0)
			reset - Is set to 'true' when the surface is created or the game pauses
			scale - The scale or quality of the surface
			w/h   - The drawing width/height of the surface
			x/y   - The drawing position of the surface, you can set this manually
			
		Ex:
			with(surface_setup("Test", game_width, game_height, game_screen_get_width_nonsync() / game_width)){
				x = view_xview_nonsync;
				y = view_yview_nonsync;
				
				 // Setup:
				if(reset){
					reset = false;
					surface_set_target(surf);
					draw_clear_alpha(0, 0);
					draw_circle((w / 2) * scale, (h / 2) * scale, 50 * scale, false);
					surface_reset_target();
				}
				
				 // Draw Surface:
				draw_surface_scale(surf, x, y, 1 / scale);
			}
	*/
	
	 // Retrieve Surface:
	if(!mod_variable_exists("mod", mod_current, "surf")){
		global.surf = {};
	}
	var _surf = lq_defget(global.surf, _name, noone);
	
	 // Initialize Surface:
	if(!is_object(_surf)){
		_surf = {
			name  : _name,
			surf  : -1,
			time  : 0,
			reset : false,
			free  : false,
			scale : 1,
			w     : 1,
			h     : 1,
			x     : 0,
			y     : 0
		};
		lq_set(global.surf, _name, _surf);
		
		 // Auto-Management:
		with(_surf){
			if(fork()){
				while(true){
					 // Deactivate Unused Surfaces:
					if(time >= 0 && --time <= 0){
						time = -1;
						surface_destroy(surf);
						
						 // Remove From List:
						if(free){
							var	_new = {};
							for(var i = 0; i < lq_size(global.surf); i++){
								var _key = lq_get_key(global.surf, i);
								if(_key != name){
									lq_set(_new, _key, lq_get_value(global.surf, i));
								}
							}
							global.surf = _new;
							break;
						}
					}
					
					 // Game Paused:
					else for(var i = 0; i < maxp; i++){
						if(button_pressed(i, "paus")){
							reset = true;
							break;
						}
					}
					
					wait 0;
				}
				exit;
			}
		}
	}
	
	 // Surface Setup:
	with(_surf){
		if(is_real(_w)) w = _w;
		if(is_real(_h)) h = _h;
		if(is_real(_scale)) scale = _scale;
		
		 // Create / Resize Surface:
		if(!surface_exists(surf) || surface_get_width(surf) != max(1, w * scale) || surface_get_height(surf) != max(1, h * scale)){
			surface_destroy(surf);
			surf = surface_create(max(1, w * scale), max(1, h * scale));
			reset = true;
		}
		
		 // Active For 30 Frames:
		if(time >= 0) time = max(time, 30);
	}
	
	return _surf;
	
#define save_options
	string_save(json_encode(global.options, "  "), 'settings'+string(VERSION)+'.json');
	update_visual_settings();

#define update_visual_settings
	if(global.options.ControlSettings){
		if(global.backup == 0 && fork()){
			global.backup = {width : game_width, height : game_height, scaling : "", mousesens : "" };
			wait(file_load("NuclearThroneTogether.ini"));
			var s = string_load("NuclearThroneTogether.ini");
			var s1 = 1;
			if(array_length(string_split(s, "Subpixel=")) > 1){
				s1 = string_split(string_split(s, "Subpixel=")[1], '"')[1];
			}
			var s2 = 5;
			if(array_length(string_split(s, "MouseDiv=")) > 1){
				s2 = string_split(string_split(s, "MouseDiv=")[1], '"')[1];
			}
			global.backup.scaling = ((s1 == "0") ? "8" : s1)
			global.backup.mousesens = s2;
		}
		undo_visual_settings();
		if(global.options.Widescreen){
			game_set_size(440, 240);
		}
		wait(4);
		string_save("/subpixel "+string(global.options.Scaling == "native" ? 8 : global.options.Scaling), "scaling.txt");
		mod_loadtext("data/"+mod_current+".mod/scaling.txt");
		if(global.options.MouseSens != "Don't Change"){
			string_save("/mousesens "+string(global.options.MouseSens), "sensitivity.txt");
			wait(0);
			mod_loadtext("data/"+mod_current+".mod/sensitivity.txt");
		}
		if(player_is_active(1)){
			wait(0);
			wait(0);
			trace_color("WARNING: ALL PLAYERS NEED TO RUN | /mousesens "+string(global.options.MouseSens)+" | TO PLAY WITHOUT DESYNCING", c_red);
		}
	}
	
#define undo_visual_settings
	if(global.backup != 0){
		game_set_size(global.backup.width, global.backup.height);
		string_save("/subpixel "+string(global.backup.scaling), "scaling.txt");
		mod_loadtext("data/"+mod_current+".mod/scaling.txt");
		string_save("/mousesens "+string(global.backup.mousesens), "sensitivity.txt");
		mod_loadtext("data/"+mod_current+".mod/sensitivity.txt");
	}