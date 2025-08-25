function recalc_stats() {
    var p = (argument_count > 0) ? argument0 : id;

    // --- Start from base (with safe fallbacks) ---
    var dmg   = is_undefined(p.base_damage)      ? 0   : p.base_damage;
    var def   = is_undefined(p.base_defense)     ? 0   : p.base_defense;
    var hpmax = is_undefined(p.base_max_hp)      ? 100 : p.base_max_hp;

    var hit   = is_undefined(p.base_hit_chance)  ? 0.9 : p.base_hit_chance;
    var crit  = is_undefined(p.base_crit_chance) ? 0.0 : p.base_crit_chance;
    var cdmg  = is_undefined(p.base_crit_damage) ? 1.5 : p.base_crit_damage;

    // Regen derives every time
    var hp_regen_per_min = 0;

    // --- Sum equip bonuses from global.equipment_slots ---
    var slots = global.equip_slots;
    var eq    = global.equipment_slots;

    for (var i = 0; i < array_length(slots); i++) {
        var sid = slots[i];
        var item_id = variable_struct_get(eq, sid);

        if (is_string(item_id) && item_id != "") {
            if (variable_struct_exists(global.item_data, item_id)) {
                var it = variable_struct_get(global.item_data, item_id);

                if (is_struct(it) && variable_struct_exists(it, "equip_stats")) {
                    var st = it.equip_stats;
                    if (is_struct(st)) {
                        if (variable_struct_exists(st, "damage"))   dmg   += st.damage;
                        if (variable_struct_exists(st, "defense"))  def   += st.defense;
                        if (variable_struct_exists(st, "hp"))       hpmax += st.hp;

                        if (variable_struct_exists(st, "hit"))      hit   += st.hit;
                        if (variable_struct_exists(st, "crit"))     crit  += st.crit;
                        if (variable_struct_exists(st, "crit_dmg")) cdmg  += st.crit_dmg;

                        if (variable_struct_exists(st, "hp_regen_per_min")) {
                            hp_regen_per_min += st.hp_regen_per_min;
                        }
                    }
                }

                if (is_struct(it) && variable_struct_exists(it, "hp_regen_per_min")) {
                    hp_regen_per_min += variable_struct_get(it, "hp_regen_per_min");
                }
            }
        }
    }

    // --- Apply upgrade bonuses (stack AFTER equipment) ---
    var damage_mul = 1;

    if (variable_global_exists("upgrade_defs") && variable_global_exists("upgrades")) {
        var ukeys = variable_struct_get_names(global.upgrade_defs);
        for (var ui = 0; ui < array_length(ukeys); ui++) {
            var key  = ukeys[ui];
            var defu = variable_struct_get(global.upgrade_defs, key);
            var stu  = variable_struct_get(global.upgrades, key);

            if (!is_struct(defu) || !is_struct(stu)) continue;
            if (!variable_struct_exists(defu, "stat")) continue;

            var lvl = (variable_struct_exists(stu, "level") && is_real(stu.level)) ? stu.level : 0;
            if (lvl <= 0) continue;

            var per  = (variable_struct_exists(defu, "per_level") && is_real(defu.per_level)) ? defu.per_level : 0;
            if (per == 0) continue;

            var s    = string(defu.stat);
            var mode = variable_struct_exists(defu, "mode") ? string(defu.mode) : "add";

            if (s == "damage" && mode == "mul") {
                var f = 1 + (per * lvl);
                if (f < 0) f = 0;
                damage_mul *= f;
            } else {
                var add = per * lvl;
                if (s == "damage")             dmg   += add;
                else if (s == "defense")       def   += add;
                else if (s == "hp")            hpmax += add;
                else if (s == "hit")           hit   += add;
                else if (s == "crit")          crit  += add;
                else if (s == "crit_dmg")      cdmg  += add;
                else if (s == "hp_regen_per_min") hp_regen_per_min += add;
            }
        }
    }

    // Multipliers apply after additive sums
    dmg *= damage_mul;

    // --- Clamp/normalize ---
    hit  = clamp(hit,  0.05, 0.99);
    crit = clamp(crit, 0.00, 0.95);
    cdmg = max(1.00, cdmg);
    hpmax = max(1, hpmax);
    hp_regen_per_min = max(0, hp_regen_per_min);

    // --- Apply (damage as whole number; HP preserves ratio / fills on first init) ---
    var dmg_int = floor(dmg + 0.000001); // small epsilon to dodge float artifacts

    // Cache old HP/max before overwriting
    var had_hp   = variable_instance_exists(p, "hp") && is_real(p.hp);
    var old_hp   = had_hp ? p.hp : hpmax; // if no hp yet, treat as full
    var prev_max = (variable_instance_exists(p, "max_hp") && is_real(p.max_hp)) ? p.max_hp : hpmax;

    p.combat_damage_raw = dmg; // optional raw
    p.combat_damage      = dmg_int;
    p.defense            = def;

    // Set new max first
    p.max_hp             = hpmax;

    // Initialize or preserve ratio across max changes
    if (!had_hp) {
        p.hp = p.max_hp; // first time → full
    } else {
        var ratio = (prev_max > 0) ? clamp(old_hp / prev_max, 0, 1) : 1;
        p.hp = clamp(round(ratio * p.max_hp), 0, p.max_hp);
    }

    p.hit_chance         = hit;
    p.crit_chance        = crit;
    p.crit_damage        = cdmg;

    p.hp_regen_per_min   = hp_regen_per_min;

    // Legacy aliases
    p.base_combat_target_damage = p.base_damage;
    p.combat_target_damage      = p.combat_damage;
    p.armor                     = p.defense;
    p.bonus_damage              = max(0, p.combat_damage - p.base_damage);
}
