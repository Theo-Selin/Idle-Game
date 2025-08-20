/// open_context_menu(_x, _y, _options_array, _category, _index, _item_id)
function open_context_menu(_x, _y, _options_array, _category, _index, _item_id) {
    if (!variable_struct_exists(global, "context_menu")) {
        global.context_menu = { is_open:false, x:0, y:0, options:[], source:{category:"", index:-1, item_id:""} };
    }
    global.context_menu.is_open = true;
    global.context_menu.x = _x;
    global.context_menu.y = _y;
    global.context_menu.options = _options_array;
    global.context_menu.source = { category: _category, index: _index, item_id: _item_id };
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
    var _x = global.context_menu.x;
    var _y = global.context_menu.y;

    var row_h = 28;
    var w = 132;

    // Draw rows
    for (var i = 0; i < array_length(opts); i++) {
        var by = _y + i * (row_h + 4);
        draw_sprite_stretched(spr_ui_button, 0, _x, by, w, row_h);
        var label = opts[i].label;
        var tw = string_width(label);
        var th = string_height(label);
        draw_set_color(c_white);
        draw_text(_x + (w - tw)/2, by + (row_h - th)/2, label);

        var hovered = point_in_rectangle(mx, my, _x, by, _x + w, by + row_h);
        if (hovered) {
            global.ui_mouse_block = true;
            if (mouse_check_button_pressed(mb_left)) {
                var action = opts[i].action;
                var src = global.context_menu.source;

                if (action == "equip") {
                    var it = src.item_id;
                    var meta = variable_struct_get(global.item_data, it);
                    if (!is_undefined(meta) && string_lower(meta.category) == "equipment") {
                        equip_item(it);
                    }
                } else if (action == "sort") {
                    sort_inventory_category(src.category);
				} else if (action == "sell") {
				    open_sell_dialog(src.item_id); // ✅ open slider modal
				}

                close_context_menu();
                return true;
            }
        }
    }

    // Click-away to close
    var total_h = array_length(opts) * (row_h + 4);
    var inside = point_in_rectangle(mx, my, _x, _y, _x + w, _y + total_h);
    if (!inside && mouse_check_button_pressed(mb_left)) {
        close_context_menu();
        return true;
    }

    // While open, block UI so grid doesn’t also react
    if (inside) global.ui_mouse_block = true;
    return false;
}
