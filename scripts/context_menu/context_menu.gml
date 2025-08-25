/// open_context_menu(_x, _y, _options_array, _category, _index, _item_id)
function open_context_menu(_x, _y, _options_array, _category, _index, _item_id) {
    if (!variable_struct_exists(global, "context_menu")) {
        global.context_menu = {
            is_open:false, x:0, y:0, options:[],
            source:{category:"", index:-1, item_id:""},
            __prev_hover:-1, __row_a:[]
        };
    }
    global.context_menu.is_open = true;
    global.context_menu.x = _x;
    global.context_menu.y = _y;
    global.context_menu.options = _options_array;
    global.context_menu.source  = { category:_category, index:_index, item_id:_item_id };

    // init hover state + alpha per row (0.80 base)
    global.context_menu.__prev_hover = -1;
    global.context_menu.__row_a = [];
    for (var i = 0; i < array_length(_options_array); i++) array_push(global.context_menu.__row_a, 0.80);
}

/// close_context_menu()
function close_context_menu() {
    if (!variable_struct_exists(global, "context_menu")) return;
    global.context_menu.is_open = false;
}

/// draw_context_menu_and_handle_input()
function draw_context_menu_and_handle_input() {
    if (!variable_struct_exists(global, "context_menu")) return false;
    if (!global.context_menu.is_open) return false;

    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    var opts = global.context_menu.options;
    var _x   = global.context_menu.x;
    var _y   = global.context_menu.y;

    if (array_length(opts) <= 0) return false;

    // ---- Look & feel ----
    var pad_x     = 10;
    var pad_y     = 8;
    var row_h     = 28;
    var row_gap   = 4;
    var label_pad = 12;
    var base_col  = make_color_rgb(36,36,44);
    var panel_col = make_color_rgb(20,20,24);

    // Measure width dynamically
    var min_w = 132;
    var max_label_w = 0;
    for (var i = 0; i < array_length(opts); i++) {
        var lbl = string(opts[i].label);
        max_label_w = max(max_label_w, string_width(lbl));
    }
    var w = max(min_w, max_label_w + label_pad*2 + 4);

    // Menu total height
    var n       = array_length(opts);
    var rows_h  = n * row_h + (n - 1) * row_gap;
    var total_h = pad_y * 2 + rows_h;

    // ---- Back panel ----
    draw_set_alpha(0.85);
    draw_set_color(panel_col);
    draw_roundrect(_x, _y, _x + w, _y + total_h, false);
    draw_set_alpha(1);

    // ---- Rows ----
    var hovered_idx = -1;
    var row_y = _y + pad_y;

    // Hover SFX
    var sfx_hover = snd_ui_hover;

    var prev_h = draw_get_halign();
    var prev_v = draw_get_valign();
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle); // vertical centering fix

    for (var i = 0; i < n; i++) {
        var label = string(opts[i].label);

        var rx1 = _x + pad_x;
        var rx2 = _x + w - pad_x;
        var ry1 = row_y;
        var ry2 = row_y + row_h;

        var is_hovered = point_in_rectangle(mx, my, rx1, ry1, rx2, ry2);
        if (is_hovered) hovered_idx = i;

        // Per-row alpha (snappy)
        if (!is_array(global.context_menu.__row_a)) global.context_menu.__row_a = [];
        if (i >= array_length(global.context_menu.__row_a)) array_push(global.context_menu.__row_a, 0.80);

        var row_a    = global.context_menu.__row_a[i];
        var target_a = is_hovered ? 1.00 : 0.80;
        row_a = row_a + (target_a - row_a) * 0.45;
        global.context_menu.__row_a[i] = row_a;

        // Row back
        draw_set_alpha(row_a);
        draw_set_color(base_col);
        draw_roundrect(rx1, ry1, rx2, ry2, false);
        draw_set_alpha(1);

        // Label (hover → white)
        draw_set_color(is_hovered ? c_white : make_color_rgb(200,200,210));
        var tx = rx1 + label_pad;
        var ty = ry1 + row_h * 0.5; // middle of row
        draw_text(tx, ty, label);

        // Click on row
        if (is_hovered) {
            global.ui_mouse_block = true;
            if (mouse_check_button_pressed(mb_left)) {
                var action = opts[i].action;
                var src    = global.context_menu.source;

                if (action == "equip") {
                    var it = src.item_id;
                    var meta = variable_struct_get(global.item_data, it);
                    if (!is_undefined(meta) && string_lower(meta.category) == "equipment") {
                        equip_item(it);
                    }
                } else if (action == "sort") {
                    sort_inventory_category(src.category);
                } else if (action == "sell") {
                    open_sell_dialog(src.item_id);
                }

                close_context_menu();
                draw_set_halign(prev_h);
                draw_set_valign(prev_v);
                return true;
            }
        }

        row_y += row_h + row_gap;
    }

    // Hover SFX once on enter (no function_exists check)
    if (hovered_idx != -1 && hovered_idx != global.context_menu.__prev_hover) {
        if (audio_exists(sfx_hover)) audio_play_sound(sfx_hover, 0, false);
    }
    global.context_menu.__prev_hover = hovered_idx;

    // Click-away to close
    var inside_menu = point_in_rectangle(mx, my, _x, _y, _x + w, _y + total_h);
    if (!inside_menu && mouse_check_button_pressed(mb_left)) {
        close_context_menu();
        draw_set_halign(prev_h);
        draw_set_valign(prev_v);
        return true;
    }

    if (inside_menu) global.ui_mouse_block = true;

    // restore alignment state
    draw_set_halign(prev_h);
    draw_set_valign(prev_v);

    return false;
}

