/// draw_upgrade_ui(x, y, w, h)
/// Top tabs (STATS/EQUIPMENT). Rows show only Name; right side shows "x <level>";
/// tooltip shows Cost + current Effect.
function draw_upgrade_ui(_x, _y, _w, _h)
{
    // ---------- THEME ----------
    var theme = {
        pad: 12, gap: 24, line: 18, row_h: 36,
        col_text: make_color_rgb(220,220,220),
        col_dim : make_color_rgb(160,160,180),
        col_out : make_color_rgb(16,16,20),
        col_btn : make_color_rgb(36,36,44)
    };
    var lbl_scale = 1;
    var sub_scale = 1;

    // ---------- SFX (hover + click only) ----------
    var sfx_hover = snd_ui_hover;
    var sfx_click = snd_upgrade_click;

    // Track last hovered key (for hover SFX once-on-enter)
    if (!variable_instance_exists(id, "__upgrade_prev_hover")) __upgrade_prev_hover = "";
    var hovered_now = "";

    // Per-button alpha tween store (snappy fade)
    if (!variable_instance_exists(id, "__btn_alpha_by_key")) __btn_alpha_by_key = {};

    // ---------- GUARDS ----------
    if (!variable_global_exists("upgrade_defs") || !is_struct(global.upgrade_defs)) return;
    if (!variable_global_exists("upgrades")     || !is_struct(global.upgrades))     return;

    // ---------- STATE ----------
    if (!variable_global_exists("current_upgrade_tab")) global.current_upgrade_tab = "STATS";
    var tabs = ["STATS", "EQUIPMENT"];

    // ---------- HELPERS ----------
    var __cost_at = function(_def, _lvl) {
        var base = variable_struct_exists(_def, "base_cost") ? _def.base_cost : 0;
        var mul  = variable_struct_exists(_def, "cost_mul")  ? _def.cost_mul  : 1;
        var c = base; var i = 0; while (i < _lvl) { c *= mul; i += 1; }
        return ceil(c);
    };

    // ---------- LAYOUT ----------
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(theme.col_text);

    var pad = theme.pad;

    // --- Top tab bar ---
    var section_spacing  = 16;
    var cat_tab_h        = 38;
    var cat_tab_spacing  = 24;

    var total_tab_w = 0;
    var tab_w = [];
    for (var i = 0; i < array_length(tabs); i++) {
        var t = tabs[i];
        tab_w[i] = string_width(t);
        total_tab_w += tab_w[i] + (i < array_length(tabs) - 1 ? cat_tab_spacing : 0);
    }
    var tabs_start_x = _x + (_w - total_tab_w) * 0.5;
    var tab_area_y   = _y;
    var draw_x       = tabs_start_x;

    var mx = mouse_x, my = mouse_y;

    // 🔊 Tab SFX state (hover once-on-enter; click when switching)
    var sfx_hover_tabs = snd_ui_hover;
    var sfx_tab_click  = snd_tab_click;
    if (!variable_instance_exists(id, "__upgrade_tab_prev_hover")) __upgrade_tab_prev_hover = -1;
    var hovered_tab_idx = -1;

    for (var ti = 0; ti < array_length(tabs); ti++) {
        var label      = tabs[ti];
        var is_selected = (string(global.current_upgrade_tab) == label);

        var lh = string_height(label);
        var ly = tab_area_y + (cat_tab_h - lh) * 0.5;

        // Hitbox
        var bx1 = draw_x, by1 = tab_area_y;
        var bx2 = draw_x + tab_w[ti] + 6, by2 = by1 + cat_tab_h;

        var is_hovered = point_in_rectangle(mx, my, bx1, by1, bx2, by2);
        if (is_hovered) { hovered_tab_idx = ti; global.ui_mouse_block = true; }

        // Color: hover → white, active → white, else dim
        draw_set_color((is_selected || is_hovered) ? c_white : make_color_rgb(160,160,160));
        draw_text(draw_x, ly, label);

        // Click to activate (play click sound only if switching)
        if (is_hovered && mouse_check_button_pressed(mb_left)) {
            if (!is_selected) {
                global.current_upgrade_tab = label;
                if (audio_exists(sfx_tab_click)) play_impact_sound(sfx_tab_click, 1, 1.5, 2);
            }
        }

        draw_x += tab_w[ti] + cat_tab_spacing;
    }

    // Play hover SFX once when entering a new (non-active) tab
    if (hovered_tab_idx != -1 && hovered_tab_idx != __upgrade_tab_prev_hover) {
        if (tabs[hovered_tab_idx] != string(global.current_upgrade_tab)) {
            if (audio_exists(sfx_hover_tabs)) play_impact_sound(sfx_hover_tabs, 0.2, 1.5, 1.5);
        }
    }
    __upgrade_tab_prev_hover = hovered_tab_idx;

    // --- below: unchanged list layout / buttons / tooltips ---
    var list_y = _y + cat_tab_h + section_spacing;
    var mid_h  = max(theme.row_h + pad * 2, floor(_h * 0.40));

    var btn_h    = theme.row_h;
    var btn_minw = 140;
    var lvl_gap  = 10;

    var x_cursor = _x + pad;
    var y_cursor = list_y;

    var all_keys  = variable_struct_get_names(global.upgrade_defs);
    var view_keys = [];
    for (var k = 0; k < array_length(all_keys); k++) {
        var key = all_keys[k];
        var def = variable_struct_get(global.upgrade_defs, key);
        if (!is_struct(def)) continue;

        var group = variable_struct_exists(def, "group") ? string(def.group) : "STATS";
        if (group == string(global.current_upgrade_tab)) array_push(view_keys, key);
    }

    if (array_length(view_keys) == 0) {
        draw_set_color(theme.col_dim);
        var msg = "No upgrades here yet.";
        var mw  = string_width(msg);
        draw_text(_x + (_w - mw) * 0.5, y_cursor + 8, msg);
        return;
    }

    // Optional lock icon for disabled state (safe)
    var spr_lock = sprite_get_index("spr_lock_small");

    for (var i3 = 0; i3 < array_length(view_keys); i3++) {
        var key = view_keys[i3];
        var def = variable_struct_get(global.upgrade_defs, key);
        if (!is_struct(def)) continue;

        var st  = variable_struct_get(global.upgrades, key);
        var lvl = (is_struct(st) && variable_struct_exists(st, "level")) ? st.level : 0;
        var max_lvl = variable_struct_exists(def, "max_level") ? def.max_level : 0;
        var btn_lbl = is_undefined(def.name) ? key : string(def.name);

        var label_w = string_width(btn_lbl) * lbl_scale;
        var btn_w   = max(btn_minw, label_w + 24);

        var lvl_str = "x " + string(lvl);
        var lvl_w   = string_width(lvl_str) * sub_scale;

        var total_w = btn_w + lvl_gap + lvl_w;

        if (x_cursor + total_w + pad > _x + _w) {
            x_cursor = _x + pad;
            y_cursor += theme.row_h + theme.gap;
            if (y_cursor + theme.row_h > _y + mid_h) break;
        }

        var cost    = __cost_at(def, lvl);
        var have_b  = currency_total_bronze();

        var can_level_more = (lvl < max_lvl || max_lvl <= 0);
        var can_afford     = (have_b >= cost);
        var can_buy        = can_level_more && can_afford;
        var disabled       = !can_buy;

        var btn_x1 = x_cursor;
        var btn_y1 = y_cursor;
        var btn_x2 = btn_x1 + btn_w;
        var btn_y2 = btn_y1 + theme.row_h;

        var over_btn = point_in_rectangle(mx, my, btn_x1, btn_y1, btn_x2, btn_y2);

        // ---- ALPHA: snappy tween on BACK PANEL only ----
        var target_a = disabled ? 0.45 : (over_btn ? 1.00 : 0.80);
        var a_store  = 0.80;
        if (variable_struct_exists(__btn_alpha_by_key, key)) a_store = variable_struct_get(__btn_alpha_by_key, key);
        var LERP = 0.45; // snappy
        a_store = a_store + (target_a - a_store) * LERP;
        variable_struct_set(__btn_alpha_by_key, key, a_store);

        // ---- VISUALS: BACKGROUND (no borders) ----
        draw_set_alpha(a_store);
        if (spr_ui_button != -1) {
            draw_sprite_stretched(spr_ui_button, 0, btn_x1, btn_y1, btn_w, theme.row_h);
        } else {
            draw_set_color(theme.col_btn);
            draw_roundrect(btn_x1, btn_y1, btn_x2, btn_y2, false);
        }
        draw_set_alpha(1);

        // optional lock badge on disabled (subtle)
        if (disabled && sprite_exists(spr_lock)) {
            var lh = max(1, sprite_get_height(spr_lock));
            var lw = sprite_get_width(spr_lock);
            var sc = clamp((theme.row_h * 0.55) / lh, 0.35, 1.0);
            var lock_cx = btn_x1 + 10 + (lw * sc) * 0.5;
            var lock_cy = btn_y1 + theme.row_h * 0.5;
            draw_sprite_ext(spr_lock, 0, lock_cx, lock_cy, sc, sc, 0, c_white, 0.7);
        }

        // ---- LABEL (hover → very white if purchasable) ----
        var label_col = disabled ? theme.col_dim : (over_btn ? c_white : theme.col_text);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(label_col);
        var cx = (btn_x1 + btn_x2) * 0.5;
        var cy = btn_y1 + theme.row_h * 0.5;
        draw_text_transformed(cx, cy, btn_lbl, lbl_scale, lbl_scale, 0);

        // ---- LEVEL to the RIGHT (always dim) ----
        var lvl_x = btn_x2 + lvl_gap;
        var lvl_y = cy;
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(theme.col_dim);
        draw_text_transformed(lvl_x, lvl_y, lvl_str, sub_scale, sub_scale, 0);

        // ---- TOOLTIP on hover ----
        if (over_btn) {
            var tip = get_upgrade_tooltip_text(key);
            if (is_string(tip) && tip != "") {
                if (disabled) {
                    if (!can_level_more) tip += "\n(Max level reached)";
                    else if (!can_afford) tip += "\n(Not enough bronze: " + string(cost) + ")";
                }
                global.tooltip_text = tip;
                global.tooltip_x = mx + 14;
                global.tooltip_y = my + 16;
            }
        }

        // ---- HOVER SFX (once on enter; only when clickable) ----
        if (over_btn) {
            hovered_now = key;
            if (__upgrade_prev_hover != hovered_now && can_buy) {
                if (audio_exists(sfx_hover)) audio_play_sound(sfx_hover, 0, false);
            }
        }

        // ---- CLICK ----
        if (over_btn && mouse_check_button_pressed(mb_left)) {
            if (can_buy) {
                if (remove_from_inventory("coin_bronze", cost)) {
                    if (!is_struct(st)) st = { level: 0 };
                    st.level = (max_lvl > 0) ? min(max_lvl, st.level + 1) : st.level + 1;
                    variable_struct_set(global.upgrades, key, st);

                    global.__save_dirty    = true;
                    global.__save_cooldown = global.__save_interval_steps;

                    var p = noone;
                    if (variable_global_exists("player") && instance_exists(global.player)) p = global.player;
                    else if (object_exists(oPlayer) && instance_number(oPlayer) > 0) p = instance_find(oPlayer, 0);
                    if (p != noone) recalc_stats(p);

                    if (!is_array(toasts)) toasts = [];
                    array_push(toasts, { text:(btn_lbl + " upgraded!"), age:0, ttl:100 });

                    if (audio_exists(sfx_click)) audio_play_sound(sfx_click, 0, false);
                }
            } else {
                if (!is_array(toasts)) toasts = [];
                var reason = (!can_level_more) ? "Max level reached" : ("Need " + string(cost) + " bronze");
                array_push(toasts, { text: reason, age:0, ttl:70 });
            }
        }

        // Advance
        x_cursor += total_w + theme.gap;
    }

    // Commit hover tracker
    __upgrade_prev_hover = hovered_now;

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
