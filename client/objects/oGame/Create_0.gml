/// oGame.Create (very top)
if (instance_number(oGame) > 1) { instance_destroy(); exit; }
persistent = true;

// AUTO COMBAT
if (!variable_global_exists("auto_combat_enabled")) global.auto_combat_enabled = false;

/** @type {Id.MpGrid | Undefined} */ global.path_grid     = undefined;
/** @type {Ds.Grid   | Undefined} */ global.walkable_grid = undefined;

if (!variable_global_exists("___init_done")) {
    global.___init_done = true;

    // INVENTORY UI (room-local visual slots; keep separate from save)
    global.ui_mouse_block      = false;
    global.inventory_max_slots = 60;
    global.inventory           = array_create(global.inventory_max_slots, undefined);

    // EQUIPMENT (runtime alias; will be pointed at save.equipment after load)
    global.equipment_slots = { weapon: undefined, armor: undefined, helmet: undefined, ring_1: undefined, ring_2: undefined, amulet: undefined, health: undefined };


	// ITEMS
	global.item_data = {
	    oak_log: {
	        name: "Oak Log",
	        icon: spr_oak_log,
	        category: "Gatherables",
	        desc: "A sturdy log from an oak tree.",
			sell_price: 1
	    },
		
		mushroom: {
	        name: "Mushroom",
	        icon: spr_mushroom,
	        category: "Gatherables",
	        desc: "A mushroom for extra energy.",
			sell_price: 1
	    },

	    cloth: {
	        name: "Cloth",
	        icon: spr_cloth,
	        category: "Materials",
	        desc: "Simple fabric. Useful for basic armor.",
			sell_price: 3,
	        // If/when you use registry-based drops, you can declare item-side drops here:
	        drops: [ { enemy: "oSlime", chance: 0.01, min: 1, max: 1 } ]
	    },
	    coin_copper: {
	        name: "Coin",
	        icon: spr_coin_copper,
	        category: "Currency",
	    },

	    // === Equipment: Stick (weapon) ===
	    stick: {
	        name: "Stick",
	        icon: spr_stick,
	        category: "Equipment",
			desc: "A trusty stick.",
			sell_price: 10,
	        slot: "weapon",

	        // ✅ New system: equipment stat bonuses (all optional; defaults = 0)
	        //hit: 0.05, +5% hit chance
	        //crit: 0.10, +10% crit chance
	        //crit_dmg: 0.50   +50% crit damage
			
	        equip_stats: {
	            damage: 1,
	            defense: 0,
	            hp: 0,
	            hit: 0.05,
	            crit: 0,
	            crit_dmg: 0 
	        },

	        // (Legacy for anything still reading old fields—safe to remove when migrated)
	        stats: { combat_target_damage: 1 },

	        anim_sprites: {
	            combat:      { right: spr_stick_combat_right,      left: spr_stick_combat_left },
	            combat_idle: { right: spr_stick_combat_idle_right, left: spr_stick_combat_idle_left }
	        },
	    },

	    // === Equipment ===
		hp_potion: {
			name: "Health Potion",
	        icon: spr_hp_potion,
	        category: "Equipment",
	        slot: "health",
			sell_price: 20,
			desc: "Potion for good health.",
			
			equip_stats: {
	            damage: 0,
	            defense: 0,
	            hp: 0,
	            hit: 0.00,
	            crit: 0.00,
	            crit_dmg: 0.00,
				hp_regen_per_min: 10,
	        },
		},
			
	    cloth_armor: {
	        name: "Cloth Armor",
	        icon: spr_cloth_armor,
	        category: "Equipment",
	        slot: "armor",
			sell_price: 20,
			desc: "Simple armor.",

	        // ✅ New system stats (defense = 1)
	        equip_stats: {
	            damage: 0,
	            defense: 1,
	            hp: 0,
	            hit: 0.00,
	            crit: 0.00,
	            crit_dmg: 0.00
	        },

	        // (Legacy mirror)
	        stats: { armor: 1 },

	        // You already have a full animation set here — keeping as-is
	        anim_sprites: {
	            idle: {
	                up: spr_cloth_idle_up, down: spr_cloth_idle_down,
	                left: spr_cloth_idle_left, right: spr_cloth_idle_right
	            },
	            walk: {
	                up: spr_cloth_walk_up, down: spr_cloth_walk_down,
	                left: spr_cloth_walk_left, right: spr_cloth_walk_right
	            },
	            run: {
	                up: spr_cloth_run_up, down: spr_cloth_run_down,
	                left: spr_cloth_run_left, right: spr_cloth_run_right
	            },
	            chop:      { right: spr_cloth_chop_right, left: spr_cloth_chop_left },
	            chop_idle: { right: spr_cloth_chop_idle_right, left: spr_cloth_chop_idle_left },
	            combat:      { right: spr_cloth_combat_right,      left: spr_cloth_combat_left },
	            combat_idle: { right: spr_cloth_combat_idle_right, left: spr_cloth_combat_idle_left }
	            // get_hit/death can be added later if/when needed
	        },
	    }
	};
	
	// -------------------- UPGRADES: registry (static) --------------------
	if (!variable_global_exists("upgrade_defs") || !is_struct(global.upgrade_defs)) {
	    global.upgrade_defs = {};
	}

	// Damage upgrade: +10% per level (multiplicative on final damage)
	variable_struct_set(global.upgrade_defs, "damage", {
	    name: "Damage",
	    stat: "damage",
	    mode: "mul",     // handled in recalc_stats
	    per_level: 0.10, // +10% per level
	    base_cost: 1,
	    cost_mul : 1.5,
	    max_level: 99,
	    icon: noone
	});
		variable_struct_set(global.upgrade_defs, "hp", {
	    name: "HP",
	    stat: "hp",
	    per_level: 10, // +10% per level
	    base_cost: 1,
	    cost_mul : 1.5,
	    max_level: 99,
	    icon: noone
	});


	// === STATS LABELS (for any UI that reads labels) ===
	// Keep legacy keys AND add the new equip_stats keys.
	// You can switch your UI to these names over time.
	global.stat_labels = {
	    // Legacy
	    combat_target_damage: "Attack Damage",
	    armor: "Armor",

	    // New system
	    damage:   "Damage",
	    defense:  "Defense",
	    hp:       "Max HP",
	    hit:      "Hit Chance",
	    crit:     "Crit Chance",
	    crit_dmg: "Crit Damage",
		hp_regen_per_min: "HP/min"
	};


    // CRAFTING
    global.crafting_recipes = [
        { id: "stick", name: "Oak Stick",
          input:  [ { id: "oak_log", amount: 1 }, { id: "coin_copper", amount: 1 } ],
          output: { id: "stick", amount: 1 }, icon_name: "spr_stick", category: "Weapons" },
		  
		{ id: "cloth_armor", name: "Cloth Armor",
          input:  [ { id: "cloth", amount: 1 }, { id: "coin_copper", amount: 1 } ],
          output: { id: "cloth_armor", amount: 1 }, icon_name: "spr_cloth_armor", category: "Armors" },
		  
		{ id: "hp_potion",
          input:  [ { id: "mushroom", amount: 35 } ],
          output: { id: "hp_potion", amount: 1 }, icon_name: "spr_hp_potion", category: "Processing" }
    ];

    // PORTALS meta
    global.portal_data = [];
    global.portal_data[PORTAL_HOME_INSIDE]  = { room: ROOM_HOME_INSIDE,  music: snd_music_forest, ambience: snd_ambience_birds };
    global.portal_data[PORTAL_HOME_OUTSIDE] = { room: ROOM_HOME_OUTSIDE, music: snd_music_forest, ambience: snd_ambience_birds };

    if (!variable_global_exists("current_portal"))  global.current_portal  = PORTAL_HOME_OUTSIDE;
    if (!variable_global_exists("previous_portal")) global.previous_portal = -1;

    // TURN SYSTEM
    global.turn_owner  = "player";
    global.turn_timer  = 0;
    global.turn_delay  = 60;
    global.turn_active = false;

    // -------------------- SAVE DATA (defaults FIRST) --------------------
    global.save = {
        version: 1,
        profile_id: "",
        revision: 0,
        last_save_dt: 0,
        last_active_dt: 0,
        inventory: {},
        equipment: global.equipment_slots,
        stats: { xp: 0, level: 1 },
        portal_id: global.current_portal,
		inventory_order: {},
		upgrades: {},

        activity: {
            type: "idle",
            portal_id: global.current_portal,
            // gather:
            resource_id: "",
            per_sec: 0,
            // combat:
            enemy_kind: "",
            kills_per_sec: 0,
            loot_per_kill: {}
        }
    };

    // Autosave flags/timers
    global.__save_dirty          = true;  // force first save
    global.__save_cooldown       = 0;
    global.__save_interval_steps = game_get_speed(gamespeed_fps) * 15; // ~15s

    // --------------------------- LOAD IF EXISTS -------------------------
    if (file_exists("save.json")) {
        var f   = file_text_open_read("save.json");
        var raw = file_text_read_string(f);
        file_text_close(f);

        var loaded = json_parse(raw);
        // SAFELY read version from loaded struct (no dot access)
        if (is_struct(loaded) && !is_undefined(variable_struct_get(loaded, "version"))) {
            global.save = loaded;

            // Ensure required fields exist (NO dot access here)
            if (!variable_struct_exists(global.save, "inventory"))
                variable_struct_set(global.save, "inventory", {});
            if (!variable_struct_exists(global.save, "stats"))
                variable_struct_set(global.save, "stats", { xp: 0, level: 1 });
            if (!variable_struct_exists(global.save, "equipment"))
                variable_struct_set(global.save, "equipment", global.equipment_slots);
            if (!variable_struct_exists(global.save, "portal_id"))
                variable_struct_set(global.save, "portal_id", global.current_portal);
            if (!variable_struct_exists(global.save, "activity")
            ||  !is_struct(variable_struct_get(global.save, "activity"))) {
                variable_struct_set(global.save, "activity", {
                    type: "idle",
                    portal_id: global.current_portal,
                    resource_id: "",
                    per_sec: 0,
                    enemy_kind: "",
                    kills_per_sec: 0,
                    loot_per_kill: {}
                });
            }
			
			// Ensure upgrades struct exists on the loaded save
			if (!variable_struct_exists(global.save, "upgrades"))
			    variable_struct_set(global.save, "upgrades", {});

			var up = variable_struct_get(global.save, "upgrades");

			// Backfill any missing upgrade keys from the registry (level -> 0)
			if (variable_global_exists("upgrade_defs") && is_struct(global.upgrade_defs)) {
			    var ukeys = variable_struct_get_names(global.upgrade_defs);
			    for (var ui = 0; ui < array_length(ukeys); ui++) {
			        var k = ukeys[ui];
			        if (is_undefined(variable_struct_get(up, k))) {
			            variable_struct_set(up, k, { level: 0 });
			            global.__save_dirty = true; // we added fields; autosave soon
			        }
			    }
			}


            // Ensure known item keys exist
            var inv = variable_struct_get(global.save, "inventory");
            if (is_undefined(variable_struct_get(inv, "oak_log")))
                variable_struct_set(inv, "oak_log", 0);
            if (is_undefined(variable_struct_get(inv, "coin_copper")))
                variable_struct_set(inv, "coin_copper", 0);
            if (is_undefined(variable_struct_get(inv, "stick")))
                variable_struct_set(inv, "stick", 0);
            if (is_undefined(variable_struct_get(inv, "cloth")))
                variable_struct_set(inv, "cloth", 0);
            if (is_undefined(variable_struct_get(inv, "cloth_armor")))
                variable_struct_set(inv, "cloth_armor", 0);

            // Optional migration from unix fields (safe)
            if (variable_struct_exists(global.save, "last_active_unix")
            ||  variable_struct_exists(global.save, "last_save_unix")) {
                var now_dt_mig = date_current_datetime();
                variable_struct_set(global.save, "last_active_dt", now_dt_mig);
                variable_struct_set(global.save, "last_save_dt",   now_dt_mig);
                if (variable_struct_exists(global.save, "last_active_unix"))
                    variable_struct_remove(global.save, "last_active_unix");
                if (variable_struct_exists(global.save, "last_save_unix"))
                    variable_struct_remove(global.save, "last_save_unix");
                global.__save_dirty = true;
            }
        }
    }

    // Keep runtime alias pointing at persisted equipment
    global.equipment_slots = global.save.equipment;
	// Keep runtime alias pointing at persisted upgrades
	global.upgrades = global.save.upgrades;
	// Schedule a few stat rebuilds to catch player spawn timing
	global.__stats_sync_frames = 3; // small number is enough


    // -------------------- PROGRESS (embed into save) --------------------
    if (variable_struct_exists(global.save, "progress") && is_struct(global.save.progress)) {
        // Migrate to guarantee fields (skills, autosave timers, etc.)
        global.progress = progress_migrate(global.save.progress);
    } else {
        global.progress = progress_defaults();
        // Store in save so it persists immediately on next autosave
        variable_struct_set(global.save, "progress", global.progress);
        global.__save_dirty = true;
    }

    // Safety for cooldown fields (in case old saves lacked them)
    if (!variable_struct_exists(global.progress, "autosave_cooldown"))     global.progress.autosave_cooldown = 0;
    if (!variable_struct_exists(global.progress, "autosave_cooldown_max")) global.progress.autosave_cooldown_max = 15;

    // ----------------------- OFFLINE CATCH-UP (activity-based) ---------
    var now_dt = date_current_datetime();
    if (is_undefined(global.save.last_active_dt) || global.save.last_active_dt == 0)
        global.save.last_active_dt = now_dt;

    var dt_seconds  = max(0, date_second_span(global.save.last_active_dt, now_dt));
    var max_offline = 60 * 60 * 8; // cap 8h
    var sim_seconds = clamp(dt_seconds, 0, max_offline);

    // Prepare an empty report (UI will show only if lines > 0)
    global.offline_report = {
        seconds: sim_seconds,
        activity_type: "idle",
        lines: [],                 // array of {id, name, amount}
        total_items: 0,
        kills: 0
    };

    if (sim_seconds > 0) {
        var act = variable_struct_get(global.save, "activity");
        if (!is_struct(act)) {
            act = {
                type: "idle",
                portal_id: global.current_portal,
                resource_id: "",
                per_sec: 0,
                enemy_kind: "",
                kills_per_sec: 0,
                loot_per_kill: {}
            };
            variable_struct_set(global.save, "activity", act);
        }

        switch (act.type) {
            case "gather": {
                var per_sec = is_undefined(act.per_sec) ? 0 : act.per_sec;
                var res_id  = is_undefined(act.resource_id) ? "" : string(act.resource_id);
                if (per_sec > 0 && res_id != "" && !is_undefined(variable_struct_get(global.item_data, res_id))) {
                    var gained = floor(sim_seconds * per_sec);
                    if (gained > 0) {
                        collect_loot(res_id, gained);
                        var def = variable_struct_get(global.item_data, res_id);
                        array_push(global.offline_report.lines, { id: res_id, name: def.name, amount: gained });
                        global.offline_report.total_items += gained;
                        global.offline_report.activity_type = "gather";
                    }
                }
            } break;

            case "combat": {
                var kps   = is_undefined(act.kills_per_sec) ? 0 : act.kills_per_sec;
                var kills = floor(sim_seconds * kps);
                if (kills > 0 && is_struct(act.loot_per_kill)) {
                    global.offline_report.kills = kills;
                    var loot_names = variable_struct_get_names(act.loot_per_kill);
                    var any_gain = false;
                    for (var i = 0; i < array_length(loot_names); i++) {
                        var item_id = loot_names[i];
                        var expect_per = variable_struct_get(act.loot_per_kill, item_id);
                        var total = floor(kills * max(0, expect_per));
                        if (total > 0 && !is_undefined(variable_struct_get(global.item_data, item_id))) {
                            collect_loot(item_id, total);
                            var def2 = variable_struct_get(global.item_data, item_id);
                            array_push(global.offline_report.lines, { id: item_id, name: def2.name, amount: total });
                            global.offline_report.total_items += total;
                            any_gain = true;
                        }
                    }
                    if (any_gain) global.offline_report.activity_type = "combat";
                }
            } break;

            default: break; // idle → no gains
        }

        global.__save_dirty = true; // will flush soon
    }

    // Mark last active = now; autosave will also set last_save_dt
    global.save.last_active_dt = now_dt;

    // Tell the UI to show the offline popup once (handled by oUIManager)
    global.offline_report_ready = (array_length(global.offline_report.lines) > 0);
}

/// DAY & NIGHT

/// ---- Cycle config ----
daynight_enabled   = true;   // set false if you want manual control
day_secs           = 20;     // how long full “daytime” lasts
night_secs         = 20;     // how long full “nighttime” lasts
dawn_secs          = 10;     // blend at sunrise
dusk_secs          = 10;     // blend at sunset

// Tiny constants (no scientific notation)
EPS_TINY  = 0.000001;
EPS_SMALL = 0.0001;

// Internals
__cycle_len_s      = max(0.001, day_secs + night_secs + dawn_secs + dusk_secs);
__prev_tod         = -1;     // last pushed time-of-day (to throttle updates)
__push_epsilon     = 0.01;   // only push when change > 1%

// Place the phase in the middle of the DAY plateau so we don't jump at t=0
var __a = dawn_secs / __cycle_len_s;     // dawn fraction
var __b = day_secs  / __cycle_len_s;     // day  fraction
__phase = __a + (__b * 0.5);             // center of daytime

/// Helper: cosine ease (0..1 → 0..1)
function __ease_cos01(t) { return 0.5 - 0.5 * dcos(t * 180); } // cheaper than cos(rad)

// Map phase→time-of-day (1=day, 0=night), with soft dawn/dusk
/// Layout: [ dawn | day | dusk | night ]
function __phase_to_tod(_p)
{
    var p = frac(_p);
    var a = dawn_secs   / __cycle_len_s;
    var b = day_secs    / __cycle_len_s;
    var c = dusk_secs   / __cycle_len_s;

    // Dawn: 0→1
    if (p < a) {
        var t = p / max(EPS_SMALL, a);
        return __ease_cos01(t); // smooth rise
    }
    p -= a;
    // Day plateau
    if (p < b) return 1.0;

    p -= b;
    // Dusk: 1→0
    if (p < c) {
        var t2 = p / max(EPS_SMALL, c);
        return 1.0 - __ease_cos01(t2);
    }
    // Night plateau
    return 0.0;
}

/// Public: set time-of-day immediately (0..1)
function game_set_time_of_day(_t)
{
    var tod = clamp(_t, 0, 1);

    // Prefer WeatherDirector API if present (it already propagates to clouds/ambience)
    var wd = noone;
    if (object_exists(oWeatherDirector)) wd = instance_find(oWeatherDirector, 0);
    if (instance_exists(wd) && variable_instance_exists(wd, "set_time_of_day")) {
        wd.set_time_of_day(tod);
    } else {
        // Fallback: call sub-systems directly
        with (oCloudShadows) if (variable_instance_exists(id, "clouds_set_time_of_day")) clouds_set_time_of_day(tod);
        // Ambience: 0=DAY, 1=NIGHT (enum AMBIENCE_MODE { DAY=0, NIGHT=1 })
        with (oAmbienceGlade) if (variable_instance_exists(id, "set_ambience_mode")) set_ambience_mode( tod >= 0.5 ? 0 : 1 );
    }

    __prev_tod = tod;
}

// Initial push now (for first frame appearance) **and** schedule a post-spawn sync
game_set_time_of_day(1.0);   // show day immediately
__sync_frames = 2;           // push again for the next 2 Steps after everything spawns

// Night fairy follower handle (auto-managed by oGame.Step only)
global.fx_follow_flame   = noone;
global.fx_follow_layer   = "FX_Overlays"; // preferred name (if present)
global.fx_follow_layer_id = -1;           // we'll resolve/create an id at runtime

