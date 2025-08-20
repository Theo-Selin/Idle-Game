/// oPopupFloat — Draw
draw_set_font(fLootPopup);
draw_set_valign(fa_middle);
draw_set_halign(fa_left);

// Resolve icon sprite (resource index only; -1 means none)
var spr = -1;
if (icon_sprite != -1) {
    spr = icon_sprite;
} else if (sprite != -1) { // legacy fallback if some spawners still set "sprite"
    spr = sprite;
}

// Measure content (scaled)
var label = text;
var tw = string_width(label) * scale;
var th = string_height(label) * scale;

var iw = (spr != -1) ? (sprite_get_width(spr)  * icon_scale) : 0;
var ih = (spr != -1) ? (sprite_get_height(spr) * icon_scale) : 0;

var total_w   = iw + ((spr != -1) ? padding : 0) + tw;
var content_h = max(th, ih);

// Background box (centered on x,y)
var cx = round(x);
var cy = round(y);
var box_w = total_w + bg_pad_x * 2;
var box_h = content_h + bg_pad_y * 2;

var x1 = cx - box_w * 0.5;
var y1 = cy - box_h * 0.5;
var x2 = x1 + box_w;
var y2 = y1 + box_h;

// --- Background ---
if (bg_enabled) {
    draw_set_color(bg_color);
    draw_set_alpha(alpha * bg_opacity);
    if (bg_rounded) draw_roundrect(x1, y1, x2, y2, false); else draw_rectangle(x1, y1, x2, y2, false);
}

// Foreground (fades with popup alpha)
draw_set_alpha(alpha);

// Content area top-left
var content_x = x1 + bg_pad_x;
var content_y = y1 + bg_pad_y;

// Icon (optional) — vertically centered; accounts for sprite origin
if (spr != -1) {
    var icon_top  = content_y + (content_h - ih) * 0.5;
    var icon_left = content_x;

    var xoff = sprite_get_xoffset(spr) * icon_scale;
    var yoff = sprite_get_yoffset(spr) * icon_scale;

    // Put the sprite's origin at (icon_left, icon_top) for true top-left alignment
    draw_sprite_ext(spr, icon_index, icon_left + xoff, icon_top + yoff, icon_scale, icon_scale, 0, c_white, alpha);

    content_x += iw + padding; // advance pen
}

// Text (vertically centered)
draw_set_color(color);
draw_text_transformed(content_x, cy, label, scale, scale, 0);

// Reset state
draw_set_alpha(1);
