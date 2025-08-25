/// oDamageFloat — Draw
var t = clamp(timer / lifespan, 0, 1);
var col = merge_color(col_start, col_end, t); // subtle color shift

var cx = round(x);
var cy = round(y);

// Optional background
if (bg_enabled) {
    var tw = string_width(label) * image_xscale;
    var th = string_height(label) * image_yscale;
    var x1 = cx - (tw * 0.5) - bg_pad_x;
    var y1 = cy - (th * 0.5) - bg_pad_y;
    var x2 = cx + (tw * 0.5) + bg_pad_x;
    var y2 = cy + (th * 0.5) + bg_pad_y;
    draw_set_alpha(alpha * bg_opacity);
    draw_set_color(bg_color);
    if (bg_rounded) draw_roundrect(x1, y1, x2, y2, false); else draw_rectangle(x1, y1, x2, y2, false);
}

// Shadow
draw_set_font(font_damage);
draw_set_valign(fa_middle);
draw_set_halign(fa_center);
draw_set_alpha(alpha * 0.8);
draw_set_color(c_black);
draw_text_transformed(cx + 1, cy + 1, label, image_xscale, image_yscale, rot);

// Main
draw_set_alpha(alpha);
draw_set_color(col);
draw_text_transformed(cx, cy, label, image_xscale, image_yscale, rot);

// Reset
draw_set_alpha(1);
