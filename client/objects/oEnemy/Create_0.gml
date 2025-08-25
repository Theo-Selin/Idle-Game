/// oEnemy Create Event
show_debug_message("✅ oEnemy Create ran for: " + object_get_name(object_index));

// === STATE ===
state = "idle";
combat_started = false;
targetable = true;
selected = false;
ai_enabled = true;
is_locked = false;

// --- Combat lock ownership (prevents stale unlocks/races)
combat_lock_owner = noone;
combat_lock_token = 0; // mirrors player's token when applicable

// --- Spawn fade defaults (set unconditionally to avoid undefined reads)
spawn_fading        = false;  // spawner can flip this to true after Create
spawn_fade_timer    = 0;
spawn_fade_duration = 0;

// === DEATH ===
is_dying = false;
death_timer = 0;
death_fade_speed = 0.05;

// === MOVEMENT ===
move_speed = 1;
path = path_add();
path_target = noone;
path_active = false;
roam_timer = 0;
roam_delay = irandom_range(360, 720);

// === GRID ===
tile_size = global.grid_cell_size;
grid_x = -1;
grid_y = -1;

// === ANIMATION ===
anim_state = "walk";
anim_dir = "down";
last_x = x;
last_y = y;

// === COMBAT ===
// === BASE STATS ===
base_damage      = 3;
base_defense     = 0;
base_max_hp      = 20;

base_hit_chance  = 0.90;  // 90% hit
base_crit_chance = 0.10;  // 10% crit
base_crit_damage = 1.50;  // crits deal 150%

// Live / derived (will be recalculated)
combat_damage = base_damage;
defense       = base_defense;
max_hp        = base_max_hp;
hp            = max_hp;

hit_chance    = base_hit_chance;
crit_chance   = base_crit_chance;
crit_damage   = base_crit_damage;

is_hit = false;
hit_timer = 0;
hit_anim_timer = 0;
hit_flash_duration = 15;
hit_shake_x = 0;
hit_shake_y = 0;

wait_timer = 0;
combat_phase = "idle";
combat_timer = 0;
combat_cooldown = 60;
combat_attack_duration = 30;
combat_hit_frame = 15;
combat_started = false;

// === DEATH STATE ===
is_dead = false;
death_started = false;
death_timer = 0;
death_fade_speed = 0.05;
has_dropped = false;

// 🎓 One-time EXP payout guard (so death EXP can't double-fire)
xp_awarded = false;

/// @func take_damage(amount, attacker, is_crit)
/// @desc Called when the enemy takes damage from an attacker (usually the player)
take_damage = function(amount, attacker = noone, is_crit = false) {
    if (is_dying) return;

    hp -= amount;
    is_hit = true;
    hit_timer = hit_flash_duration;

    play_impact_sound(hit_sound);

    // 🧭 Directional hit animation
    if (instance_exists(attacker)) {
        anim_dir = (attacker.x < x) ? "left" : "right";
        var hit_sprite = get_anim_sprite(base_sprites, combat_anim + "_hit", anim_dir);
        if (hit_sprite != -1) {
            sprite_index = hit_sprite;
            image_index = 0;
            image_speed = 1;
        }
    }

    // 🔢 Damage number (uses the optional flag)
    damage_popup_show(id, amount, is_crit ? "crit" : "hit");

    if (hp <= 0) {
        is_dead = true;

        // 💀 Death sounds
        if (!is_undefined(death_sound)) {
            play_impact_sound(death_sound);
            play_impact_sound(destroy_sound);
        }

// 🎁 Drops: multiple probabilistic + guaranteed coins
if (!has_dropped && instance_exists(oPlayer) && !is_undefined(drop_loot)) {
    has_dropped = true; // ensure once per corpse

    var source_x = oPlayer.x;
    var source_y = oPlayer.y;
    var offset_x = (source_x > x) ? -64 : 64;
    var offset_y = -64;

    // 1) Enemy-defined probabilistic table (multiple can drop)
    if (variable_instance_exists(id, "loot_table") && is_array(loot_table)) {
        var n1 = array_length(loot_table);
        for (var i = 0; i < n1; i++) {
            var e = loot_table[i];
            if (is_struct(e) && variable_struct_exists(e, "type") && variable_struct_exists(e, "chance")) {
                var ch = e.chance;
                if (ch > 0 && random(1) < ch) {
                    var mn = variable_struct_exists(e, "min") ? e.min : 1;
                    var mx = variable_struct_exists(e, "max") ? e.max : mn;
                    var amt = (mn == mx) ? mn : irandom_range(mn, mx);
                    if (amt > 0) {
                        drop_loot(source_x, source_y, e.type, amt, id, offset_x, offset_y);
                    }
                }
            }
        }
    }

    // 2) Item-based probabilistic table (built from global.item_data.*.drops)
    var enemy_name = object_get_name(object_index);
    var idx_table  = variable_struct_get(global.enemy_drops, enemy_name);
    if (!is_undefined(idx_table) && is_array(idx_table)) {
        var n2 = array_length(idx_table);
        for (var k = 0; k < n2; k++) {
            var r = idx_table[k]; // {item, chance, min, max}
            if (r.chance > 0 && random(1) < r.chance) {
                var amt2 = (r.min == r.max) ? r.min : irandom_range(r.min, r.max);
                if (amt2 > 0) {
                    drop_loot(source_x, source_y, r.item, amt2, id, offset_x, offset_y);
                }
            }
        }
    }

    // 3) Guaranteed coins (always drop in addition to the above)
    if (!is_undefined(coin_type)) {
        var cmin = is_real(coin_min) ? coin_min : 1;
        var cmax = is_real(coin_max) ? coin_max : cmin;
        var camt = (cmin == cmax) ? cmin : irandom_range(cmin, cmax);
        if (camt > 0) {
            drop_loot(source_x, source_y, coin_type, camt, id, offset_x, offset_y);
        }
    }
}




        // 🎓 EXP on kill (once)
        if (!xp_awarded) {
            var skill = variable_instance_exists(id, "xp_skill") ? xp_skill : "combat";
            var amt   = variable_instance_exists(id, "xp_reward") ? xp_reward : 5; // fallback
            progress_award_xp(skill, amt);
            xp_popup_show(skill, amt);
            xp_awarded = true;
        }
    }
};
