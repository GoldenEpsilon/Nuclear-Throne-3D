#define init
global.menu_stuff = {
	view_settings: false, settings_page: [], page_index: 0, selected: [], pressed: [], side: [], key_timer: []
};

global.splats = array_clone([]);
global.nonsplats = array_clone([]);

var p = 0;

for (p = 0; maxp > p; p ++){
	global.menu_stuff.settings_page[p] = 0;
	global.menu_stuff.selected[p] = -1;
	global.menu_stuff.pressed[p] = false;
	global.menu_stuff.side[p] = 0;
	global.menu_stuff.key_timer[p] = 0;
	
	global.splats[p] = array_clone([]);
	global.nonsplats[p] = array_clone([]);
}

global.stored_options = {};

if (array_length(instances_matching(instances_matching_ne(instances_matching(CustomObject, "name", "OptionCont"), "options", null), "persistent", true)) <= 0){
	with(instance_create(0, 0, CustomObject)){
		name = "OptionCont";
		persistent = true;
		
		if (!"options" in self){
			options = global.stored_options;
		}
		
		if (!"menu_stuff" in self){
			menu_stuff = global.menu_stuff;
		}
	}
}

with(instances_matching(instances_matching_ne(instances_matching(CustomObject, "name", "OptionCont"), "options", null), "persistent", true)){
	if (!"options" in self){
		options = global.stored_options;
	}
	
	if (!"menu_stuff" in self){
		menu_stuff = global.menu_stuff;
	}
	
	global.stored_options = options;
	global.menu_stuff = menu_stuff;
}

with(instances_matching_ne(CustomScript, mod_current, null)){
	instance_destroy();
}

global.option_slider = sprite_image_get_bbox(0, 0, sprOptionSlider, 0);
global.left_daily_arrow = sprite_image_get_bbox(0, 0, sprDailyArrow, 0);
global.right_daily_arrow = sprite_image_get_bbox(0, 0, sprDailyArrow, 1);

global.daily_splat = sprite_image_get_bbox(0, 0, sprDailySplat, 3);
global.score_splat = sprite_image_get_bbox(0, 0, sprScoreSplat, 2);
global.arrow_splat = sprite_image_get_bbox(0, 0, sprDailyArrowSplat, 3);

#define cleanup
with(instances_matching_ne(CustomScript, mod_current, null)){
	instance_destroy();
}

if (array_length(instances_matching(instances_matching_ne(instances_matching(CustomObject, "name", "OptionCont"), "options", null), "persistent", true)) <= 0){
	with(instance_create(0, 0, CustomObject)){
		name = "OptionCont";
		persistent = true;
		mod_source = mod_current;
	}
}

with(instances_matching(instances_matching_ne(instances_matching(CustomObject, "name", "OptionCont"), "options", null), "persistent", true)){
	options = global.stored_options;
	menu_stuff = global.menu_stuff;
}

#macro BUTTON_POS_Y game_height * 0.5 - 24 * (instance_number(OptionMenuButton) * 0.5 - 1)
#macro SINGLE_LINE_HEIGHT 32

// hex colors in GML are BGR, but that doesn't matter here
#macro C_GREY $999999

#define step
if (array_length(instances_matching(instances_matching_ne(instances_matching(CustomObject, "name", "OptionCont"), "options", null), "persistent", true)) <= 0){
	with(instance_create(0, 0, CustomObject)){
		name = "OptionCont";
		persistent = true;
		mod_source = mod_current;
		
		if (!"options" in self){
			options = global.stored_options;
		}
		
		if (!"menu_stuff" in self){
			menu_stuff = global.menu_stuff;
		}
	}
}

// you can tell I pasted this from below
#define chat_message(_msg, _p)
if (global.menu_stuff.view_settings){
	var mod_details = string_split(lq_get_key(global.stored_options, global.menu_stuff.page_index), ".");
	var dot_count = array_length(mod_details);
	
	var mod_name = array_join(array_slice(mod_details, 0, dot_count - 1), ".");
	var mod_type = mod_details[dot_count - 1];
	
	var mod_lq = lq_get_value(global.stored_options, global.menu_stuff.page_index);
	var my_options = lq_defget(mod_lq, "my_options", lq_clone({}));
	
	var my_variable = (lq_exists(mod_lq, "point") ? lq_get(mod_lq, "point") : "options");
	
	if (is_array(my_options)){
		mod_lq = legacy_options_convert(mod_lq);
		my_options = lq_get(mod_lq, "my_options");
		
		my_variable = (lq_exists(mod_lq, "point") ? lq_get(mod_lq, "point") : "options");
		mod_name = lq_get_key(global.stored_options, global.menu_stuff.page_index);
		
		with(["mod", "weapon", "race", "skill", "crown", "area", "skin"]){
			if (mod_variable_exists(self, mod_name, my_variable)){
				mod_type = self;
				break;
			}
		}
	}
	
	var page_count = lq_size(my_options);
	var my_page = lq_get_value(my_options, global.menu_stuff.settings_page[_p]);
	var page_name = lq_get_key(my_options, global.menu_stuff.settings_page[_p]);
	
	var option_count = lq_size(my_page);
	
	if (is_object(my_page)){
		var o = 0;
		
		for (o = 0; option_count > o; o ++){
			var _key = lq_get_key(my_page, o);
			var _me = lq_get_value(my_page, o);
			
			if (is_object(_me)){
				var _selected = (global.menu_stuff.selected[_p] == o || global.menu_stuff.selected[_p] == o + 10016) + (global.menu_stuff.selected[_p] == o + 10016);
				
				var _type = lq_get(_me, "type");
				
				var _nonsync = lq_defget(_me, "nonsync", false);
				var fake_nonsync = lq_defget(_me, "fake_nonsync", false);
				
				if (_selected > 0 && (!_nonsync || (_nonsync && _p == player_find_local_nonsync()))){
					switch(_type){
						case "int":
						case "slider":
						case "text":{
							sound_play_nonsync(_p, sndNoSelect);
							
							var _point = lq_defget(_me, "point", -1);
							
							var _digits = sign_string_dotdigits(_msg);
							var _real = (string_length(_digits) > 0 ? real(_digits) : (is_array(_point) ? option_get(_point[0], _point[1], _point[2], _key) : option_get(mod_type, mod_name, my_variable, _key)));
							
							if (_type == "slider"){
								_real /= lq_defget(_me, "display", 100);
							}
							
							if (fake_nonsync){
								if (is_array(_point) && array_length(_point) >= 3){
									option_set_fake_nonsync(_point[0], _point[1], _point[2], _p, _key, (_type == "text" ? _msg : _real));
								}
								
								else{
									option_set_fake_nonsync(mod_type, mod_name, my_variable, _p, _key, (_type == "text" ? _msg : _real));
								}
							}
							
							else{
								if (is_array(_point) && array_length(_point) >= 3){
									option_set(_point[0], _point[1], _point[2], _key, (_type == "text" ? _msg : _real));
								}
								
								else{
									option_set(mod_type, mod_name, my_variable, _key, (_type == "text" ? _msg : _real));
								}
							}
							
							global.menu_stuff.selected[_p] = o;
							
							return true;
						}
					}
				}
			}
		}
	}
}

// incredibly cursed
#define draw_options
// trace_time();
// draw_set_projection(0);

var local_player = player_find_local_nonsync();

var _halign = draw_get_halign();
var _valign = draw_get_valign();

if (global.menu_stuff.view_settings){
	draw_set_font(fntM);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	
	var _me = id;
	
	with([global.splats[local_player], global.nonsplats[local_player]]){
		var _real = self;
		
		if (!is_array(self)){
			_real = [_real];
		}
		
		with(_real){
			with(self){
				var _x = view_xview_nonsync + x;
				var _y = view_yview_nonsync + y;
				// var _x = x;
				// var _y = y;
				
				with(_me){
					var _text = lq_defget(other, "text", false);
					
					if (is_string(_text)){
						_text = string_add_linebreaks(_text);
						
						var _side = lq_defget(other, "side", fa_center);
						
						draw_set_halign(_side);
						draw_text_nt(_x, _y, _text);
					}
					
					else{
						var _part = lq_defget(other, "part", null);
						
						var _xscale = lq_defget(other, "xscale", 1);
						var _yscale = lq_defget(other, "yscale", 1);
						var _blend = lq_defget(other, "blend", c_white);
						var _alpha = lq_defget(other, "alpha", 1);
						
						var _yoffset = (draw_get_valign() != fa_middle ? string_height("OFF") * 0.5 * (draw_get_valign() == fa_bottom ? -1 : 1) : 0);
						
						if (is_object(_part)){
							draw_sprite_part_ext(other.spr, other.img, _part.left, _part.top, _part.width, _part.height, _x, _y + _yoffset, _xscale, _yscale, _blend, _alpha);
						}
						
						else{
							draw_sprite_ext(other.spr, other.img, _x, _y + _yoffset, _xscale, _yscale, 0, _blend, _alpha);
						}
					}
				}
			}
		}
	}
}

global.splats[local_player] = array_clone([]);
global.nonsplats[local_player] = array_clone([]);

draw_set_halign(_halign);
draw_set_valign(_valign);

// draw_reset_projection();
// trace_time("draw");

/*
A short way to do lq_set(mod_variable_get(mod_type, mod_name, mod_var), option_name, value)
*/
#define option_set(mod_type, mod_name, mod_var, option_name, value)
if (!is_undefined(value)){
	var _lq = mod_variable_get(mod_type, mod_name, mod_var);
	
	if (is_undefined(_lq)){
		mod_variable_set(mod_type, mod_name, mod_var, lq_clone({}));
		_lq = mod_variable_get(mod_type, mod_name, mod_var);
	}
	
	lq_set(_lq, option_name, value);
	return value;
}

/*
A short way to do lq_get(mod_variable_get(mod_type, mod_name, mod_var), option_name)
*/
#define option_get(mod_type, mod_name, mod_var, option_name)
var _lq = mod_variable_get(mod_type, mod_name, mod_var);
return lq_get(_lq, option_name);

/*
A short way to do lq_defget(mod_variable_get(mod_type, mod_name, mod_var), option_name, def_value)
*/
#define option_defget(mod_type, mod_name, mod_var, option_name, def_value)
var _lq = mod_variable_get(mod_type, mod_name, mod_var);
return lq_defget(_lq, option_name, def_value);

/*
A short way to do lq_get(mod_variable_get(mod_type, mod_name, mod_var), option_name)[player] = value
*/
#define option_set_fake_nonsync(mod_type, mod_name, mod_var, player, option_name, value)
if (!is_undefined(value)){
	var _lq = mod_variable_get(mod_type, mod_name, mod_var);
	
	if (is_undefined(_lq)){
		mod_variable_set(mod_type, mod_name, mod_var, lq_clone({}));
		_lq = mod_variable_get(mod_type, mod_name, mod_var);
	}
	
	lq_get(_lq, option_name)[@player] = value;
	return value;
}

/*
A short way to do lq_get(mod_variable_get(mod_type, mod_name, mod_var), option_name)[player]
*/
#define option_get_fake_nonsync(mod_type, mod_name, mod_var, player, option_name)
var _lq = mod_variable_get(mod_type, mod_name, mod_var);
return lq_get(_lq, option_name)[@player];

/*
A short way to do var _value = lq_get(mod_variable_get(mod_type, mod_name, mod_var), option_name)[player]; _value = (is_undefined(_value) ? def_value : _value)
*/
#define option_defget_fake_nonsync(mod_type, mod_name, mod_var, player, option_name, def_value)
var _lq = mod_variable_get(mod_type, mod_name, mod_var);
var _array = lq_defget(_lq, option_name, []);
return (array_length(_array) > player ? _array[@player] : def_value);

/*
Change an option's properties.

option_set_field("mod", "options", "My Page 1", "my_bool", "desc", "This is a new description");

Allows for all kinds of funky stuff, so be careful.
*/
#define option_set_field(mod_type, mod_name, page_name, option_name, field, value)
// I could've done some recursive magic, but this is readable
var my_field = `${mod_name}.${mod_type}`;

if (!lq_exists(global.stored_options, my_field)){
	exit;
}

var mod_lq = lq_defget(lq_defget(global.stored_options, my_field, {}), "my_options", {});

if (!lq_exists(mod_lq, page_name)){
	exit;
}

var page_lq = lq_defget(mod_lq, page_name, {});

if (!lq_exists(page_lq, option_name)){
	exit;
}

lq_set(lq_get(page_lq, option_name), field, value);

/*
Retrieve an option's properties.

option_get_field("mod", "options", "My Page 1", "my_bool", "desc");
*/
#define option_get_field(mod_type, mod_name, page_name, option_name, field)
return lq_get(lq_defget(lq_defget(lq_defget(lq_defget(global.stored_options, `${mod_name}.${mod_type}`, {}), "my_options", {}), page_name, {}), option_name, {}), field);

/*
Retrieve an option's properties.

option_defget_field("mod", "options", "My Page 1", "my_bool", "desc");

If nothing is found, returns def_value.
*/
#define option_defget_field(mod_type, mod_name, page_name, option_name, field, def_value)
return lq_defget(lq_defget(lq_defget(lq_defget(lq_defget(global.stored_options, `${mod_name}.${mod_type}`, {}), "my_options", {}), page_name, {}), option_name, {}), field, def_value);

/*
Adds an option from JSON to the options controller/this mod.

option_set("mod", "options", "options", "my_bool", false);
option_add("mod", "options", "options", "MY#OPTIONS", "My Page 1", "my_bool", {name: "MY BOOLEAN", type: "bool", desc: "A boolean/toggle for my mod"});

Note that the game will give errors if the mod doesn't have mod_var or its field option_name.
See option_create for structure details.
*/
#define option_add(mod_type, mod_name, mod_var, mod_display_name, page_name, option_name, json_args)
if (!mod_exists(mod_type, mod_name)){
	exit;
}

if (!is_string(json_args) && !is_object(json_args)){
	exit;
}

var my_field = `${mod_name}.${mod_type}`;

if (!lq_exists(global.stored_options, my_field)){
	lq_set(global.stored_options, my_field, {name: mod_display_name, point: mod_var, my_options: {}});
}

var my_lq = lq_defget(lq_get(global.stored_options, my_field), "my_options", lq_clone({}));

if (!lq_exists(my_lq, page_name)){
	lq_set(my_lq, page_name, lq_clone({}));
}

my_lq = lq_get(my_lq, page_name);

var option_desc = lq_defget(json_args, "desc", "Did you define the#JSON arguments properly?");
var _o = option_create(my_lq, option_name, json_args);

update_optioncont();

return _o;

/*
Adds a page of options from JSON to the options controller/this mod.

option_add_page("mod", "options", "options", "MY#OPTIONS", "My Page 1", {my_bool: {name: "MY BOOLEAN", type: "bool", desc: "A boolean/toggle for my mod"}, my_int: {name: "MY INT", type: "int", desc: "A number option for my mod"}});

Note that a page with a single option is functionally the same as using option_add.
*/
#define option_add_page(mod_type, mod_name, mod_var, mod_display_name, page_name, json_args)
if (!mod_exists(mod_type, mod_name)){
	exit;
}

if (is_string(json_args)){
	json_args = json_decode(json_args);
}

else if (!is_object(json_args) && !is_array(json_args)){
	exit;
}

var my_field = `${mod_name}.${mod_type}`;

if (!lq_exists(global.stored_options, my_field)){
	lq_set(global.stored_options, my_field, {name: mod_display_name, point: mod_var, my_options: {}});
}

var my_lq = lq_defget(lq_get(global.stored_options, my_field), "my_options", lq_clone({}));

if (!lq_exists(my_lq, page_name)){
	lq_set(my_lq, page_name, lq_clone({}));
}

// safety checks with scripts will be up to the user
if (is_array(json_args)){
	lq_set(my_lq, page_name, json_args);
	return my_lq;
}

my_lq = lq_get(my_lq, page_name);

var _size = lq_size(json_args);
var i = 0;

for (i = 0; _size > i; i ++){
	var option_name = lq_get_key(json_args, i);
	var _me = lq_get_value(json_args, i);
	
	var option_type = lq_defget(_me, "type", "bool");
	
	option_create(my_lq, option_name, _me);
}

update_optioncont();

return my_lq;

/*
Removes an option from the options controller/this mod.

option_remove("options.mod", "My Page 1", "my_bool");
*/
#define option_remove(category_name, page_name, option_name)
if (!lq_exists(global.stored_options, category_name)){
	exit;
}

var my_lq = lq_defget(lq_get(global.stored_options, category_name), "my_options", lq_clone({}));

if (!lq_exists(my_lq, page_name)){
	exit;
}

lq_set(my_lq, page_name, lq_delete(lq_get(my_lq, page_name), option_name));

update_optioncont();

/*
Removes an option from the options controller/this mod.
Assumes the category name is mod_name.mod_type.	When true, it's identical to option_remove.

option_remove_ext("mod", "options", "My Page 1", "my_bool");
*/
#define option_remove_ext(mod_type, mod_name, page_name, option_name)
var my_field = `${mod_name}.${mod_type}`;

if (!lq_exists(global.stored_options, my_field)){
	exit;
}

var my_lq = lq_defget(lq_get(global.stored_options, my_field), "my_options", lq_clone({}));

if (!lq_exists(my_lq, page_name)){
	exit;
}

lq_set(my_lq, page_name, lq_delete(lq_get(my_lq, page_name), option_name));

update_optioncont();

/*
Removes an option page from the options controller/this mod.

option_remove_page("options.mod", "My Page 1");
*/
#define option_remove_page(category_name, page_name)
if (!lq_exists(global.stored_options, category_name)){
	exit;
}

var my_lq = lq_defget(lq_get(global.stored_options, category_name), "my_options", lq_clone({}));

if (!lq_exists(my_lq, page_name)){
	exit;
}

lq_set(lq_get(global.stored_options, category_name), "my_options", lq_delete(my_lq, page_name));

update_optioncont();

/*
Removes an option page from the options controller/this mod.
Assumes the category name is mod_name.mod_type.	When true, it's identical to option_remove_page.

option_remove_page("mod", "options", "My Page 1");
*/
#define option_remove_page_ext(mod_type, mod_name, page_name)
var my_field = `${mod_name}.${mod_type}`;

if (!lq_exists(global.stored_options, my_field)){
	exit;
}

var my_lq = lq_defget(lq_get(global.stored_options, my_field), "my_options", lq_clone({}));

if (!lq_exists(my_lq, page_name)){
	exit;
}

lq_set(lq_get(global.stored_options, my_field), "my_options", lq_delete(my_lq, page_name));

update_optioncont();

/*
Removes an entire category from the options controller/this mod.

option_remove_category("options.mod");

What's the point of this?	Why is there no extended version?
Two very good questions.
*/
#define option_remove_category(category_name)
if (!lq_exists(global.stored_options, category_name)){
	exit;
}

global.stored_options = lq_delete(global.stored_options, category_name);

update_optioncont();

/*
Converts old option configurations within the options controller/this mod to the new configuration.
Probably doesn't break anything, and you should never have to use this yourself.
*/
#define legacy_options_convert(category_name)
var mod_lq = lq_get(global.stored_options, category_name);

var new_lq = {};

lq_set(new_lq, "name", lq_defget(mod_lq, "name", "UNNAMED"));
lq_set(new_lq, "point", lq_defget(mod_lq, "point", "options"));
lq_set(new_lq, "my_options", lq_clone({}));

var new_options = lq_get(new_lq, "my_options");
var mod_types = ["mod", "weapon", "race", "skill", "crown", "area", "skin"];

var _field = "";

with(mod_types){
	if (mod_variable_exists(self, category_name, lq_defget(mod_lq, "point", "options"))){
		_field = `${category_name}.${self}`;
	}
}

var mod_options = lq_defget(mod_lq, "my_options", []);
var _length = array_length(mod_options);
var i = 0;

for (i = 0; _length > i; i ++){
	var _page = mod_options[i];
	
	lq_set(new_options, `PAGE ${i + 1}`, lq_clone({}));
	var new_page = lq_get(new_options, `PAGE ${i + 1}`);
	
	var item_count = array_length(_page);
	var j = 0;
	
	for (j = 0; item_count > j; j ++){
		var _item = _page[j];
		
		if (is_string(_item)){
			if (array_find_index(mod_types, _item) >= 0){
				if (item_count > j + 2){
					var _name = _page[j + 1];
					var _script = _page[j + 2];
					
					if (is_string(_name) && is_string(_script) && mod_script_exists(_item, _name, _script)){
						lq_set(new_options, `PAGE ${i + 1}`, _page);
						break;
					}
				}
			}
			
			option_create(new_page, `title_${j}`, {name: _item, type: "title", desc: _item});
		}
		
		else if (is_object(_item)){
			option_create(new_page, lq_get(_item, "point"), _item);
		}
	}
}

global.stored_options = lq_delete(global.stored_options, category_name);
lq_set(global.stored_options, _field, new_lq);

with(instances_matching(instances_matching_ne(instances_matching(CustomObject, "name", "OptionCont"), "options", null), "persistent", true)){
	options = lq_delete(options, category_name);
	lq_set(options, _field, new_lq);
}

return new_lq;

/*
Creates a new lightweight object in page_lq with the field being option_name.
Uses default values if it can't find them in json_args.
*/
#define option_create(page_lq, option_name, json_args)
if (is_string(json_args)){
	json_args = json_decode(json_args);
}

else if (!is_object(json_args)){
	exit;
}

var option_type = lq_defget(json_args, "type", "bool");
var option_desc = lq_defget(json_args, "desc", "Did you define the#JSON arguments properly?");

lq_set(json_args, "type", lq_defget(json_args, "type", "bool"));
lq_set(json_args, "desc", lq_defget(json_args, "desc", "Did you define the#JSON arguments properly?"));
lq_set(json_args, "nonsync", lq_defget(json_args, "nonsync", false));

switch(string_lower(option_type)){
	default:
	case "bool":{
		lq_set(json_args, "name", lq_defget(json_args, "name", "BLANK BOOL"));
		lq_set(json_args, "display", lq_defget(json_args, "display", ["OFF", "ON"]));
		
		break;
	}
	
	case "int":{
		lq_set(json_args, "name", lq_defget(json_args, "name", "BLANK INT"));
		lq_set(json_args, "steps", lq_defget(json_args, "steps", 1));
		lq_set(json_args, "range", lq_defget(json_args, "range", [null, null]));
		lq_set(json_args, "wrap", lq_defget(json_args, "wrap", true));
		lq_set(json_args, "prefix", lq_defget(json_args, "prefix", ""));
		lq_set(json_args, "suffix", lq_defget(json_args, "suffix", ""));
		
		break;
	}
	
	case "slider":{
		lq_set(json_args, "name", lq_defget(json_args, "name", "BLANK SLIDER"));
		lq_set(json_args, "range", lq_defget(json_args, "range", [0, 1]));
		lq_set(json_args, "prefix", lq_defget(json_args, "prefix", ""));
		lq_set(json_args, "suffix", lq_defget(json_args, "suffix", "%"));
		lq_set(json_args, "steps", lq_defget(json_args, "steps", 0.001));
		lq_set(json_args, "fine_steps", lq_defget(json_args, "fine_steps", 0.1));
		lq_set(json_args, "display", lq_defget(json_args, "display", 100));
		lq_set(json_args, "decimal", lq_defget(json_args, "decimal", 1));
		
		break;
	}
	
	case "cycle":{
		lq_set(json_args, "name", lq_defget(json_args, "name", "BLANK CYCLE"));
		lq_set(json_args, "choices", lq_defget(json_args, "choices", ["OFF", "ON"]));
		lq_set(json_args, "display", lq_defget(json_args, "display", null));
		
		break;
	}
	
	case "text":{
		lq_set(json_args, "name", lq_defget(json_args, "name", "BLANK TEXT"));
		
		break;
	}
	
	case "title":{
		lq_set(json_args, "name", lq_defget(json_args, "name", "BLANK TITLE"));
		
		break;
	}
	
	case "keys":{
		lq_set(json_args, "name", lq_defget(json_args, "name", "BLANK KEYS"));
		lq_set(json_args, "style", lq_defget(json_args, "style", "keys"));
		
		break;
	}
}

lq_set(page_lq, option_name, json_args);

return lq_get(page_lq, option_name);

#define update_optioncont()
with(instances_matching(instances_matching_ne(instances_matching(CustomObject, "name", "OptionCont"), "options", null), "persistent", true)){
	options = global.stored_options;
}

#define scr_slider(_p, _gui, _selected, _x, _y, _value, _args)
if (is_string(_args)){
	_args = json_decode(_args);
}

else if (!is_object(_args)){
	exit;
}

var old_value = _value;

var _range = lq_defget(_args, "range", [0, 1]);
var _min = _range[0];
var _max = _range[1];

var _display = lq_defget(_args, "display", 100);
var _steps = lq_defget(_args, "steps", 0.001);
var fine_steps = lq_defget(_args, "fine_steps", 0.1);
var _decimal = lq_defget(_args, "decimal", 1);
var _prefix = lq_defget(_args, "prefix", "");
var _suffix = lq_defget(_args, "suffix", "%");

var _spr = sprOptionSlider;

var _width = sprite_get_width(_spr);
var _height = sprite_get_height(_spr);

var _bbox = global.option_slider;

var x_boost = (_gui ? view_xview[_p] : 0);
var y_boost = (_gui ? view_yview[_p] : 0);

var mouse_trapped = (point_in_rectangle(mouse_x[_p], mouse_y[_p], (_x + _bbox.left) + x_boost - _width * 0.1, (_y + _bbox.top) + y_boost, (_x + _bbox.right) + x_boost + _width * 0.1, (_y + _bbox.bottom) + y_boost));

var slider_percent = (_value - _min) / (_max - _min);

var max_digits = string_length(string_replace(string_replace(string(_display), ".", ""), "-", "")) + _decimal;

if (mouse_trapped && _selected != 0){
	if (button_pressed(_p, "fire")){
		sound_play_nonsync(_p, sndSlider);
	}
	
	if (button_check(_p, "fire")){
		var _new = ((clamp(mouse_x[_p] - x_boost, (_x + _bbox.left), (_x + _bbox.left) + _width) - (_x + _bbox.left)) / _width * (_display * 10) / (_display * 10)) * (_max - _min) + _min;
		
		var round_to = 1 / _steps;
		
		_new = round(_new * round_to) / round_to;
		
		if (_value != _new){
			sound_play_pitch_nonsync(_p, sndSlider, slider_percent);
			_value = _new;
		}
	}
	
	if (button_released(_p, "fire")){
		sound_play_nonsync(_p, sndSliderLetGo);
	}
}

if ((mouse_trapped && _selected != 0) || _selected > 0){
	if (!button_check(_p, "fire")){
		if (button_pressed(_p, "west")){
			sound_play_nonsync(_p, sndSlider);
			_value = clamp(_value - fine_steps, _min, _max);
		}
		
		else if (button_pressed(_p, "east")){
			sound_play_nonsync(_p, sndSlider);
			_value = clamp(_value + fine_steps, _min, _max);
		}
	}
}

array_push(global.splats[_p], [
	{spr: _spr, img: 0, x: (_x + _bbox.x_offset), y: (_y + _bbox.y_offset)}
]);

array_push(global.nonsplats[_p], [
	{spr: _spr, img: 1, x: (_x + _bbox.x_offset) - sprite_get_xoffset(_spr), y: (_y + _bbox.y_offset) - sprite_get_yoffset(_spr), part: {left: 0, top: 0, width: _width * slider_percent, height: _height}},
	{spr: sprSliderEnd, img: 0, x: (_x + _bbox.x_offset) + _width * slider_percent, y: (_y + _bbox.y_offset) + sprite_get_yoffset(sprSliderEnd) * 0.5},
	{text: `@(color:${(((mouse_trapped && _selected != 0) || _selected > 0) ? c_white : C_GREY)})${_prefix}${string_format(_value * _display, max_digits, _decimal)}${_suffix}`, x: (_x + _bbox.left), y: _y, side: fa_left}
]);

if (_value != old_value){
	return _value;
}

return null;

#define scr_bool(_p, _gui, _selected, _x, _y, _value, _args)
if (is_string(_args)){
	_args = json_decode(_args);
}

else if (!is_object(_args)){
	exit;
}

var old_value = _value;

var _display = lq_defget(_args, "display", ["OFF", "ON"]);

var _spr = sprScoreSplat;

var _width = sprite_get_width(_spr);
var _height = sprite_get_height(_spr);

var _bbox = global.score_splat;

var x_boost = (_gui ? view_xview[_p] : 0);
var y_boost = (_gui ? view_yview[_p] : 0);

var mouse_trapped = (point_in_rectangle(mouse_x[_p], mouse_y[_p], (_x + _bbox.left) + x_boost, (_y + _bbox.top) + y_boost, (_x + _bbox.right) + x_boost, (_y + _bbox.bottom) + y_boost));

if (((mouse_trapped && _selected != 0) || _selected > 0) && (button_pressed(_p, "fire") || button_pressed(_p, "okay") || button_pressed(_p, "east") || button_pressed(_p, "west"))){
	sound_play_nonsync(_p, sndClick);
	_value = !_value;
}

array_push(global.splats[_p], [
	{spr: _spr, img: 2, x: (_x + _bbox.x_offset), y: (_y + _bbox.y_offset)}
]);

array_push(global.nonsplats[_p], [
	{text: `@(color:${(((mouse_trapped && _selected != 0) || _selected > 0) ? c_white : C_GREY)})${_display[_value]}`, x: _x, y: _y}
]);

if (_value != old_value){
	return _value;
}

return null;

#define scr_int(_p, _gui, _selected, _x, _y, _value, _args)
if (is_string(_args)){
	_args = json_decode(_args);
}

else if (!is_object(_args)){
	exit;
}

var old_value = _value;

var _steps = lq_defget(_args, "steps", 1);
var _range = lq_defget(_args, "range", [null, null]);
var _wrap = lq_defget(_args, "wrap", true);
var _prefix = lq_defget(_args, "prefix", "");
var _suffix = lq_defget(_args, "suffix", "");

var _spr = sprScoreSplat;

var _width = sprite_get_width(_spr);
var _height = sprite_get_height(_spr);

var _bbox = global.score_splat;

var x_boost = (_gui ? view_xview[_p] : 0);
var y_boost = (_gui ? view_yview[_p] : 0);

var mouse_trapped = (point_in_rectangle(mouse_x[_p], mouse_y[_p], (_x + _bbox.left) + x_boost, (_y + _bbox.top) + y_boost, (_x + _bbox.right) + x_boost, (_y + _bbox.bottom) + y_boost));

array_push(global.splats[_p], [
	{spr: _spr, img: 2, x: (_x + _bbox.x_offset), y: (_y + _bbox.y_offset)}
]);

array_push(global.nonsplats[_p], [
	{text: `@(color:${(((mouse_trapped && _selected != 0) || _selected > 0) ? c_white : C_GREY)})${_prefix}${_value}${_suffix}`, x: _x, y: _y}
]);

if ((mouse_trapped && _selected != 0) || _selected > 0){
	var _dir = sign(button_pressed(_p, "east") - button_pressed(_p, "west"));
	
	if (_dir != 0){
		sound_play_nonsync(_p, sndClick);
		_value += _dir * _steps;
	}
}

if (_value != old_value){
	if (!_wrap || is_undefined(_range[0]) || is_undefined(_range[1])){
		_value = (!is_undefined(_range[0]) ? max(_range[0], _value) : _value);
		_value = (!is_undefined(_range[1]) ? min(_range[1], _value) : _value);
		
		return _value;
	}
	
	return wrap_clamp(_value, (!is_undefined(_range[0]) ? _range[0] : _value), (!is_undefined(_range[1]) ? _range[1] : _value));
}

return null;

#define scr_cycle(_p, _gui, _selected, _x, _y, _value, _args)
if (is_string(_args)){
	_args = json_decode(_args);
}

else if (!is_object(_args)){
	exit;
}

var old_value = _value;

var _choices = lq_defget(_args, "choices", ["I", "wasn't", "set", "up", "properly!"]);
var choice_count = array_length(_choices);
var _display = lq_defget(_args, "display", null);

var _i = array_find_index(_choices, _value);

var _spr = sprScoreSplat;

var _width = sprite_get_width(_spr);
var _height = sprite_get_height(_spr);

var _bbox = global.score_splat;

var x_boost = (_gui ? view_xview[_p] : 0);
var y_boost = (_gui ? view_yview[_p] : 0);

var mouse_trapped = (point_in_rectangle(mouse_x[_p], mouse_y[_p], (_x + _bbox.left) + x_boost, (_y + _bbox.top) + y_boost, (_x + _bbox.right) + x_boost, (_y + _bbox.bottom) + y_boost));

if ((mouse_trapped && _selected != 0) || _selected > 0){
	var _dir = sign((button_pressed(_p, "fire") || button_pressed(_p, "okay") || button_pressed(_p, "east")) - button_pressed(_p, "west"));
	
	if (_dir != 0){
		sound_play_nonsync(_p, sndClick);
		_i = wrap_clamp(_i + 1, 0, choice_count - 1);
		_value = _choices[_i];
	}
}

array_push(global.splats[_p], [
	{spr: _spr, img: 2, x: (_x + _bbox.x_offset), y: (_y + _bbox.y_offset)}
]);

array_push(global.nonsplats[_p], [
	{text: `@(color:${(((mouse_trapped && _selected != 0) || _selected > 0) ? c_white : C_GREY)})${(!is_undefined(_display) && array_length(_display) >= choice_count ? _display[_i] : _value)}`, x: _x, y: _y}
]);

if (_value != old_value){
	return _value;
}

return null;

// the actual stuff happens in #define chat_message
#define scr_text(_p, _gui, _selected, _x, _y, _value, _args)					
var _spr = sprOptionSlider;

var _width = sprite_get_width(_spr);
var _height = sprite_get_height(_spr);

var _bbox = global.option_slider;

var x_boost = (_gui ? view_xview[_p] : 0);
var y_boost = (_gui ? view_yview[_p] : 0);

var mouse_trapped = (point_in_rectangle(mouse_x[_p], mouse_y[_p], (_x + _bbox.left) + x_boost, (_y + _bbox.top) + y_boost, (_x + _bbox.right) + x_boost, (_y + _bbox.bottom) + y_boost));

array_push(global.splats[_p], [
	{spr: _spr, img: 0, x: (_x + _bbox.x_offset), y: (_y + _bbox.y_offset)}
]);

array_push(global.nonsplats[_p], [
	{text: `@(color:${(_selected > 0 ? c_white : C_GREY)})${((mouse_trapped && button_check(_p, "talk")) || _selected - 1 > 0 ? (current_frame div 1 % 40 / current_time_scale <= 20 ? "|" : "") : _value)}`, x: (_x + _bbox.right), y: _y, side: fa_right}
]);

return null;

#define scr_keys(_p, _gui, _selected, _x, _y, _value, _args)
if (is_string(_args)){
	_args = json_decode(_args);
}

else if (!is_object(_args)){
	exit;
}

var old_value = _value;

var _style = lq_defget(_args, "style", "keys");

var _buttons = ["fire", "spec", "pick", "swap", "nort", "sout", "east", "west", "key1", "key2", "key3", "key4", "key5", "key6", "key7", "key8", "key9"];

var _spr = sprOptionSlider;

var _width = sprite_get_width(_spr);
var _height = sprite_get_height(_spr);

var _bbox = global.option_slider;

var x_boost = (_gui ? view_xview[_p] : 0);
var y_boost = (_gui ? view_yview[_p] : 0);

var mouse_trapped = (point_in_rectangle(mouse_x[_p], mouse_y[_p], (_x + _bbox.left) + x_boost, (_y + _bbox.top) + y_boost, (_x + _bbox.right) + x_boost, (_y + _bbox.bottom) + y_boost));

var _combo = "";
var my_value = string_split(_value, "+");

if (_style != "text"){
	with(my_value){
		var is_number = (string_count("key", self) >= 1);
		_combo += `+@3(sprKeySmall:${(is_number ? string(48 + real(string_char_at(self, 4))) : self)})`;
	}
}

else{
	_combo = array_join(my_value, "+");
}

if (_style != "text" && string_length(_combo) >= 1){
	_combo = string_delete(_combo, 1, 1);
}

array_push(global.splats[_p], [
	{spr: _spr, img: 0, x: (_x + _bbox.x_offset), y: (_y + _bbox.y_offset)}
]);

array_push(global.nonsplats[_p], [
	{text: `@(color:${(_selected > 0 ? c_white : C_GREY)})${_combo}`, x: (_x + _bbox.right), y: _y, side: fa_right}
]);

var my_keys = (global.menu_stuff.key_timer[_p] > 0 ? string_split(_value, "+") : []);
var key_count = 0;

if (_selected - 1 > 0){
	with(_buttons){
		if ((self != "fire" || global.menu_stuff.key_timer[_p] > 0) && button_check(_p, self) && array_find_index(my_keys, self) < 0){
			var is_number = (string_count("key", self) >= 1);
			key_count += 1;
			
			if (_style != "text"){
				_combo += `+@3(sprKeySmall:${(is_number ? string(48 + real(string_char_at(self, 4))) : self)})`;
			}
			
			array_push(my_keys, self);
		}
	}
	
	if (_style == "text"){
		_combo = array_join(my_keys, "+");
	}
}

if (key_count <= 0){
	my_keys = string_split(_value, "+");
	
	if (_style != "text"){
		with(my_keys){
			_combo += `+@3(sprKeySmall:${(string_count("key", self) >= 1 ? string(48 + real(string_char_at(self, 4))) : self)})`;
		}
	}
	
	else{
		_combo = array_join(my_keys, "+");
	}
}

else{
	global.menu_stuff.key_timer[_p] = 15;
}

if (global.menu_stuff.key_timer[_p] > 0){
	global.menu_stuff.key_timer[_p] -= current_time_scale;
	_value = array_join(my_keys, "+");
}

if (_selected > 0 && _value != old_value){
	return _value;
}

return null;

#define sound_play_nonsync(_p, _sound)
if (sound_exists(_sound) && _p == player_find_local_nonsync()){
	sound_play(_sound);
}

#define sound_play_pitch_nonsync(_p, _sound, _pitch)
if (sound_exists(_sound) && _p == player_find_local_nonsync()){
	sound_play_pitch(_sound, _pitch);
}

// I completely destroyed it, but it works better now
// don't use this as an example for learning
#define draw_pause
var show_time = false;

if (show_time){
	trace_time();
}

var _halign = draw_get_halign();
var _valign = draw_get_valign();

draw_set_projection(0);

var _vx = 0;
var _vy = 0;
var _cx = _vx + game_width * 0.5;
var _cy = _vy + game_height * 0.5;

var arrow_width = sprite_get_width(sprDailyArrow);
var arrow_height = sprite_get_height(sprDailyArrow);

var menu_stuff = global.menu_stuff;
var local_player = player_find_local_nonsync();

var _clicked = false;

if (instance_exists(OptionMenuButton)){
	draw_set_font(fntBigName);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	
	var _obj = lq_get_value(global.stored_options, global.menu_stuff.page_index);
	var my_options = lq_defget(_obj, "my_options", lq_clone({}));
	var _pages = lq_size(global.stored_options);
	
	if (is_array(my_options)){
		legacy_options_convert(lq_get_key(global.stored_options, global.menu_stuff.page_index));
	}
	
	while (_pages > 0){
		var my_pages = lq_size(my_options);
		var i = 0;
		
		for (i = 0; my_pages > i; i ++){
			var my_items = lq_size(lq_get_value(my_options, i));
			
			if (my_items > 0 || is_array(lq_get_value(my_options, i))){
				continue;
			}
			
			option_remove_page(lq_get_key(global.stored_options, global.menu_stuff.page_index), lq_get_key(my_options, i));
		}
		
		if ((is_object(_obj) && _pages > 0) || (is_object(my_options) && lq_size(my_options) > 0)){
			break;
		}
		
		option_remove_category(lq_get_key(global.stored_options, global.menu_stuff.page_index));
		global.menu_stuff.page_index = min(global.menu_stuff.page_index, _pages - 1);
		_obj = lq_get_value(global.stored_options, global.menu_stuff.page_index);
		my_options = lq_defget(mod_lq, "my_options", lq_clone({}));
		_pages = lq_size(global.stored_options);
	}
	
	if (is_object(_obj)){
		var _text = lq_get(_obj, "name");
		var broken_text = string_add_linebreaks(_text);
		var text_width = max(string_width(broken_text), 24);
		var text_height = max(string_height(broken_text), SINGLE_LINE_HEIGHT);
		
		var surface_xscale = 0.65;
		var surface_yscale = surface_xscale;
		
		var text_left = _cx - text_width * 0.5 * surface_xscale;
		var text_top = _vy + BUTTON_POS_Y - text_height * surface_yscale * 1.1 - 21 + text_height div SINGLE_LINE_HEIGHT * 2;
		
		var text_surface_drawn = false;
		
		with(mouse_in_rectangle(-1, text_left, text_top, text_left + text_width * surface_xscale, text_top + text_height * surface_yscale, true)){
			if (!text_surface_drawn && self == local_player){
				with(other){
					draw_sprite_ext(sprMainMenuSplat, 3, _cx,	+ BUTTON_POS_Y - text_height * surface_yscale * 0.55 - 21 + text_height div SINGLE_LINE_HEIGHT * 2, 1, 1, 0, c_white, 1);
				}
				
				text_surface_drawn = true;
				draw_text_transformed_color(_cx, text_top, _text, surface_xscale, surface_yscale, 0, c_white, c_white, c_white, c_white, 1);
			}
			
			if (button_pressed(self, "fire") || button_pressed(self, "okay")){
				sound_play_nonsync(self, sndClick);
				
				global.menu_stuff.view_settings = true;
				
				if (array_length(instances_matching(CustomScript, mod_current, "CustomOptionsDraw")) <= 0){
					with(script_bind_draw(draw_options, -1111)){
						variable_instance_set(id, mod_current, "CustomOptionsDraw");
						persistent = true;
						mod_source = mod_current;
					}
				}
				
				with(OptionMenuButton){
					instance_destroy();
				}
				
				_clicked = true;
				
				break;
			}
			
			else{
				var _dir = sign(button_pressed(self, "east") - button_pressed(self, "west"));
				
				if (_dir != 0){
					sound_play_nonsync(self, sndClick);
					global.menu_stuff.page_index += _dir;
					break;
				}
			}
		}
		
		if (!text_surface_drawn){
			draw_text_transformed_color(_cx, text_top, _text, surface_xscale, surface_yscale, 0, C_GREY, C_GREY, C_GREY, C_GREY, 1);
		}
		
		if (_pages > 1){
			var left_arrow_drawn = false;
			var right_arrow_drawn = false;
			
			with(mouse_in_rectangle(-1, text_left - arrow_width, text_top, text_left, text_top + text_height * surface_yscale, true)){
				if (!left_arrow_drawn && self == local_player){
					left_arrow_drawn = true;
					
					with(other){
						draw_sprite_ext(sprDailyArrow, 0, text_left - arrow_width * 0.2 + global.left_daily_arrow.x_offset, text_top + text_height * surface_yscale * 0.5 + global.left_daily_arrow.y_offset, 1, 1, 0, c_white, 1);
					}
				}
				
				if (button_pressed(self, "fire")){
					sound_play_nonsync(self, sndClick);
					global.menu_stuff.page_index -= 1;
					break;
				}
			}
			
			if (!left_arrow_drawn){
				draw_sprite_ext(sprDailyArrow, 0, text_left - arrow_width * 0.2 + global.left_daily_arrow.x_offset, text_top + text_height * surface_yscale * 0.5 + global.left_daily_arrow.y_offset, 1, 1, 0, C_GREY, 1);
			}
			
			with(mouse_in_rectangle(-1, text_left + text_width * surface_xscale, text_top, text_left + text_width * surface_xscale + arrow_width, text_top + text_height * surface_yscale, true)){
				if (!right_arrow_drawn && self == local_player){
					right_arrow_drawn = true;
					
					with(other){
						draw_sprite_ext(sprDailyArrow, 1, text_left + text_width * surface_xscale + arrow_width * 0.2 + global.right_daily_arrow.x_offset, text_top + text_height * surface_yscale * 0.5 + global.right_daily_arrow.y_offset, 1, 1, 0, c_white, 1);
					}
				}
				
				if (button_pressed(self, "fire")){
					sound_play_nonsync(self, sndClick);
					global.menu_stuff.page_index += 1;
				}
			}
			
			if (!right_arrow_drawn){
				draw_sprite_ext(sprDailyArrow, 1, text_left + text_width * surface_xscale + arrow_width * 0.2 + global.right_daily_arrow.x_offset, text_top + text_height * surface_yscale * 0.5 + global.right_daily_arrow.y_offset, 1, 1, 0, C_GREY, 1);
			}
		}
		
		global.menu_stuff.page_index = wrap_clamp(global.menu_stuff.page_index, 0, _pages - 1);
	}
	
	else{
		global.stored_options = lq_delete(global.stored_options, lq_get_key(global.stored_options, global.menu_stuff.page_index));
		
		global.menu_stuff.page_index = wrap_clamp(global.menu_stuff.page_index, 0, _pages - 1);
	}
}

if (!_clicked && !instance_exists(menubutton) && global.menu_stuff.view_settings){
	var mod_details = string_split(lq_get_key(global.stored_options, global.menu_stuff.page_index), ".");
	var dot_count = array_length(mod_details);
	
	var mod_name = array_join(array_slice(mod_details, 0, dot_count - 1), ".");
	var mod_type = mod_details[dot_count - 1];
	
	var mod_lq = lq_get_value(global.stored_options, global.menu_stuff.page_index);
	var my_options = lq_defget(mod_lq, "my_options", lq_clone({}));
	
	var my_variable = (lq_exists(mod_lq, "point") ? lq_get(mod_lq, "point") : "options");
	
	var page_count = lq_size(my_options);
	
	var page_width = 16;
	var page_height = 16;
	
	var _xscale = 1;
	var _yscale = _xscale;
	
	var name_left = _cx - page_width * 0.5 * _xscale;
	var name_top = _vy + game_height - page_height * _yscale - 6;
	
	var option_count = 0;
	var page_name = "";
	
	var _highlight = array_create(maxp, -1);
	
	var p = 0;
	
	for (p = 0; maxp > p; p ++){
		if (player_is_active(p)){
			if (player_is_local_nonsync(p) && p != player_find_local_nonsync()){
				continue;
			}
			
			draw_set_visible_all(false);
			draw_set_visible(p, true);
			
			var _mx = mouse_x[p] + (_vx - view_xview[p]);
			var _my = mouse_y[p] + (_vy - view_yview[p]);
			
			var _lmb = button_pressed(p, "fire");
			var _enter = button_pressed(p, "okay");
			var _left = button_pressed(p, "west");
			var _right = button_pressed(p, "east");
			var _up = button_pressed(p, "nort");
			var _down = button_pressed(p, "sout");
			
			var my_page = lq_get_value(my_options, global.menu_stuff.settings_page[p]);
			page_name = lq_get_key(my_options, global.menu_stuff.settings_page[p]);
			
			global.menu_stuff.settings_page[p] = clamp(global.menu_stuff.settings_page[p], 0, page_count - 1);
			
			option_count = lq_size(my_page);
			
			while (option_count <= 0 && page_count >= 1 && !is_array(my_page)){
				option_remove_page_ext(mod_type, mod_name, page_name);
				my_options = lq_defget(mod_lq, "my_options", lq_clone({}));
				page_count = lq_size(my_options);
				global.menu_stuff.settings_page[p] = min(global.menu_stuff.settings_page[p], page_count - 1);
				my_page = lq_get_value(my_options, global.menu_stuff.settings_page[p]);
				page_name = lq_get_key(my_options, global.menu_stuff.settings_page[p]);
				option_count = lq_size(my_page);
			}
			
			var broken_page_name = string_add_linebreaks(page_name);
			
			if (page_count > 1){
				draw_set_font(fntL);
				draw_set_halign(fa_center);
				draw_set_valign(fa_top);
				
				page_width = max(string_width(broken_page_name), 16);
				page_height = max(string_height(broken_page_name), 16);
				
				name_left = _cx - page_width * 0.5 * _xscale;
				name_top = _vy + game_height - page_height * _yscale - 6;
				
				if (point_in_rectangle(_mx, _my, name_left, name_top, name_left + page_width * _xscale, name_top + page_height * _yscale) || (global.menu_stuff.side[p] == 0 && global.menu_stuff.selected[p] == option_count)){
					global.menu_stuff.selected[p] = option_count;
					global.menu_stuff.side[p] = 0;
					_highlight[p] = fa_center;
				}
				
				if (point_in_rectangle(_mx, _my, name_left - arrow_width, name_top, name_left, name_top + page_height * _yscale) || (global.menu_stuff.side[p] == -1 && global.menu_stuff.selected[p] == option_count)){
					global.menu_stuff.side[p] = -1;
					global.menu_stuff.selected[p] = option_count;
					_highlight[p] = fa_left;
				}
				
				else if (point_in_rectangle(_mx, _my, name_left + page_width * _xscale, name_top, name_left + page_width * _xscale + arrow_width, name_top + page_height * _yscale) || (global.menu_stuff.side[p] == 1 && global.menu_stuff.selected[p] == option_count)){
					global.menu_stuff.side[p] = 1;
					global.menu_stuff.selected[p] = option_count;
					_highlight[p] = fa_right;
				}
				
				else{
					global.menu_stuff.side[p] = 0;
				}
				
				if (global.menu_stuff.side[p] != 0 && (_lmb || _enter)){
					sound_play_nonsync(p, sndClick);
					global.menu_stuff.settings_page[p] = wrap_clamp(global.menu_stuff.settings_page[p] + global.menu_stuff.side[p], 0, page_count - 1);
					global.menu_stuff.side[p] = 0;
					global.menu_stuff.selected[p] = -1;
				}
				
				my_page = lq_get_value(my_options, global.menu_stuff.settings_page[p]);
				option_count = lq_size(my_page);
				
				draw_set_font(fntM);
				draw_set_halign(fa_left);
				draw_set_valign(fa_top);
			}
			
			if (is_array(my_page) && script_ref_call(my_page, p)){
				option_count = 0;
				global.menu_stuff.selected[p] = -1;
				draw_set_projection(0);
			}
			
			if (option_count <= 0){
				continue;
			}
			
			if (global.menu_stuff.selected[p] < 10016){
				var _dir = sign(_down - _up);
				global.menu_stuff.selected[p] = wrap_clamp(global.menu_stuff.selected[p] + _dir, -1, option_count - (page_count <= 1));
				
				if (global.menu_stuff.selected[p] == option_count){
					var _side = sign(_right - _left);
					global.menu_stuff.side[p] = clamp(global.menu_stuff.side[p] + _side, -1, 1);
				}
			}
			
			if (is_object(my_page)){
				var _space = 0;
				var o = option_count;
				
				var option_height = 0;
				var line_height = string_height("OFF") + 4;
				
				for (o = 0; option_count > o; o ++){
					var _me = lq_get_value(my_page, o);
					
					if (is_object(_me)){
						option_height += (4 + string_height(string_add_linebreaks(lq_defget(_me, "name", "BLANK TITLE"))));
						option_height += (lq_defget(_me, "pixels", 0) + lq_defget(_me, "lines", 0) * line_height);
					}
				}
				
				var mod_options = mod_variable_get(mod_type, mod_name, my_variable);
				
				var _selected = 0;
				
				for (o = 0; option_count > o; o ++){
					var _key = lq_get_key(my_page, o);
					var _me = lq_get_value(my_page, o);
					var _pressed = array_create(maxp, false);
					
					if (is_object(_me)){
						_space += lq_defget(_me, "pixels", 0);
						var local_space = 4 + string_height(string_add_linebreaks(lq_defget(_me, "name", "BLANK TITLE"))) + lq_defget(_me, "lines", 0) * line_height;
						var my_y = round(_cy + _space - option_height * 0.5);
						_space += local_space;
						
						var name_x = round(_vx + game_width * 0.111);
						var value_x = round(_vx + game_width * 0.777);
						
						var bounds_left = _vx + game_width * 0.078;
						var bounds_right = _vx + game_width * 0.966;
						
						if (point_in_rectangle(_mx, _my, bounds_left, my_y - line_height * 0.5, bounds_right, my_y + line_height * 0.5)){
							if (global.menu_stuff.selected[p] < 10016){
								global.menu_stuff.selected[p] = o;
							}
						}
						
						if (global.menu_stuff.selected[p] == o + 10016 && (button_pressed(p, "okay")) && global.menu_stuff.pressed[p]){
							_pressed[p] = true;
						}
						
						var _type = string_lower(lq_defget(_me, "type", "title"));
						var _name = lq_defget(_me, "name", "BLANK TITLE");
						var broken_name = string_add_linebreaks(_name);
						
						var _nonsync = lq_defget(_me, "nonsync", false);
						var fake_nonsync = lq_defget(_me, "fake_nonsync", false);
						
						_selected = (_selected <= 0 && (global.menu_stuff.selected[p] == o || global.menu_stuff.selected[p] == o + 10016) + (global.menu_stuff.selected[p] == o + 10016));
						
						var _scr = -1;
						
						if (_type != "title"){
							switch(_type){
								case "bool": _scr = scr_bool; break;
								case "int": _scr = scr_int; break;
								case "slider": _scr = scr_slider; break;
								case "cycle": _scr = scr_cycle; break;
								case "text": _scr = scr_text; break;
								case "keys": _scr = scr_keys; break;
							}
						}
						
						var _point = lq_defget(_me, "point", -1);
						
						if (is_array(_point) && array_length(_point) >= 3){
							var _current = option_get(_point[0], _point[1], _point[2], _key);
							
							if (_scr != -1 && (!_nonsync || p == local_player)){
								if (fake_nonsync && is_array(_current) && array_length(_current) > p){
									var _value = script_execute(_scr, p, true, _selected, value_x, my_y, _current[p], _me);
									
									if (_selected > 0 && _type != "text"){
										option_set_fake_nonsync(_point[0], _point[1], _point[2], p, _key, _value);
									}
								}
								
								else if (!fake_nonsync){
									var _value = script_execute(_scr, p, true, _selected, value_x, my_y, _current, _me);
									
									if (_selected > 0 && _type != "text"){
										option_set(_point[0], _point[1], _point[2], _key, _value);
									}
								}
							}
						}
						
						else{
							var _current = lq_get(mod_options, _key);
							
							if (_scr != -1 && (!_nonsync || p == local_player)){
								if (fake_nonsync && is_array(_current) && array_length(_current) > p){
									var _value = script_execute(_scr, p, true, _selected, value_x, my_y, _current[p], _me);
									
									if (_selected > 0 && _type != "text"){
										option_set_fake_nonsync(mod_type, mod_name, my_variable, p, _key, _value);
									}
								}
								
								else if (!fake_nonsync){
									var _value = script_execute(_scr, p, true, _selected, value_x, my_y, _current, _me);
									
									if (_selected > 0 && _type != "text"){
										option_set(mod_type, mod_name, my_variable, _key, _value);
									}
								}
							}
						}
						
						var slider_bbox = global.option_slider;
						
						if (_selected > 0){
							if (p == local_player){
								if (_type == "title"){
									array_push(global.splats[local_player], [
										{spr: sprMainMenuSplat, img: 3, x: _cx, y: my_y}
									]);
									
									array_push(global.nonsplats[local_player], [
										{text: `@(color:${c_white})${_name}`, x: _cx, y: my_y}
									]);
								}
								
								else{
									array_push(global.splats[local_player], [
										{spr: sprMainMenuSplat, img: 3, x: name_x + sprite_get_xoffset(sprMainMenuSplat), y: my_y}
									]);
									
									array_push(global.nonsplats[local_player], [
										{text: `@(color:${c_white})${_name}`, x: name_x, y: my_y, side: fa_left}
									]);
								}
							}
							
							var _desc = lq_defget(_me, "desc", "");
							
							if (string_length(_desc) > 0){
								draw_tooltip_projection_nonsync(p, _cx, _cy - option_height * 0.5, _desc);
							}
							
							if (_type == "text" || _type == "keys"){
								var mouse_in_text_box = (_mx >= slider_bbox.left + value_x && _my >= slider_bbox.top + my_y && _mx <= slider_bbox.right + value_x && _my <= slider_bbox.bottom + my_y);
								
								if (((mouse_in_text_box && button_pressed(p, "fire")) || button_pressed(p, "okay")) && !_pressed[p] && global.menu_stuff.selected[p] == o){
									global.menu_stuff.pressed[p] = true;
									global.menu_stuff.selected[p] = o + 10016;
								}
							}
						}
						
						else{
							if (p == local_player){
								if (_type == "title"){
									array_push(global.nonsplats[local_player], [
										{text: `@(color:${C_GREY})${_name}`, x: _cx, y: my_y}
									]);
								}
								
								else{
									array_push(global.nonsplats[local_player], [
										{text: `@(color:${C_GREY})${_name}`, x: name_x, y: my_y, side: fa_left}
									]);
								}
							}
						}
						
						if (_pressed[p]){
							global.menu_stuff.pressed[p] = false;
							global.menu_stuff.selected[p] = o;
						}
					}
				}
			}
		}
	}
	
	draw_reset_projection();
	
	draw_set_visible_all(true);
	
	if (page_count > 1){
		draw_set_font(fntL);
		draw_set_halign(fa_center);
		draw_set_valign(fa_top);
		
		page_name = string_add_linebreaks(lq_get_key(my_options, global.menu_stuff.settings_page[local_player]));
		var broken_page_name = string_add_linebreaks(page_name);
		
		page_width = max(string_width(broken_page_name), 16);
		page_height = max(string_height(broken_page_name), 16);
		
		name_left = _cx - page_width * 0.5 * _xscale;
		name_top = _vy + game_height - page_height * _yscale;
		
		var page_drawn = false;
		
		if (_highlight[local_player] == fa_center){
			draw_text_transformed_color(view_xview_nonsync + _cx, view_yview_nonsync + name_top, page_name, _xscale, _yscale, 0, c_white, c_white, c_white, c_white, 1);
			page_drawn = true;
		}
		
		else{
			draw_text_transformed_color(view_xview_nonsync + _cx, view_yview_nonsync + name_top, page_name, _xscale, _yscale, 0, C_GREY, C_GREY, C_GREY, C_GREY, 1);
		}
		
		name_top -= 6;
		
		switch(_highlight[local_player]){
			case fa_left:{
				array_push(global.splats[local_player], [
					{spr: sprDailyArrowSplat, img: 3, x: name_left - arrow_width * 0.2 + global.daily_splat.x_offset, y: name_top + arrow_height * 0.5 + global.daily_splat.y_offset}
				]);
				
				array_push(global.nonsplats[local_player], [
					{spr: sprDailyArrow, img: 0, x: name_left - arrow_width * 0.2 + global.left_daily_arrow.x_offset, y: name_top + arrow_height * 0.5 + global.left_daily_arrow.y_offset, blend: c_white},
					{spr: sprDailyArrow, img: 1, x: name_left + page_width + arrow_width * 0.2 + global.right_daily_arrow.x_offset, y: name_top + arrow_height * 0.5 + global.right_daily_arrow.y_offset, blend: C_GREY}
				]);
				
				break;
			}
			
			case fa_right:{
				array_push(global.splats[local_player], [
					{spr: sprDailyArrowSplat, img: 3, x: name_left + page_width + arrow_width * 0.2 + global.daily_splat.x_offset, y: name_top + arrow_height * 0.5 + global.daily_splat.y_offset}
				]);
				
				array_push(global.nonsplats[local_player], [
					{spr: sprDailyArrow, img: 0, x: name_left - arrow_width * 0.2 + global.left_daily_arrow.x_offset, y: name_top + arrow_height * 0.5 + global.left_daily_arrow.y_offset, blend: C_GREY},
					{spr: sprDailyArrow, img: 1, x: name_left + page_width + arrow_width * 0.2 + global.right_daily_arrow.x_offset, y: name_top + arrow_height * 0.5 + global.right_daily_arrow.y_offset, blend: c_white}
				]);
				
				break;
			}
			
			default:{
				array_push(global.nonsplats[local_player], [
					{spr: sprDailyArrow, img: 0, x: name_left - arrow_width * 0.2 + global.left_daily_arrow.x_offset, y: name_top + arrow_height * 0.5 + global.left_daily_arrow.y_offset, blend: C_GREY},
					{spr: sprDailyArrow, img: 1, x: name_left + page_width + arrow_width * 0.2 + global.right_daily_arrow.x_offset, y: name_top + arrow_height * 0.5 + global.right_daily_arrow.y_offset, blend: C_GREY}
				]);
				
				break;
			}
		}
		
		draw_set_font(fntM);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		
		if (page_drawn){
			draw_tooltip_projection_nonsync(local_player, _cx, name_top, `Page ${global.menu_stuff.settings_page[local_player] + 1} of ${page_count}`);
		}
	}
}

if (instance_exists(menubutton) && global.menu_stuff.view_settings){
	global.menu_stuff.view_settings = false;
	
	array_clear(global.menu_stuff.selected, -1);
	array_clear(global.menu_stuff.pressed, false);
	array_clear(global.menu_stuff.side, 0);
	
	with(instances_matching_ne(CustomScript, mod_current, null)){
		instance_destroy();
	}
	
	var mod_details = string_split(lq_get_key(global.stored_options, global.menu_stuff.page_index), ".");
	var dot_count = array_length(mod_details);
	
	var mod_name = array_join(array_slice(mod_details, 0, dot_count - 1), ".");
	var mod_type = mod_details[dot_count - 1];
	
	if (mod_script_exists(mod_type, mod_name, "save_options")){
		mod_script_call(mod_type, mod_name, "save_options");
	}
}

draw_reset_projection();

draw_set_font(fntM);
draw_set_halign(_halign);
draw_set_valign(_valign);

if (show_time){
	trace_time("pause");
}

#define draw_tooltip_projection_nonsync(_p, _x, _y, _text)
if (player_find_local_nonsync() != _p){
	exit;
}

draw_reset_projection();

draw_tooltip(view_xview_nonsync + _x, view_yview_nonsync + _y, _text);

draw_set_projection(0);

#define mouse_in_rectangle(_p, _x1, _y1, _x2, _y2, _gui)
var _x = _x1;
var _y = _y1;

_x1 = min(_x1, _x2);
_y1 = min(_y1, _y2);
_x2 = max(_x, _x2);
_y2 = max(_y, _y2);

var _players = [];

if (_p >= 0 && maxp > _p){
	if (player_is_active(_p)){
		var _mx = mouse_x[_p] - (_gui ? view_xview[_p] : 0);
		var _my = mouse_y[_p] - (_gui ? view_yview[_p] : 0);
		
		if (point_in_rectangle(_mx, _my, _x1, _y1, _x2, _y2)){
			array_push(_players, _p);
		}
	}
}

else{
	var p = 0;
	
	for (p = 0; maxp > p; p ++){
		if (player_is_active(p)){
			if (player_is_local_nonsync(p) && p != player_find_local_nonsync()){
				continue;
			}
			
			var _mx = mouse_x[p] - (_gui ? view_xview[p] : 0);
			var _my = mouse_y[p] - (_gui ? view_yview[p] : 0);
			
			if (point_in_rectangle(_mx, _my, _x1, _y1, _x2, _y2)){
				array_push(_players, p);
			}
		}
	}
}

return _players;

// https://forum.yoyogames.com/index.php?threads/string-2-number.16835/#post-108369
#define sign_string_dotdigits(_str)
var _d = "112935";
var _s = "1625541";

while (string_pos(_d, _str)){
	_d += _d;
}

while (string_pos(_s, _str)){
	_s += _s;
}

return string_replace(string_replace(string_digits(string_replace(string_replace(_str, ".", _d), "-", _s)), _d, "."), _s, "-");

#define string_add_linebreaks(_str)
if (!is_string(_str)){
	_str = string(_str);
}

var new_str = _str;
var _height = string_height(new_str);
var _pos = string_pos("#", new_str);

while (_pos > 0 && _pos < string_length(new_str)){
	new_str = string_replace(new_str, "#", chr(13));
	_pos = string_pos("#", new_str);
}

return (_height != string_height(new_str) ? new_str : _str);

#define lq_delete(_lq, _field)
var o = {};

var _size = lq_size(_lq);
var i = 0;

for (i = 0; _size > i; i ++){
	var _key = lq_get_key(_lq, i);
	
	if (_key != _field){
		lq_set(o, _key, lq_get(_lq, _key));
	}
}

return o;

// #define wrap(_value, _min, _max)
// var _r = _max - _min + 1;

// return ((((_value - _min) % _r) + _r) % _r) + _min;

//what do I call this
#define wrap_clamp(_value, _min, _max)
if (_value < _min){
	_value = _max;
}

if (_value > _max){
	_value = _min;
}

return _value;

#define sprite_image_get_bbox(_x, _y, _spr, _img)
var _uvs = sprite_get_uvs(_spr, _img);

var _width = sprite_get_width(_spr) * _uvs[6];
var _height = sprite_get_height(_spr) * _uvs[7];
var _left = _uvs[4];
var _top = _uvs[5];

return {
	left: _x - _width * 0.5,
	right: _x + _width * 0.5,
	top: _y - _height * 0.5,
	bottom: _y + _height * 0.5,
	
	x_offset: _x + sprite_get_xoffset(_spr) - (_left + _width * 0.5),
	y_offset: _y + sprite_get_yoffset(_spr) - (_top + _height * 0.5)
};
