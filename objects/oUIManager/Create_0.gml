/// oUIManager.Create

// ----------------- BASIC UI STATE -----------------
toggle_button_rect = [0, 0, 0, 0];
auto_btn_rect      = [0, 0, 0, 0];
ui_tabs            = ["character", "inventory", "crafting", "upgrade"];
active_tab         = "inventory";
ui_visible         = false;
__tab_prev_hover   = 0;

tab_x       = 16;
tab_y       = 64;
tab_spacing = 48;

// TOOLTIP
global.tooltip_text        = "";
global.tooltip_x           = 0;
global.tooltip_y           = 0;
global.tooltip_item_id     = undefined;
global.tooltip_sell_bronze = undefined;

// TOAST QUEUE (direct push)
if (!variable_instance_exists(id, "toasts") || !is_array(toasts)) {
    toasts = []; // { text, ttl, age, [spr] }
}

// ----------------- INVENTORY SETTINGS -----------------
item_slot_size    = 48;
item_slot_margin  = 4.6;
item_slots_total  = 48;
global.current_inventory_category = "Gatherables";

// Context menu + drag state
if (!variable_struct_exists(global, "context_menu")) {
    global.context_menu = {
        is_open:false, x:0, y:0, options:[],
        source:{ category:"", index:-1, item_id:"" }
    };
}
if (!variable_struct_exists(global, "inv_drag")) {
    global.inv_drag = {
        active:false, category:"", from_index:-1, item_id:"",
        offset_x:0, offset_y:0
    };
}

// ----------------- CRAFTING -----------------
global.selected_recipe_index  = -1;
global.crafting_progress      = 0;
global.crafting_in_progress   = false;
global.crafting_recipe        = undefined;
global.current_craft_category = "Weapons";

// ----------------- AFK GAINS -----------------
offline_visible    = (variable_global_exists("offline_report_ready") ? global.offline_report_ready : false);
offline_alpha_bg   = 0;    // 0..0.65
offline_alpha_card = 0;    // 0..1
offline_closing    = false;


// --- LEVEL-UP ICONS (skill -> sprite) ---
// ⚠️ Use exact, existing asset names. Comment out anything you don't have yet.
if (!variable_global_exists("levelup_icon_map") || !is_struct(global.levelup_icon_map)) {
    global.levelup_icon_map = {
        woodcutting: { "default": "spr_skill_woodcutting" }, // <- make sure this sprite exists
        combat     : { "default": "spr_skill_combat" }        // <- make sure this sprite exists
        // mining   : { "default": "spr_skill_mining" },
        // fishing  : { "default": "spr_skill_fishing" },
    };
}

// Cache “already warned” skills so we don’t spam logs
if (!variable_global_exists("__levelup_icon_warned")) {
    global.__levelup_icon_warned = ds_map_create();
}

// Safe sprite getter (name or index)
function __spr_get(_any) {
    if (is_string(_any)) {
        var i = sprite_get_index(_any);
        return (i != -1 && sprite_exists(i)) ? i : -1;
    }
    if (is_real(_any)) return sprite_exists(_any) ? _any : -1;
    return -1;
}

// Single source of truth: resolve icon for a skill/level
global.levelup_icon_for_skill = function(_skill, _level) {
    var k = string_lower(string(_skill));
    if (!variable_global_exists("levelup_icon_map")) return -1;

    var m = global.levelup_icon_map;
    if (!is_struct(m) || !variable_struct_exists(m, k)) {
        // log once per unknown key
        if (!ds_map_exists(global.__levelup_icon_warned, k)) {
            show_debug_message("[toast-icon] no mapping for skill '" + k + "'");
            ds_map_add(global.__levelup_icon_warned, k, true);
        }
        return -1;
    }

    var def = variable_struct_get(m, k);
    if (!is_struct(def)) return -1;

    // default sprite
    var spr_idx = -1;
    if (variable_struct_exists(def, "default")) {
        spr_idx = __spr_get(variable_struct_get(def, "default"));
    }

    // optional tiers (highest min <= level wins)
    if (variable_struct_exists(def, "tiers")) {
        var tiers = def.tiers;
        if (is_array(tiers)) {
            for (var i = 0; i < array_length(tiers); i++) {
                var e = tiers[i];
                if (is_struct(e) && variable_struct_exists(e, "min") && variable_struct_exists(e, "spr")) {
                    var min_lvl = e.min;
                    if (is_real(min_lvl) && _level >= min_lvl) {
                        var ts = __spr_get(e.spr);
                        if (ts != -1) spr_idx = ts;
                    }
                }
            }
        }
    }

    // If still missing, log once and (optionally) fallback
    if (spr_idx == -1) {
        if (!ds_map_exists(global.__levelup_icon_warned, k)) {
            show_debug_message("[toast-icon] mapping for '" + k + "' has no valid sprite");
            ds_map_add(global.__levelup_icon_warned, k, true);
        }
        // Optional fallback so you still see a picture:
        var fallback = sprite_get_index("spr_coin_gold");
        return (fallback != -1 ? fallback : -1);
    }

    return spr_idx;
};



