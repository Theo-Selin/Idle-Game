/// oUIManager.Draw
draw_set_font(fnt_ui);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

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

// --- Toast rendering (lightweight, mobile-friendly) ---
if (array_length(toasts) > 0) {
    var tx = cam_x + 16 * scale_x;
    var ty = cam_y + 64 * scale_y; // below the toggle/AUTO row
    var gap = 4 * scale_y;
    var pad = 6;

    draw_set_font(fnt_ui);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // Draw newest at top; limit to 3 to keep overdraw tiny
    var count = min(3, array_length(toasts));
    for (var j = 0; j < count; j++) {
        var idx = array_length(toasts) - 1 - j; // newest first
        var t = toasts[idx];
        var a = t.age, ttl = t.ttl;

        // Fade in/out
        var fade_in  = min(1, a / 10);                  // first 10 frames
        var fade_out = (a > ttl - 15) ? (ttl - a) / 15 : 1; // last 15 frames
        var alpha = clamp(fade_in * fade_out, 0, 1);

        var text_w = string_width(t.text);
        var text_h = string_height(t.text);

        var bx1 = tx;
        var by1 = ty + (text_h + gap) * j;
        var bx2 = bx1 + text_w + pad * 2;
        var by2 = by1 + text_h + pad * 2;

        // Panel
        draw_set_alpha(0.9 * alpha);
        draw_set_color(make_color_rgb(20,20,24));
        draw_roundrect(bx1, by1, bx2, by2, true);

        // Text
        draw_set_alpha(alpha);
        draw_set_color(c_white);
        draw_text(bx1 + pad, by1 + pad, t.text);

        // Reset
        draw_set_alpha(1);
    }
}

// Restore defaults used elsewhere
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// === DEBUG CROSSHAIRS (optional) ===
draw_set_color(c_lime);
draw_rectangle(mx - 2, my - 2, mx + 2, my + 2, false);
draw_text(mx + 6, my, "MOUSE");

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

// ----------------------------------------------------
// (Removed header meters from here; they now live in draw_character_stats_ui)
// ----------------------------------------------------
var content_y2 = content_y;
var content_h2 = content_h;

// === DRAW LEFT-SIDE TABS ===
var tab_spacing = 64 * scale_y;
var label_x_center = tab_x + (tab_column_w / 2);

for (var i = 0; i < array_length(ui_tabs); i++) {
    var label  = string_upper(ui_tabs[i]);
    var text_w = string_width(label);
    var text_h = string_height(label);

    var x_pos = label_x_center - text_w / 2;
    var y_pos = tab_y + i * tab_spacing;

    var is_active = (active_tab == ui_tabs[i]);
    draw_set_color(is_active ? c_white : make_color_rgb(180, 180, 180));
    draw_text(x_pos, y_pos, label);

    // HITBOX
    var padding_x = 6 * scale_x;
    var padding_y = 4 * scale_y;

    var hitbox_x1 = x_pos - padding_x;
    var hitbox_y1 = y_pos - padding_y;
    var hitbox_x2 = x_pos + text_w + padding_x;
    var hitbox_y2 = y_pos + text_h + padding_y;

    if (point_in_rectangle(mx, my, hitbox_x1, hitbox_y1, hitbox_x2, hitbox_y2)) {
        if (mouse_check_button_pressed(mb_left)) {
            active_tab = ui_tabs[i];
        }
    }
}

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
}

// === TOOLTIP RENDERING (centralized single draw) ===
if (is_string(global.tooltip_item_id) && global.tooltip_item_id != "") {
    var _tt = get_item_tooltip_text(global.tooltip_item_id);

    // Get per-item sell price (bronze). Use precomputed if provided by the hover code.
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
