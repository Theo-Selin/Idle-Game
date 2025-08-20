global.player = id;

// MOVEMENT
path = path_add();
walk_speed = 2;
run_speed  = 3.5;
move_speed = walk_speed;
path_move  = -1;
target     = noone;
last_x     = x;
last_y     = y;
state      = "idle";

// Equip slot list used by recalc
global.equip_slots = ["weapon","armor","helmet","ring_1","ring_2","amulet","health"];

// === BASE STATS ===
base_damage      = 3;
base_defense     = 0;
base_max_hp      = 20;

base_hit_chance  = 0.90;  // 90% hit
base_crit_chance = 0.08;  // 10% crit
base_crit_damage = 1.50;  // crits deal 150%

// Passive regen (minute pulse with cooldown/armed behavior)
hp_regen_per_min       = 0;
regen_interval_ms      = 60000; // 60s
regen_cd_remaining_ms  = regen_interval_ms; // start with a fresh minute
regen_ready_armed      = false; // becomes true if cooldown ends while at full HP

// Derived (recalced on equip change)
combat_damage = base_damage;
defense       = base_defense;
max_hp        = base_max_hp;
hp            = max_hp;

hit_chance    = base_hit_chance;
crit_chance   = base_crit_chance;
crit_damage   = base_crit_damage;

// Equipment slots (instance-local mirror; source of truth is global.equipment_slots)
weapon_data = undefined;
armor_data  = undefined;
helmet_data = undefined;
ring_1_data = undefined;
ring_2_data = undefined;
amulet_data = undefined;
health_data = undefined;

equipped      = { weapon:"", armor:"", helmet:"", ring_1:"", ring_2:"", amulet:"", health:"" };
__last_eq_sig = ""; // used in Step to detect equip changes

// COMBAT/GATHER ANIM KEYS USED IN STEP
combat_anim = "combat";
gather_anim = "chop";

// STATE / FX
is_dying = false;
is_hit   = false;
hit_flash_duration = 6;
hit_timer = 0;
hit_anim_timer = 0;
hit_anim_duration = 20;
is_anim_playing = false;

hit_sound   = snd_hit_default;
death_sound = snd_slime_death;

combat_hit_frame        = 15;
combat_attack_duration  = 30;
combat_phase            = "idle";
combat_timer            = 0;
combat_cooldown         = 30;
combat_dest_x = x;
combat_dest_y = y;
wait_timer   = 0;

is_dead       = false;
death_started = false;
death_timer   = 0;

// AUTO COMBAT
auto_scan_cooldown = 0;
auto_scan_interval = 12;

// GATHERING
gather_type = "chop";
gather_dest_x = x;
gather_dest_y = y;
gather_timer = 0;
gather_phase = "idle";
gather_cooldown = 30;
gather_chop_duration = 30;
gather_speed = 1.0;

// INTERACTING
action_type = "";
interact_dest_x = x;
interact_dest_y = y;
teleport_started = false;

// ANIMATIONS
anim_state = "idle";
anim_dir   = "down";
move_anim_mode = "walk";

// If we came from a portal, carry over the facing into this room
if (variable_global_exists("portal_spawn_facing")) {
    var __dir = global.portal_spawn_facing;
    if (__dir == "up" || __dir == "down" || __dir == "left" || __dir == "right") {
        anim_dir = __dir;
    }
    global.portal_spawn_facing = undefined; // consume it so fresh spawns use default
}

// Player base sprites
base_sprites = {
    idle: { up:spr_player_idle_up, down:spr_player_idle_down, left:spr_player_idle_left, right:spr_player_idle_right },
    walk: { up:spr_player_walk_up, down:spr_player_walk_down, left:spr_player_walk_left, right:spr_player_walk_right },
    run:  { up:spr_player_run_up,  down:spr_player_run_down,  left:spr_player_run_left,  right:spr_player_run_right  },
    chop:      { right:spr_player_chop_right,      left:spr_player_chop_left },
    chop_idle: { right:spr_player_chop_idle_right, left:spr_player_chop_idle_left },
    combat:      { right:spr_player_combat_right,      left:spr_player_combat_left },
    combat_idle: { right:spr_player_combat_idle_right, left:spr_player_combat_idle_left },
    get_hit: { left:spr_player_hit_left, right:spr_player_hit_right },
    death:   { left:spr_player_death_left, right:spr_player_death_right }
};

// Initial sprite
{
    var spr0 = get_anim_sprite(base_sprites, anim_state, anim_dir);
    if (spr0 != -1) { sprite_index = spr0; image_index = 0; }
}

// Damage intake (DEFENSE-based)
take_damage = function (amount, source, is_crit) {
    if (is_dying || is_hit) return;

    var final = max(0, amount);   // already defense-adjusted by combat_resolve_attack
    hp -= final;

    is_hit = true;
    hit_timer = hit_flash_duration;
    hit_anim_timer = hit_anim_duration;

    damage_popup_show(id, final, is_crit ? "crit" : "hit");

    anim_dir = (source.x < x) ? "left" : "right";

    //if (!is_undefined(hit_sound)) {
    //    play_impact_sound(hit_sound);
    //}

    start_shake(8, 2, 0, 30);

    if (hp <= 0 && !is_dead) {
        is_dead = true;
        if (!is_undefined(death_sound)) play_impact_sound(death_sound);
    }
};


/// Helper: switch movement mode
function set_movement_mode(_mode) {
    if (_mode == "run") { move_speed = run_speed;  move_anim_mode = "run"; }
    else                { move_speed = walk_speed; move_anim_mode = "walk"; }
}
