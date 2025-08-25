/// set_activity_combat(enemy_instance)
/// Uses simple per-portal/per-enemy averages for offline: kills/sec and expected loot per kill.
function set_activity_combat(enemy) {
    var enemy_kind = "oSlime";
    if (instance_exists(enemy)) {
        enemy_kind = object_get_name(enemy.object_index);
    }

    // Defaults if the enemy doesn't expose tuning variables
    var kills_per_min = 3; // tune per enemy
    var kps = kills_per_min / 60;

    // Expected loot per kill as a struct (id -> average amount)
    var expect = {};
    // Prefer enemy-provided averages if present (e.g., set on oSlime.Create)
    if (instance_exists(enemy) && variable_instance_exists(enemy, "offline_kills_per_min")) {
        kills_per_min = max(0, enemy.offline_kills_per_min);
        kps = kills_per_min / 60;
    }
    if (instance_exists(enemy) && variable_instance_exists(enemy, "offline_loot_avg") && is_struct(enemy.offline_loot_avg)) {
        expect = enemy.offline_loot_avg; // e.g., { coin_copper: 1, oak_log: 0.1 }
    } else {
        // Safe fallback: 1 copper coin per kill
        variable_struct_set(expect, "coin_copper", 1);
    }

    global.save.activity.type         = "combat";
    global.save.activity.portal_id    = global.current_portal;
    global.save.activity.enemy_kind   = enemy_kind;
    global.save.activity.kills_per_sec = kps;
    global.save.activity.loot_per_kill = expect;

    global.__save_dirty = true;
}
