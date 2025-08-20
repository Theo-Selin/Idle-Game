/// @function recalc_stats([p])
/// Rebuilds stats from base + global.equipment_slots using equip_stats + hp_regen_per_min.
function recalc_stats() {
    var p = (argument_count > 0) ? argument0 : id;

    // --- Start from base (with safe fallbacks) ---
    var dmg   = is_undefined(p.base_damage)     ? 0   : p.base_damage;
    var def   = is_undefined(p.base_defense)    ? 0   : p.base_defense;
    var hpmax = is_undefined(p.base_max_hp)     ? 100 : p.base_max_hp;

    var hit   = is_undefined(p.base_hit_chance) ? 0.9 : p.base_hit_chance;
    var crit  = is_undefined(p.base_crit_chance)? 0.0 : p.base_crit_chance;
    var cdmg  = is_undefined(p.base_crit_damage)? 1.5 : p.base_crit_damage;

    // Regen: start from base or zero
    var hp_regen_per_min = is_undefined(p.hp_regen_per_min) ? 0 : p.hp_regen_per_min;
    hp_regen_per_min = 0; // derived each time from equipment (base itemless regen can be added if you want)

    // --- Sum equip bonuses from global.equipment_slots ---
    var slots = global.equip_slots;     // e.g. ["weapon","armor","helmet","health", ...]
    var eq    = global.equipment_slots; // set by save system

    for (var i = 0; i < array_length(slots); i++) {
        var sid = slots[i];
        var item_id = variable_struct_get(eq, sid);

        if (is_string(item_id) && item_id != "") {
            if (variable_struct_exists(global.item_data, item_id)) {
                var it = variable_struct_get(global.item_data, item_id);

                // 1) Standard equip_stats block (existing)
                if (is_struct(it) && variable_struct_exists(it, "equip_stats")) {
                    var st = it.equip_stats;
                    if (is_struct(st)) {
                        if (variable_struct_exists(st, "damage"))   dmg   += st.damage;
                        if (variable_struct_exists(st, "defense"))  def   += st.defense;
                        if (variable_struct_exists(st, "hp"))       hpmax += st.hp;

                        if (variable_struct_exists(st, "hit"))      hit   += st.hit;
                        if (variable_struct_exists(st, "crit"))     crit  += st.crit;
                        if (variable_struct_exists(st, "crit_dmg")) cdmg  += st.crit_dmg;

                        // ✅ Allow regen to live inside equip_stats if you ever choose
                        if (variable_struct_exists(st, "hp_regen_per_min")) {
                            hp_regen_per_min += st.hp_regen_per_min;
                        }
                    }
                }

                // 2) Also support a top-level stat on the item (your potion uses this)
                if (is_struct(it) && variable_struct_exists(it, "hp_regen_per_min")) {
                    hp_regen_per_min += variable_struct_get(it, "hp_regen_per_min");
                }
            }
        }
    }

    // --- Clamp/normalize ---
    hit  = clamp(hit,  0.05, 0.99);
    crit = clamp(crit, 0.00, 0.95);
    cdmg = max(1.00, cdmg);
    hpmax = max(1, hpmax);
    hp_regen_per_min = max(0, hp_regen_per_min); // no negative regen unless you want curses

    // --- Apply ---
    p.combat_damage      = dmg;
    p.defense            = def;
    p.max_hp             = hpmax;
    if (p.hp > p.max_hp) p.hp = p.max_hp;

    p.hit_chance         = hit;
    p.crit_chance        = crit;
    p.crit_damage        = cdmg;

    // ✅ Expose derived regen for the Step-based system
    p.hp_regen_per_min   = hp_regen_per_min;

    // --- Legacy aliases (keep old code happy) ---
    p.base_combat_target_damage = p.base_damage;
    p.combat_target_damage      = p.combat_damage;
    p.armor                     = p.defense;
    p.bonus_damage              = max(0, p.combat_damage - p.base_damage);
}
