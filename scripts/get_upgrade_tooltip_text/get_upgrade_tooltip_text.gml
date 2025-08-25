/// @func get_upgrade_tooltip_text(_key)
/// @desc Tooltip for an upgrade: Name, Cost (with coin icons), CURRENT effect. No Level shown.
function get_upgrade_tooltip_text(_key) {
    if (!variable_global_exists("upgrade_defs") || !is_struct(global.upgrade_defs)) return "";
    if (!variable_global_exists("upgrades")     || !is_struct(global.upgrades))     return "";

    var key = string(_key);
    if (!variable_struct_exists(global.upgrade_defs, key)) return "";

    var def = variable_struct_get(global.upgrade_defs, key);
    if (!is_struct(def)) return "";

    var st  = variable_struct_get(global.upgrades, key);
    if (!is_struct(st)) st = {};

    // Safe reads with defaults
    var name    = variable_struct_exists(def, "name")       ? string(variable_struct_get(def, "name"))       : key;
    var s       = variable_struct_exists(def, "stat")       ? string(variable_struct_get(def, "stat"))       : "";
    var per     = variable_struct_exists(def, "per_level")  ? variable_struct_get(def, "per_level")          : 0;
    var mode    = variable_struct_exists(def, "mode")       ? string(variable_struct_get(def, "mode"))       : "add";
    var max_lvl = variable_struct_exists(def, "max_level")  ? variable_struct_get(def, "max_level")          : 0;
    var lvl     = (variable_struct_exists(st, "level") && is_real(st.level)) ? st.level : 0;

    // Cost (for current level → cost to buy NEXT level)
    var base = variable_struct_exists(def, "base_cost") ? variable_struct_get(def, "base_cost") : 0;
    var mul  = variable_struct_exists(def, "cost_mul")  ? variable_struct_get(def, "cost_mul")  : 1;
    var cost = base;
    var i = 0; while (i < lvl) { cost *= mul; i += 1; }
    cost = ceil(cost);

    // Current effect only
    var effect_line = "";
    if (s == "damage" && mode == "mul") {
        var now_pct = floor(per * lvl * 100);
        effect_line = "Effect: +" + string(now_pct) + "% dmg";
    } else if (s == "hit" || s == "crit" || s == "crit_dmg") {
        var now_pct2 = floor(per * lvl * 100);
        var lbl = (s == "crit_dmg") ? "crit dmg" : s;
        effect_line  = "Effect: +" + string(now_pct2) + "% " + lbl;
    } else {
        var eff_now = per * lvl;
        var lbl2 = (s == "defense") ? "def" : (s == "hp" ? "HP" : (s == "hp_regen_per_min" ? "HP/min" : s));
        if (lbl2 == "") lbl2 = "bonus";
        effect_line = "Effect: +" + string(eff_now) + " " + lbl2;
    }

    // Build cost line with icon tokens; hide when maxed
    var cost_line = "";
    if (max_lvl > 0 && lvl >= max_lvl) {
        cost_line = "Cost: MAX";
    } else {
        var bsg = currency_bronze_to_bsg(cost);
        var parts = "";
        if (bsg.gold   > 0) parts += (parts == "" ? "" : " ") + string(bsg.gold)   + " [G]";
        if (bsg.silver > 0) parts += (parts == "" ? "" : " ") + string(bsg.silver) + " [S]";
        if (bsg.bronze > 0 || parts == "") parts += (parts == "" ? "" : " ") + string(bsg.bronze) + " [C]";
        cost_line = "Cost: " + parts;
    }

    // Final text (no Level line)
    var lines = name + "\n" +
                cost_line + "\n" +
                effect_line;

    // Optional description
    if (variable_struct_exists(def, "desc")) {
        var d = variable_struct_get(def, "desc");
        if (is_string(d) && d != "") lines += "\n" + d;
    }

    return lines;
}
