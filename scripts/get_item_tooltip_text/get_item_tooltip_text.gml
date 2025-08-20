/// @func get_item_tooltip_text(item_id)
/// @desc Builds a rich tooltip from global.item_data + delta vs equipped.
/// @param {string} item_id
function get_item_tooltip_text(item_id) {
    var id_str = string(item_id);
    if (!variable_struct_exists(global.item_data, id_str)) return "";

    var it = variable_struct_get(global.item_data, id_str);
    if (!is_struct(it)) return "";

    var text = string(it.name);

    // ==== SAFE CATEGORY / SLOT SUBTITLE ====
    var cat_txt  = "";
    var slot_key = "";

    if (variable_struct_exists(it, "category")) {
        var _c = variable_struct_get(it, "category");
        if (!is_undefined(_c)) cat_txt = string(_c);
    }
    if (variable_struct_exists(it, "slot")) {
        var _s = variable_struct_get(it, "slot");
        if (!is_undefined(_s)) slot_key = string(_s);
    }

    var is_equippable = (slot_key != "");

    // Resolve a display label for the slot (pretty-print)
    var slot_lbl = string_replace_all(slot_key, "_", " ");

    // Subtitle
    if (is_equippable) {
        if (slot_lbl != "") text += "\n" + string_upper(slot_lbl);
    } else {
        var line = "";
        if (cat_txt != "") line = string_upper(cat_txt);
        if (slot_lbl != "") {
            if (line != "") line += " • ";
            line += string_upper(slot_lbl);
        }
        if (line != "") text += "\n" + line;
    }

    // ==== Equip stats + delta vs equipped (same slot) ====
    if (variable_struct_exists(it, "equip_stats")) {
        var st = variable_struct_get(it, "equip_stats");

		// --- Safely resolve currently-equipped item's stats in this slot ---
		var eq_st = undefined;

		if (slot_key != "" && is_struct(global.save)) {
		    // 1) fetch 'equipment' safely into a local
		    var _equip = undefined;
		    if (variable_struct_exists(global.save, "equipment")) {
		        var _maybe = variable_struct_get(global.save, "equipment");
		        if (is_struct(_maybe)) _equip = _maybe;
		    }

		    // 2) only touch the local once it's known to be a struct
		    if (is_struct(_equip)) {
		        var eq_id = variable_struct_exists(_equip, slot_key)
		            ? variable_struct_get(_equip, slot_key)
		            : "";

		        if (is_string(eq_id) && eq_id != "" && variable_struct_exists(global.item_data, eq_id)) {
		            var eq_it = variable_struct_get(global.item_data, eq_id);
		            if (is_struct(eq_it) && variable_struct_exists(eq_it, "equip_stats")) {
		                eq_st = variable_struct_get(eq_it, "equip_stats");
		            }
		        }
		    }
		}


        // Helpers (inline to keep it light)
        var _signed     = function(v) { return (v > 0 ? "+" : "") + string(v); };
        var _signed_pct = function(v) { return (v > 0 ? "+" : "") + string(round(v * 100)) + "%"; };

        // DAMAGE
        var v = variable_struct_exists(st, "damage") ? st.damage : 0;
        if (v != 0) {
            var cur = (is_struct(eq_st) && variable_struct_exists(eq_st, "damage")) ? eq_st.damage : 0;
            var d = v - cur;
            text += "\n+" + string(v) + " Damage" + (d != 0 ? " (" + _signed(d) + ")" : "");
        }

        // DEFENSE
        v = variable_struct_exists(st, "defense") ? st.defense : 0;
        if (v != 0) {
            var cur2 = (is_struct(eq_st) && variable_struct_exists(eq_st, "defense")) ? eq_st.defense : 0;
            var d2 = v - cur2;
            text += "\n+" + string(v) + " Defense" + (d2 != 0 ? " (" + _signed(d2) + ")" : "");
        }

        // MAX HP
        v = variable_struct_exists(st, "hp") ? st.hp : 0;
        if (v != 0) {
            var cur3 = (is_struct(eq_st) && variable_struct_exists(eq_st, "hp")) ? eq_st.hp : 0;
            var d3 = v - cur3;
            text += "\n+" + string(v) + " Max HP" + (d3 != 0 ? " (" + _signed(d3) + ")" : "");
        }

        // HIT CHANCE (0..1)
        v = variable_struct_exists(st, "hit") ? st.hit : 0;
        if (v != 0) {
            var cur4 = (is_struct(eq_st) && variable_struct_exists(eq_st, "hit")) ? eq_st.hit : 0;
            var d4 = v - cur4;
            text += "\n+" + string(round(v * 100)) + "% Hit Chance" + (d4 != 0 ? " (" + _signed_pct(d4) + ")" : "");
        }

        // CRIT CHANCE (0..1)
        v = variable_struct_exists(st, "crit") ? st.crit : 0;
        if (v != 0) {
            var cur5 = (is_struct(eq_st) && variable_struct_exists(eq_st, "crit")) ? eq_st.crit : 0;
            var d5 = v - cur5;
            text += "\n+" + string(round(v * 100)) + "% Crit Chance" + (d5 != 0 ? " (" + _signed_pct(d5) + ")" : "");
        }

        // CRIT DAMAGE MULTIPLIER (e.g., 1.5 => +50%)
        v = variable_struct_exists(st, "crit_dmg") ? st.crit_dmg : 0;
        if (v != 0) {
            var cur6 = (is_struct(eq_st) && variable_struct_exists(eq_st, "crit_dmg")) ? eq_st.crit_dmg : 0;
            var d6 = v - cur6;
            text += "\n+" + string(round(v * 100)) + "% Crit Damage" + (d6 != 0 ? " (" + _signed_pct(d6) + ")" : "");
        }
    }

    if (variable_struct_exists(it, "desc")) {
        var _desc = variable_struct_get(it, "desc");
        if (!is_undefined(_desc) && _desc != "") text += "\n" + string(_desc);
    }

    return text;
}
