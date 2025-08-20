// oSlime Create Event
event_inherited(); // 🧠 This calls oEnemy.Create and sets all shared variables

marker_y_offset = -8; // negative = higher above the mask top

// Slime shadow: squishy and bigger
shadow_width     = 18;
shadow_height    = 5;
shadow_offset_y  = -2;
shadow_alpha     = 0.25;

// === STATS ===
hp = 5;
// Enemy combat tuning (per type)
combat_damage = 2;     // you already have this
hit_chance    = 0.90;  // 90% hit
crit_chance   = 0.05;  // 5% crit
crit_damage   = 1.50;  // 150% on crits

combat_anim = "combat";
hit_sound = snd_slime_hit;
death_sound = snd_slime_death;
destroy_sound = snd_slime_splash;
hit_sound_delay = 4; // Delay in steps (frames) before sound plays
combat_distance = 36; // Adjust per enemy (e.g. Slime = 36, Goblin = 48, Boss = 64)

// === LOOT ===
// Backward-compat: keep loot_type for default coin drop
loot_type = "coin_copper";

// Offline/combat tuning (expected items per kill)
offline_kills_per_min = 3;
offline_loot_avg = { coin_copper: 1, cloth: 0.1 }; // add cloth expectation


// 🎓 EXP settings owned by this enemy type
xp_skill = "combat";
xp_reward = 12; // tune per enemy type

// === SLIME ANIMATIONS ===
base_sprites = {
    idle: {
        up: spr_enemy_slime_idle_up,
        down: spr_enemy_slime_idle_down,
        left: spr_enemy_slime_idle_left,
        right: spr_enemy_slime_idle_right
    },
    walk: {
        up: spr_enemy_slime_walk_up,
        down: spr_enemy_slime_walk_down,
        left: spr_enemy_slime_walk_left,
        right: spr_enemy_slime_walk_right
    },
    combat: {
        left: spr_enemy_slime_combat_left,
        right: spr_enemy_slime_combat_right
    },
    combat_idle: {
        left: spr_enemy_slime_combat_idle_left,
        right: spr_enemy_slime_combat_idle_right
    },
    get_hit : {
        left: spr_enemy_slime_hit_left,
        right: spr_enemy_slime_hit_right
    },
    death: {
        left: spr_enemy_slime_death_left,
        right: spr_enemy_slime_death_right
    },
};
