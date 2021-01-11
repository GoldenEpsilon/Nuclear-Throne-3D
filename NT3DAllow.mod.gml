#define step
if(mod_sideload()){
	string_save("/allowmod NT3D", "allow.txt");
	mod_loadtext("data/"+mod_current+".mod/allow.txt");
	mod_unload(mod_current)
}