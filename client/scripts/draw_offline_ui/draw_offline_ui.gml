function draw_offline_ui(_cam_x, _cam_y, _cam_w, _cam_h)
{
    if (!variable_instance_exists(id, "offline_visible") || !offline_visible) return;

    // -------- draw-once-per-step guard (prevents accidental double calls) --------
    static __last_tick = -1;
    var __now = current_time;
    if (__last_tick == __now) return;
    __last_tick = __now;

    var cfg = {
        panel_spr          : spr_ui_panel_medium,

        card_w_abs         : 520,
        card_w_pct_of_cam  : 0.90,
        card_h_pct_of_cam  : 0.90,

        pad_outer          : 16,
        gap_title          : 8,
        gap_after_subtitle : 28,
        gap_before_list    : 28,
        gap_section        : 28,
        row_gap            : 12,

        font               : -1,
        title_color        : c_white,
        subtitle_color     : make_color_rgb(200,200,200),
        header_color       : make_color_rgb(170,170,170),
        text_color         : c_white,
        rule_color         : make_color_rgb(70,90,100),
        subtitle_line_sep  : 2,

        row_h              : 32,
        icon_sz            : 16,      // desired icon cell size
        icon_snap_integer  : true,    // snap scale to 1x/2x/3x for crisp pixels
        icon_min_scale     : 0.6,     // don't shrink below this factor

        max_rows           : 7,

        btn_w              : 200,
        btn_h              : 34,
        btn_gap_top        : 12,
        btn_bottom_pad     : 8,
        btn_fill_color     : make_color_rgb(240,240,240),
        btn_fill_hover     : make_color_rgb(255,220,0),
        btn_text_color     : make_color_rgb(20,20,20),
        btn_label          : "Collect",

        extra_rule_gap     : 2,
        debug_outline      : false
    };

    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    var _text_h      = function(_s)       { return string_height(_s); };
    var _text_h_wrap = function(_s,_s2,_w){ return string_height_ext(_s,_s2,_w); };
    var _text_w      = function(_s)       { return string_width(_s); };

    if (cfg.font != -1) draw_set_font(cfg.font);

    var report = variable_global_exists("offline_report") ? global.offline_report : undefined;
    var lines  = (is_struct(report) && is_array(report.lines)) ? report.lines : [];
    var rows_nominal = min(cfg.max_rows, array_length(lines));

    // ---- integer-snapped sizing/placement to avoid sub-pixel seams ----
    var card_w = min(cfg.card_w_abs, _cam_w * cfg.card_w_pct_of_cam);
    card_w     = floor(card_w);
    var card_x = floor(_cam_x + (_cam_w - card_w) * 0.5);

    // Backdrop
    draw_set_alpha(offline_alpha_bg);
    draw_set_color(c_black);
    draw_rectangle(_cam_x, _cam_y, _cam_x + _cam_w, _cam_y + _cam_h, false);
    draw_set_alpha(1);
    draw_set_color(c_white);

    var secs  = is_struct(report) ? report.seconds : 0;
    var mins  = floor(secs / 60);
    var rem_s = secs mod 60;
    var act   = is_struct(report) ? report.activity_type : "idle";
    var human = (mins > 0) ? (string(mins) + "m " + string(rem_s) + "s") : (string(rem_s) + "s");

    var subtitle = "Time offline: " + human + "   Activity: " + string_upper(act);
    if (act == "combat" && is_struct(report) && !is_undefined(report.kills) && report.kills > 0) {
        subtitle += "   Kills: " + string(report.kills);
    }

    var inner_w_measure = card_w - (cfg.pad_outer * 2);
    var title_h   = _text_h("A") + 4;
    var sub_h     = _text_h_wrap(subtitle, cfg.subtitle_line_sep, inner_w_measure);
    var rewards_h = _text_h("A");

    var pre_list = (
        title_h + cfg.gap_title + sub_h + cfg.gap_after_subtitle +
        cfg.gap_section + rewards_h + cfg.gap_before_list
    );

    var fixed_bottom = cfg.btn_gap_top + cfg.btn_h + cfg.btn_bottom_pad;
    var card_h_guess = (cfg.pad_outer*2) + pre_list + (rows_nominal * (cfg.row_h + cfg.row_gap)) + fixed_bottom;
    var card_h       = min(card_h_guess, _cam_h * cfg.card_h_pct_of_cam);
    card_h           = floor(card_h);
    var card_y       = floor(_cam_y + (_cam_h - card_h) * 0.5);

    var inner_x = card_x + cfg.pad_outer;
    var inner_y = card_y + cfg.pad_outer;
    var inner_w = card_w - (cfg.pad_outer * 2);
    var inner_h = card_h - (cfg.pad_outer * 2);

    var list_space = max(0, inner_h - pre_list - fixed_bottom);
    var rows_fit   = min(rows_nominal, floor(list_space / (cfg.row_h + cfg.row_gap)));

    card_h = (cfg.pad_outer*2) + pre_list + (rows_fit * (cfg.row_h + cfg.row_gap)) + fixed_bottom;
    card_h = floor(card_h);
    card_y = floor(_cam_y + (_cam_h - card_h) * 0.5);

    inner_x = card_x + cfg.pad_outer;
    inner_y = card_y + cfg.pad_outer;
    inner_w = card_w - (cfg.pad_outer * 2);
    inner_h = card_h - (cfg.pad_outer * 2);

    // ---- draw the panel once, compensating for sprite origin ----
    var spr = cfg.panel_spr;
    var ox  = sprite_get_xoffset(spr);
    var oy  = sprite_get_yoffset(spr);

    draw_set_alpha(offline_alpha_card);
    draw_sprite_stretched(spr, 0, card_x - ox, card_y - oy, card_w, card_h);
    draw_set_alpha(1);

    // ----------------------------- content -----------------------------
    var draw_y = inner_y;

    draw_set_color(cfg.title_color);
    draw_text(inner_x, draw_y, "While you were away");
    draw_y += title_h + cfg.gap_title;

    draw_set_color(cfg.subtitle_color);
    draw_text_ext(inner_x, draw_y, subtitle, cfg.subtitle_line_sep, inner_w);
    draw_y += sub_h + cfg.gap_after_subtitle;

    draw_set_color(cfg.header_color);
    draw_text(inner_x, draw_y - cfg.extra_rule_gap, "Rewards:");
    draw_y += cfg.gap_before_list;

    // Rewards list — scaled & vertically centered icons
    draw_set_color(cfg.text_color);
    var icon_cell = cfg.icon_sz;
    var text_h = _text_h("A"); // >>> cache text height for vertical centering

    for (var i = 0; i < rows_fit; i++)
    {
        var entry   = lines[i];
        var item_id = entry.id;
        var amount  = entry.amount;

        var row_y = draw_y + (i * (cfg.row_h + cfg.row_gap));

        // --- TEXT block metrics (top + center) ---------------------------------
        var label_y = row_y + (cfg.row_h - text_h) * 0.5;     // top of text line in row
        var cy_text = label_y + (text_h * 0.5);               // >>> vertical center of text

        // --- ICON (scaled to fit icon_cell), centered to text center ------------
        var def = variable_struct_get(global.item_data, item_id);
        if (!is_undefined(def) && !is_undefined(def.icon)) {
            var ispr = def.icon;
            var sw   = sprite_get_width(ispr);
            var sh   = sprite_get_height(ispr);

            var scale = icon_cell / max(sw, sh);
            scale = (cfg.icon_snap_integer) ? max(cfg.icon_min_scale, round(scale))
                                            : max(cfg.icon_min_scale, scale);

            var cx = inner_x + icon_cell * 0.5; // center of icon cell (x)
            var cy = cy_text;                   // >>> match text's vertical center

            // draw centered (ignore sprite origin to avoid offsets)
            draw_sprite_ext(ispr, 0, floor(cx), floor(cy), scale, scale, 0, c_white, 1);
        }

        // --- TEXT (to the right of icon cell) -----------------------------------
        draw_text(inner_x + icon_cell + 8, label_y, entry.name + "  x" + string(amount));
    }

    if (array_length(lines) > rows_fit) {
        var more = array_length(lines) - rows_fit;
        var more_y = draw_y + (rows_fit * (cfg.row_h + cfg.row_gap)) + 4;
        draw_set_color(make_color_rgb(200,200,120));
        draw_text(inner_x, more_y, "+ " + string(more) + " more…");
    }

    var btn_x = card_x + (card_w - cfg.btn_w) * 0.5;
    var btn_y = card_y + card_h - cfg.pad_outer - cfg.btn_h;

    var hover = point_in_rectangle(_mx, _my, btn_x, btn_y, btn_x + cfg.btn_w, btn_y + cfg.btn_h);

    draw_set_color(hover ? cfg.btn_fill_hover : cfg.btn_fill_color);
    draw_rectangle(btn_x, btn_y, btn_x + cfg.btn_w, btn_y + cfg.btn_h, false);

    draw_set_color(cfg.btn_text_color);
    var tx = btn_x + (cfg.btn_w - _text_w(cfg.btn_label)) * 0.5;
    var ty = btn_y + (cfg.btn_h - _text_h(cfg.btn_label)) * 0.5;
    draw_text(tx, ty, cfg.btn_label);

    global.ui_mouse_block = true;

    if (hover && mouse_check_button_pressed(mb_left)) {
        offline_visible = false;
    }

    draw_set_color(c_white);
    draw_set_alpha(1);
}
