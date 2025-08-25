function draw_tooltip(){
    /// draw_tooltip(text, x, y)
    /// @arg text  // supports tokens: [G] [S] [C]
    /// @arg x
    /// @arg y
    var _text = argument0;
    var _x    = argument1;
    var _y    = argument2;

    // --- Icon setup (½ scale) ---
    var sc = 0.5;

    var hasG = sprite_exists(spr_coin_gold);
    var hasS = sprite_exists(spr_coin_silver);
    var hasC = sprite_exists(spr_coin_copper);

    var gw = hasG ? sprite_get_width(spr_coin_gold)   * sc : 0;
    var sw = hasS ? sprite_get_width(spr_coin_silver) * sc : 0;
    var bw = hasC ? sprite_get_width(spr_coin_copper) * sc : 0;

    var gh = hasG ? sprite_get_height(spr_coin_gold)   * sc : 0;
    var sh = hasS ? sprite_get_height(spr_coin_silver) * sc : 0;
    var bh = hasC ? sprite_get_height(spr_coin_copper) * sc : 0;

    var base_line_h = string_height("A");
    var line_h = max(base_line_h, max(gh, max(sh, bh)));

    // --- Split into lines (simple, no string_pos_ext) ---
    var lines = [];
    {
        var start = 1;
        var total_len = string_length(_text);
        if (total_len == 0) {
            array_push(lines, "");
        } else {
            while (start <= total_len) {
                var rem_len = total_len - start + 1;
                var slice   = string_copy(_text, start, rem_len);
                var nl_pos  = string_pos("\n", slice);
                if (nl_pos <= 0) {
                    array_push(lines, slice);
                    break;
                } else {
                    array_push(lines, string_copy(slice, 1, nl_pos - 1));
                    start += nl_pos; // skip newline
                }
            }
        }
    }

    // --- Measure width with token icons ---
    var pad = 6;
    var max_w = 0;

    for (var i = 0; i < array_length(lines); i++) {
        var rest = lines[i];
        var w = 0;

        while (true) {
            var pG = string_pos("[G]", rest);
            var pS = string_pos("[S]", rest);
            var pC = string_pos("[C]", rest);

            var p = 0;
            if (pG > 0) p = (p == 0) ? pG : min(p, pG);
            if (pS > 0) p = (p == 0) ? pS : min(p, pS);
            if (pC > 0) p = (p == 0) ? pC : min(p, pC);

            if (p == 0) { w += string_width(rest); break; }

            // text before token
            if (p > 1) {
                var seg = string_copy(rest, 1, p - 1);
                w += string_width(seg);
            }

            // token width
            var tok = string_copy(rest, p, 3);
            if (tok == "[G]")      w += gw;
            else if (tok == "[S]") w += sw;
            else                   w += bw;

            // chop processed (prefix + token)
            rest = string_delete(rest, 1, p + 2);
        }

        max_w = max(max_w, w);
    }

    var box_w = max_w + pad * 2;
    var box_h = array_length(lines) * line_h + pad * 2;

    // --- Prevent offscreen (right + bottom only) ---
    if (_x + box_w > display_get_gui_width())  _x = display_get_gui_width()  - box_w - 4;
    if (_y + box_h > display_get_gui_height()) _y = display_get_gui_height() - box_h - 4;

    // --- Background ---
    draw_set_color(make_color_rgb(30, 30, 30));
    draw_rectangle(_x, _y, _x + box_w, _y + box_h, false);
    draw_set_color(make_color_rgb(0, 0, 0));
    draw_rectangle(_x + 1, _y + 1, _x + box_w - 1, _y + box_h - 1, true);

    // --- Draw lines with tokens ---
    draw_set_color(c_white);
    var dy = _y + pad;

    for (var j = 0; j < array_length(lines); j++) {
        var rest2 = lines[j];
        var cx = _x + pad;

        while (true) {
            var pG2 = string_pos("[G]", rest2);
            var pS2 = string_pos("[S]", rest2);
            var pC2 = string_pos("[C]", rest2);

            var p2 = 0;
            var tok2 = "";
            if (pG2 > 0 && (p2 == 0 || pG2 < p2)) { p2 = pG2; tok2 = "[G]"; }
            if (pS2 > 0 && (p2 == 0 || pS2 < p2)) { p2 = pS2; tok2 = "[S]"; }
            if (pC2 > 0 && (p2 == 0 || pC2 < p2)) { p2 = pC2; tok2 = "[C]"; }

            if (p2 == 0) {
                if (rest2 != "") draw_text(cx, dy, rest2);
                break;
            }

            // text before token
            if (p2 > 1) {
                var seg2 = string_copy(rest2, 1, p2 - 1);
                if (seg2 != "") {
                    draw_text(cx, dy, seg2);
                    cx += string_width(seg2);
                }
            }

            // icon dims (no ternary chains)
            var iw = 0, ih = 0;
            if (tok2 == "[G]")      { iw = gw; ih = gh; }
            else if (tok2 == "[S]") { iw = sw; ih = sh; }
            else                    { iw = bw; ih = bh; }

            var iy = dy + (line_h - ih) * 0.5;

            // draw the icon
            if (tok2 == "[G]" && hasG) {
                draw_sprite_ext(spr_coin_gold, 0, cx + iw * 0.5, iy + ih * 0.5, sc, sc, 0, c_white, 1);
            } else if (tok2 == "[S]" && hasS) {
                draw_sprite_ext(spr_coin_silver, 0, cx + iw * 0.5, iy + ih * 0.5, sc, sc, 0, c_white, 1);
            } else if (hasC) {
                draw_sprite_ext(spr_coin_copper, 0, cx + iw * 0.5, iy + ih * 0.5, sc, sc, 0, c_white, 1);
            }

            cx += iw;

            // advance after token
            rest2 = string_delete(rest2, 1, p2 + 2);
        }

        dy += line_h;
    }
}
