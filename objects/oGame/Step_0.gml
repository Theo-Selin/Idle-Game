/// oGame.Step
/// DEV: Reset all progress (Ctrl+Shift+R)
if (keyboard_check_pressed(ord("R")) && keyboard_check(vk_control) && keyboard_check(vk_shift)) {
    progress_reset_all();
    if (instance_exists(oUIManager)) {
        ui_toast_add("Progress reset", 90);
    }
}

// ----------------------------------------------- //

if (global.current_portal != global.previous_portal) {
    handle_portal_audio(global.current_portal);
    global.previous_portal = global.current_portal;
}

if (!global.turn_active) {
    global.turn_timer++;
    if (global.turn_timer >= global.turn_delay) {
        global.turn_active = true;
        global.turn_timer  = 0;
    }
}

// === AUTOSAVE THROTTLE ===
global.__save_cooldown++;
if (global.__save_cooldown >= global.__save_interval_steps) {
    global.__save_cooldown = 0;
    if (global.__save_dirty) {
        var now_dt = date_current_datetime();
        global.save.last_save_dt    = now_dt;
        global.save.last_active_dt  = now_dt;
        global.save.portal_id       = global.current_portal;
        global.save.revision       += 1;

        global.save.progress = global.progress;

        var json = json_stringify(global.save);
        var f = file_text_open_write("save.json");
        file_text_write_string(f, json);
        file_text_close(f);

        global.__save_dirty = false;
    }
}

// EXP (merge progress into save when debounce elapses; do NOT write file here)
if (is_struct(global.progress)) {
    var p = global.progress;

    if (!variable_struct_exists(p, "autosave_cooldown"))     p.autosave_cooldown = 0;
    if (!variable_struct_exists(p, "autosave_cooldown_max")) p.autosave_cooldown_max = 15;

    if (p.autosave_cooldown > 0) {
        p.autosave_cooldown -= 1;

        // When the cooldown hits 0, mark main save dirty and copy progress in
        if (p.autosave_cooldown <= 0) {
            // Keep the embedded copy up to date, then let the main autosave write it
            if (!variable_struct_exists(global.save, "progress")) {
                variable_struct_set(global.save, "progress", p);
            } else {
                global.save.progress = p;
            }
            global.__save_dirty = true;
        }
    }
}

/// DAY & NIGHT

// Delta time in seconds (delta_time is microseconds) — safe clamp
var dt = clamp(delta_time / 1000000.0, 0.000001, 0.1);

if (daynight_enabled) {
    __phase = frac(__phase + (dt / __cycle_len_s));
    var tod     = __phase_to_tod(__phase);
    var night_k = 1.0 - tod;           // 0=day ... 1=night

    // --- Strong hysteresis to avoid flapping/duplicates during transitions ---
    var CREATE_AT  = 0.8;             // clearly night
    var DESTROY_AT = 0.2;             // clearly day

    // >>> NEW: expose stable, hysteresis-based global flags <<<
    if (!variable_global_exists("is_night")) global.is_night = false;
    if (!variable_global_exists("time_of_day")) global.time_of_day = tod;

    // Update is_night using same hysteresis as your FX logic
    if (global.is_night) {
        if (night_k <= DESTROY_AT) global.is_night = false;
    } else {
        if (night_k >= CREATE_AT)   global.is_night = true;
    }
    // Keep a scalar around for smooth shading/other systems
    global.time_of_day = tod;
	
	// --- Keep WeatherDirector in sync every frame ---
	var wd = object_exists(oWeatherDirector) ? instance_find(oWeatherDirector, 0) : noone;
	if (instance_exists(wd)) {
	    wd.set_time_of_day(global.time_of_day);
	}

    // <<< END NEW >>>

    // Create only when (a) night is on, (b) player exists, (c) no current flame
	if (night_k >= CREATE_AT && !instance_exists(global.fx_follow_flame) && instance_exists(oPlayer)) {
	    // Resolve or create an FX layer id (no renaming at runtime)
	    if (layer_exists(global.fx_follow_layer)) {
	        global.fx_follow_layer_id = layer_get_id(global.fx_follow_layer);
	    } else if (global.fx_follow_layer_id == -1 || !layer_exists(global.fx_follow_layer_id)) {
	        global.fx_follow_layer_id = layer_create(-100000); // very front
	    }

	    var ply = instance_find(oPlayer, 0);
	    var px = ply.x, py = ply.y;
	    global.fx_follow_flame = instance_create_layer(px, py, global.fx_follow_layer_id, oFollowerFlame);
	}


    // Destroy when day is clearly on
    else if (night_k <= DESTROY_AT && instance_exists(global.fx_follow_flame)) {
        with (global.fx_follow_flame) instance_destroy();
        global.fx_follow_flame = noone;
    }

    // Throttle pushes to avoid spamming tiny updates
    if (abs(tod - __prev_tod) > __push_epsilon) {
        game_set_time_of_day(tod);
    }
}

