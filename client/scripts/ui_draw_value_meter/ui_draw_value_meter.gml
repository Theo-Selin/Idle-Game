/// @function ui_draw_value_meter(label, cur, max, x, y, w, h, fill_col)
/// @desc Bar with label on the LEFT side of the bar and value on the RIGHT side of the bar.
function ui_draw_value_meter(_label, _cur, _max, _x, _y, _w, _h, _fill_col)
{
    var _frac = (_max <= 0) ? 0 : clamp(_cur / _max, 0, 1);

    // Local colors
    var col_back   = make_color_rgb(20,20,24);
    var col_text   = make_color_rgb(235,235,240);
    var col_shadow = make_color_rgb(0,0,0);

    // Spacing for text outside the bar
    var text_pad = 10;

    // Font
    var prev_font = draw_get_font();
    if (variable_global_exists("f_ui_small")) draw_set_font(global.f_ui_small);

    // Back plate
    draw_set_alpha(0.85);
    draw_set_color(col_back);
    draw_roundrect(_x, _y, _x + _w, _y + _h, false);
    draw_set_alpha(1);

    // Fill (same vertical bounds as backplate; width scales by _frac)
    var fx1 = _x;
    var fy1 = _y;
    var fx2 = _x + max(1, floor(_w * _frac));
    var fy2 = _y + _h;
    draw_set_color(_fill_col);
    draw_roundrect(fx1, fy1, fx2, fy2, false);

    // ---- Text OUTSIDE the bar ----
    var value_text = string(_cur) + " / " + string(max(1, _max));
    var center_y   = _y + _h * 0.5;

    // LEFT side label (right-aligned to sit snug against the bar)
    var label_x = _x - text_pad;
    draw_set_valign(fa_middle);

    // shadow
    draw_set_color(col_shadow);
    draw_set_halign(fa_right);
    draw_text(label_x + 1, center_y + 1, string_upper(_label));

    // fg
    draw_set_color(col_text);
    draw_text(label_x, center_y, string_upper(_label));

    // RIGHT side value (left-aligned to sit snug against the bar)
    var value_x = _x + _w + text_pad;

    // shadow
    draw_set_color(col_shadow);
    draw_set_halign(fa_left);
    draw_text(value_x + 1, center_y + 1, value_text);

    // fg
    draw_set_color(col_text);
    draw_text(value_x, center_y, value_text);

    // restore
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(prev_font);
}
