/// oUIManager.Draw
draw_set_font(fnt_ui);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// Ensure queue exists (avoids undefined access)
if (!variable_instance_exists(id, "toasts")) toasts = [];

// === CAMERA INFO ===
var cam   = view_camera[0];
var cam_x = camera_get_view_x(cam);
var cam_y = camera_get_view_y(cam);
var cam_w = camera_get_view_width(cam);
var cam_h = camera_get_view_height(cam);

// === MOUSE POSITION (GUI space if you use device_* elsewhere) ===
var mx = mouse_x;
var my = mouse_y;

// === OFFLINE POPUP ...
if (variable_instance_exists(id, "offline_visible") && offline_visible) {
    draw_offline_ui(cam_x, cam_y, cam_w, cam_h);
    exit;
}

// === SIMULATED 1280x720 GAME UI ===
var target_w = 1280;
var target_h = 720;

// === SCALE FACTOR TO MATCH 1280x720 DESIGN ===
var scale_x = cam_w / target_w;
var scale_y = cam_h / target_h;

// === PANEL POSITIONING BASED ON TARGET DESIGN ===
var panel_w = 922;
var panel_h = 599;
var panel_x = cam_x + ((target_w - panel_w) div 2) * scale_x;
var panel_y = cam_y + ((target_h - panel_h) div 2) * scale_y;

// === TOGGLE BUTTON (FIXED IN TOP-LEFT OF VIEW) ===
var toggle_size = 32 * scale_x;
var toggle_x = cam_x + 16 * scale_x;
var toggle_y = cam_y + 16 * scale_y;
toggle_button_rect = [toggle_x, toggle_y, toggle_x + toggle_size, toggle_y + toggle_size];

draw_set_color(c_white);
draw_rectangle(toggle_x, toggle_y, toggle_button_rect[2], toggle_button_rect[3], false);

// === AUTO COMBAT BUTTON (touch-friendly) ===
var auto_w = 96 * scale_x;
var auto_h = 32 * scale_y;
var auto_x = toggle_button_rect[2] + 12 * scale_x;
var auto_y = toggle_button_rect[1];

auto_btn_rect = [auto_x, auto_y, auto_x + auto_w, auto_y + auto_h];

draw_set_alpha(0.9);
draw_set_color(global.auto_combat_enabled ? make_color_rgb(80,200,120) : make_color_rgb(70,70,70));
draw_roundrect(auto_x, auto_y, auto_btn_rect[2], auto_btn_rect[3], false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(auto_x + auto_w * 0.5, auto_y + auto_h * 0.5, "AUTO");

// --- Toast rendering (top-center, text + optional sprite; centered, rounded backpanel) ---
if (array_length(toasts) > 0) {
    var max_show = min(3, array_length(toasts));
    var gap_y    = 6 * scale_y;

    var start_x_center = cam_x + cam_w * 0.5;
    var y_cur          = cam_y + 16 * scale_y;

    draw_set_font(fnt_ui);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle); // draw text at row midline

    var toast_scale = 1; // a little bigger text

    for (var j = 0; j < max_show; j++) {
        var idx = array_length(toasts) - 1 - j; // newest first
        var t   = toasts[idx];

        var a   = t.age;
        var ttl = t.ttl;

        if (a <= 0) { a = 1; t.age = 1; toasts[idx] = t; } // safety

        var fade_in  = min(1, a / 10);
        var fade_out = (a > ttl - 15) ? (ttl - a) / 15 : 1;
        var alpha    = clamp(fade_in * fade_out, 0, 1);

        var text = string(t.text);
        var tw   = string_width(text);
        var th   = string_height(text);

        // Optional sprite resolve
        var spr_icon = -1;
        if (is_struct(t) && variable_struct_exists(t, "spr")) {
            spr_icon = is_string(t.spr) ? sprite_get_index(t.spr) : t.spr;
            if (!sprite_exists(spr_icon)) spr_icon = -1;
        }

        // Layout constants
        var pad_x    = 12 * scale_x;
        var pad_y    = 8  * scale_y;
        var icon_gap = 12 * scale_x;

        // Size text (scaled)
        var text_w_scaled = tw * toast_scale;
        var text_h_scaled = th * toast_scale;

        // Icon sized relative to text height, with a minimum
        var ICON_TEXT_MULT = 1.0;
        var ICON_MIN_PX    = 28 * scale_y;

        var icon_h        = (spr_icon != -1) ? max(text_h_scaled * ICON_TEXT_MULT, ICON_MIN_PX) : 0;
        var icon_w_scaled = 0;
        var icon_scale    = 1;

        if (spr_icon != -1) {
            var iw = sprite_get_width(spr_icon);
            var ih = max(1, sprite_get_height(spr_icon));
            icon_scale    = icon_h / ih;
            icon_w_scaled = iw * icon_scale;
        }

        // Content + panel sizes
        var content_w = (spr_icon != -1 ? (icon_w_scaled + icon_gap) : 0) + text_w_scaled;
        var row_h     = max(text_h_scaled, icon_h);
        var box_w     = content_w + pad_x * 2;
        var box_h     = row_h     + pad_y * 2;

        var bx1 = round(start_x_center - box_w * 0.5);
        var by1 = round(y_cur);
        var bx2 = bx1 + box_w;
        var by2 = by1 + box_h;

        // Backpanel (rounded rectangle @ 0.8 alpha)
        draw_set_alpha(0.8 * alpha);
        draw_set_color(make_color_rgb(20,20,24));
        draw_roundrect(bx1, by1, bx2, by2, false);

        // Content positions
        var row_mid_y = by1 + box_h * 0.5;
        var cx        = bx1 + pad_x;

        // ICON — pass alpha directly (text alpha doesn't affect sprites)
        if (spr_icon != -1) {
            draw_sprite_ext(
                spr_icon, 0,
                cx + icon_w_scaled * 0.5,
                row_mid_y,
                icon_scale, icon_scale, 0, c_white, alpha
            );
            cx += icon_w_scaled + icon_gap;
        }

        // TEXT — use global alpha
        draw_set_alpha(alpha);
        draw_set_color(c_white);
        draw_text_transformed(cx, row_mid_y, text, toast_scale, toast_scale, 0);
        draw_set_alpha(1);

        // Advance
        y_cur = by2 + gap_y;
    }
}

// Restore defaults used elsewhere
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// === UI VISIBILITY ===
if (!ui_visible) exit;

// === PANEL BACKGROUND ===
draw_set_alpha(0.88);
draw_sprite(spr_ui_panel, 0, panel_x, panel_y);
draw_set_alpha(1);

// === BLOCK MOUSE IF INSIDE UI PANEL ===
var panel_x2 = panel_x + panel_w * scale_x;
var panel_y2 = panel_y + panel_h * scale_y;
if (point_in_rectangle(mx, my, panel_x, panel_y, panel_x2, panel_y2)) {
    global.ui_mouse_block = true;
}

// === LAYOUT CONSTANTS ===
var scaled_panel_w = panel_w * scale_x;
var scaled_panel_h = panel_h * scale_y;

// === 💡 UI LAYOUT SETTINGS ===
var outer_margin = 6 + scale_x;   // space from left and right edge of panel
var gutter       = 16 * scale_x;  // space between tabs and content
var tab_column_w = 142 * scale_x; // width of the tab column

// === Calculated positions based on settings above ===
var tab_x     = panel_x + outer_margin;
var tab_y     = panel_y + 128;
var tab_w     = tab_column_w * 2;
var tab_h     = scaled_panel_h - 16;

var content_x = panel_x + outer_margin + tab_column_w + gutter;
var content_y = panel_y + outer_margin;
var content_w = scaled_panel_w - (outer_margin * 2 + tab_column_w + gutter);
var content_h = scaled_panel_h - outer_margin * 2;

var content_y2 = content_y;
var content_h2 = content_h;

// ----- WALLET DISPLAY (top of left-side tab column; centered; sprite icons) -----
{
    var col_x = tab_x;
    var col_w = tab_column_w;
    var top_y = panel_y + outer_margin;
    var bottom_y = tab_y - (8 * scale_y);
    if (bottom_y <= top_y) bottom_y = top_y + 1;

    var pad_left = 6 * scale_x;
    var pad_top  = 2 * scale_y;
    var icon_pad = 6 * scale_x;
    var sec_gap  = 12 * scale_x;

    var bsg   = currency_get_bsg();
    var amt_g = (is_real(bsg.gold)   ? bsg.gold   : 0);
    var amt_s = (is_real(bsg.silver) ? bsg.silver : 0);
    var amt_b = (is_real(bsg.bronze) ? bsg.bronze : 0);

    var sc = 0.5;

    var gw = sprite_exists(spr_coin_gold)   ? sprite_get_width(spr_coin_gold)   * sc : 0;
    var gh = sprite_exists(spr_coin_gold)   ? sprite_get_height(spr_coin_gold)  * sc : 0;
    var sw = sprite_exists(spr_coin_silver) ? sprite_get_width(spr_coin_silver) * sc : 0;
    var sh = sprite_exists(spr_coin_silver) ? sprite_get_height(spr_coin_silver)* sc : 0;
    var bw = sprite_exists(spr_coin_copper) ? sprite_get_width(spr_coin_copper) * sc : 0;
    var bh = sprite_exists(spr_coin_copper) ? sprite_get_height(spr_coin_copper)* sc : 0;

    var text_h = string_height("A");
    var line_h = max(text_h, max(gh, max(sh, bh)));

    var g_txt = string(amt_g), s_txt = string(amt_s), b_txt = string(amt_b);
    var g_w = (gw > 0 ? gw + icon_pad : string_width("g") + icon_pad) + string_width(g_txt);
    var s_w = (sw > 0 ? sw + icon_pad : string_width("s") + icon_pad) + string_width(s_txt);
    var c_w = (bw > 0 ? bw + icon_pad : string_width("c") + icon_pad) + string_width(b_txt);
    var total_w = g_w + s_w + c_w + sec_gap * 2;

    var start_x = col_x + max(0, (col_w - total_w) * 0.5) + pad_left;

    var raise = 40 * scale_y;
    var cy = clamp(
        top_y + (bottom_y - top_y) * 0.5 + pad_top - raise,
        top_y    + line_h * 0.5,
        bottom_y - line_h * 0.5
    );

    var prev_h = draw_get_halign();
    var prev_v = draw_get_valign();
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);

    var xcur = start_x;

    if (gw > 0 && gh > 0) {
        draw_sprite_ext(spr_coin_gold, 0, xcur + gw * 0.5, cy, sc, sc, 0, c_white, 1);
        xcur += gw + icon_pad;
    } else {
        draw_text(xcur, cy, "g");
        xcur += string_width("g") + icon_pad;
    }
    draw_text(xcur, cy, g_txt);
    xcur += string_width(g_txt) + sec_gap;

    if (sw > 0 && sh > 0) {
        draw_sprite_ext(spr_coin_silver, 0, xcur + sw * 0.5, cy, sc, sc, 0, c_white, 1);
        xcur += sw + icon_pad;
    } else {
        draw_text(xcur, cy, "s");
        xcur += string_width("s") + icon_pad;
    }
    draw_text(xcur, cy, s_txt);
    xcur += string_width(s_txt) + sec_gap;

    if (bw > 0 && bh > 0) {
        draw_sprite_ext(spr_coin_copper, 0, xcur + bw * 0.5, cy, sc, sc, 0, c_white, 1);
        xcur += bw + icon_pad;
    } else {
        draw_text(xcur, cy, "c");
        xcur += string_width("c") + icon_pad;
    }
    draw_text(xcur, cy, b_txt);

    draw_set_halign(prev_h);
    draw_set_valign(prev_v);
}

// === DRAW LEFT-SIDE TABS ===
// hover SFX once-on-enter for tabs (but not for the active tab)
// click SFX when switching tabs
var sfx_hover_tabs = snd_ui_hover;
var sfx_tab_click  = snd_tab_click;
if (!variable_instance_exists(id, "__tab_prev_hover")) __tab_prev_hover = -1;
var hovered_tab_idx = -1;

var tab_spacing = 64 * scale_y;
var label_x_center = tab_x + (tab_column_w / 2);

for (var i = 0; i < array_length(ui_tabs); i++) {
    var label  = string_upper(ui_tabs[i]);
    var text_w = string_width(label);
    var text_h = string_height(label);

    var x_pos = label_x_center - text_w / 2;
    var y_pos = tab_y + i * tab_spacing;

    // HITBOX
    var padding_x = 6 * scale_x;
    var padding_y = 4 * scale_y;

    var hitbox_x1 = x_pos - padding_x;
    var hitbox_y1 = y_pos - padding_y;
    var hitbox_x2 = x_pos + text_w + padding_x;
    var hitbox_y2 = y_pos + text_h + padding_y;

    var is_active  = (active_tab == ui_tabs[i]);
    var is_hovered = point_in_rectangle(mx, my, hitbox_x1, hitbox_y1, hitbox_x2, hitbox_y2);

    if (is_hovered) hovered_tab_idx = i;

    // Color: hover → white, active → white, else dim
    draw_set_color((is_active || is_hovered) ? c_white : make_color_rgb(180, 180, 180));
    draw_text(x_pos, y_pos, label);

    // Click to activate (play click sound only if switching)
    if (is_hovered && mouse_check_button_pressed(mb_left)) {
        if (ui_tabs[i] != active_tab) {
            active_tab = ui_tabs[i];
            if (audio_exists(sfx_tab_click)) play_impact_sound(sfx_tab_click, 1, 1.5, 2);
        }
    }
}

// Play hover SFX once when entering a new (non-active) tab
if (hovered_tab_idx != -1 && hovered_tab_idx != __tab_prev_hover) {
    if (ui_tabs[hovered_tab_idx] != active_tab) {
        if (audio_exists(sfx_hover_tabs)) play_impact_sound(sfx_hover_tabs, 0.2, 1.5, 1.5);
    }
}
__tab_prev_hover = hovered_tab_idx;

// === DRAW ACTIVE TAB CONTENT (uses content_y2/content_h2) ===

// 🔹 Centralized tooltip reset for this frame (do this ONCE, before panels draw)
global.tooltip_item_id = "";
global.tooltip_text    = "";
global.tooltip_x       = 0;
global.tooltip_y       = 0;
global.tooltip_sell_bronze = undefined;

switch (active_tab) {
    case "character":
        draw_character_stats_ui(content_x, content_y2, content_w, content_h2);
        break;

    case "inventory":
        draw_inventory_ui(content_x, content_y2, content_w, content_h2);
        break;

    case "crafting":
        draw_crafting_ui(content_x, content_y2, content_w, content_h2);
        break;

    case "upgrade":
        draw_upgrade_ui(content_x, content_y2, content_w, content_h2);
        break;
}

// === TOOLTIP RENDERING (centralized single draw) ===
if (is_string(global.tooltip_item_id) && global.tooltip_item_id != "") {
    var _tt = get_item_tooltip_text(global.tooltip_item_id);

    var _sb = is_undefined(global.tooltip_sell_bronze)
              ? inv_get_sell_price_bronze(global.tooltip_item_id)
              : global.tooltip_sell_bronze;

    if (_sb > 0) {
        var _sv = currency_format_bronze(_sb); // "Xg Ys Zb"
        _tt = (_tt == "") ? ("Sell value: " + _sv) : (_tt + "\nSell value: " + _sv);
    }

    if (_tt != "") draw_tooltip(_tt, global.tooltip_x, global.tooltip_y);
}
else if (is_string(global.tooltip_text) && global.tooltip_text != "") {
    draw_tooltip(global.tooltip_text, global.tooltip_x, global.tooltip_y);
}
