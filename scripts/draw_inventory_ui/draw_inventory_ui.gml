function draw_inventory_ui(x1, y1, w, h) {
    // === SETTINGS ===
    var section_spacing = 16;
    var cat_tab_h = 38;
    var cat_tab_spacing = 24;
    var grid_padding = 8;
    var grid_max_rows = 4;

    // Input tuning
    var DRAG_DEADZONE = 6;       // px before we consider it a drag
    var LONGPRESS_STEPS = 12;    // frames to trigger long-press open

    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    // Safe flags (avoid reading undefined globals)
    var context_open    = variable_struct_exists(global, "context_menu") && global.context_menu.is_open;
    var inv_drag_active = variable_struct_exists(global, "inv_drag") && global.inv_drag.active;

    // Ensure press state exists
    if (!variable_struct_exists(global, "inv_press")) {
        global.inv_press = { active:false, category:"", index:-1, item_id:"",
                             start_x:0, start_y:0, timer:0, opened_menu:false };
    }

    // === AREAS ===
    var tab_area_y = y1;
    var tab_area_h = cat_tab_h + 4;

    var grid_area_y = tab_area_y + tab_area_h + section_spacing;
    var grid_area_h = floor(h * 0.4);

    var bottom_area_y = grid_area_y + grid_area_h + section_spacing * 3;
    var bottom_area_h = h - (tab_area_h + grid_area_h + section_spacing * 3);

    var equipped_w = floor((w - section_spacing) / 1.415);
    var stats_w = w - equipped_w - section_spacing;

    var usable_w = w - grid_padding * 2;

    // === 1️⃣ CATEGORY TABS ===
    var item_categories = ["Equipment", "Gatherables", "Materials"];
    var current_category = global.current_inventory_category;

    // --- SFX for category tabs (match side tabs behavior) ---
    var sfx_hover_tabs = snd_ui_hover;
    var sfx_tab_click  = snd_tab_click;
    if (!variable_instance_exists(id, "__invcat_prev_hover")) __invcat_prev_hover = -1;
    var hovered_cat_idx = -1;

    var total_tab_width = 0;
    var label_widths = [];
    for (var i = 0; i < array_length(item_categories); i++) {
        var label = string_upper(item_categories[i]);
        var lw = string_width(label);
        label_widths[i] = lw;
        total_tab_width += lw + (i < array_length(item_categories) - 1 ? cat_tab_spacing : 0);
    }

    var tabs_start_x = x1 + (w - total_tab_width) / 2;
    var draw_x = tabs_start_x;

    for (var i = 0; i < array_length(item_categories); i++) {
        var label = string_upper(item_categories[i]);
        var is_selected = (current_category == item_categories[i]);

        var label_h = string_height(label);
        var label_y = tab_area_y + (cat_tab_h - label_h) / 2;

        var text_w = label_widths[i];
        var bx1 = draw_x, by1 = tab_area_y;
        var bx2 = draw_x + text_w + 6, by2 = by1 + cat_tab_h;

        var is_hovered = point_in_rectangle(mx, my, bx1, by1, bx2, by2);
        if (is_hovered) { hovered_cat_idx = i; global.ui_mouse_block = true; }

        // Color: hover → white, active → white, else dim gray
        draw_set_color((is_selected || is_hovered) ? c_white : make_color_rgb(160,160,160));
        draw_text(draw_x, label_y, label);

        // Click to activate (play click sound only if switching)
        if (is_hovered && mouse_check_button_pressed(mb_left)) {
            if (item_categories[i] != current_category) {
                global.current_inventory_category = item_categories[i];
                current_category = item_categories[i];
                if (audio_exists(sfx_tab_click)) play_impact_sound(sfx_tab_click, 1, 1.5, 2);
            }
        }

        draw_x += text_w + cat_tab_spacing;
    }

    // Play hover SFX once when entering a new (non-active) category tab
    if (hovered_cat_idx != -1 && hovered_cat_idx != __invcat_prev_hover) {
        if (item_categories[hovered_cat_idx] != current_category) {
            if (audio_exists(sfx_hover_tabs)) play_impact_sound(sfx_hover_tabs, 0.2, 1.5, 1.5);
        }
    }
    __invcat_prev_hover = hovered_cat_idx;

    // === 2️⃣ FILTER + ORDER (persisted) ===
    var filtered_inventory = []; // [{id, amount}]
    var names = variable_struct_get_names(global.item_data); // all known item ids

    for (var i = 0; i < array_length(names); i++) {
        var item_id = names[i];
        var item = variable_struct_get(global.item_data, item_id);

        // ✅ don't list currency items in the grid
        if (string_lower(item.category) == "currency") continue;

        if (string_lower(item.category) != string_lower(current_category)) continue;

        var amount = inventory_count(item_id);
        if (amount > 0) array_push(filtered_inventory, { id: item_id, amount: amount });
    }

    // Build a quick lookup of counts (id -> amount)
    var count_lookup = {};
    for (var i = 0; i < array_length(filtered_inventory); i++) {
        variable_struct_set(count_lookup, filtered_inventory[i].id, filtered_inventory[i].amount);
    }

    // Ensure and fetch the category order array
    var ordered_ids = ensure_inventory_order(current_category);

    // Make a view array using order (skip ids with 0 amount just in case)
    var inventory_view = []; // [{id, amount}]
    for (var i = 0; i < array_length(ordered_ids); i++) {
        var vid = ordered_ids[i];
        var amt = variable_struct_get(count_lookup, vid);
        if (!is_undefined(amt) && amt > 0) array_push(inventory_view, { id: vid, amount: amt });
    }

    // === 3️⃣ INVENTORY GRID (drag & drop + context menu) ===
    var cols = max(1, floor(usable_w / (item_slot_size + item_slot_margin)));
    var total_slots = cols * grid_max_rows;

    var grid_total_w = cols * (item_slot_size + item_slot_margin) - item_slot_margin;
    var grid_total_h = grid_max_rows * (item_slot_size + item_slot_margin) - item_slot_margin;

    var grid_x = x1 + (w - grid_total_w) / 2;
    var grid_y = grid_area_y + (grid_area_h - grid_total_h) / 2;

    var mouse_handled = false;

    // === A) Desktop right-click opens context menu instantly (no drag) ===
    if (!context_open && mouse_check_button_pressed(mb_right)) {
        for (var i = 0; i < total_slots; i++) {
            var col = i mod cols, row = i div cols;
            var sx = grid_x + col * (item_slot_size + item_slot_margin);
            var sy = grid_y + row * (item_slot_size + item_slot_margin);
            if (point_in_rectangle(mx, my, sx, sy, sx + item_slot_size, sy + item_slot_size)) {
                if (i < array_length(inventory_view)) {
                    var slot = inventory_view[i];
                    var meta = variable_struct_get(global.item_data, slot.id);
                    var opts = [];
                    if (string_lower(meta.category) == "equipment") array_push(opts, {label:"Equip", action:"equip"});
                    array_push(opts, {label:"Sort", action:"sort"});
                    array_push(opts, {label:"Sell", action:"sell"});
                    open_context_menu(mx + 8, my + 8, opts, current_category, i, slot.id);
                }
                break;
            }
        }
    }

    // === B) Left press logic (drag vs long-press/tap) ===
    if (!context_open && !inv_drag_active && mouse_check_button_pressed(mb_left)) {
        for (var i = 0; i < total_slots; i++) {
            var col = i mod cols, row = i div cols;
            var sx = grid_x + col * (item_slot_size + item_slot_margin);
            var sy = grid_y + row * (item_slot_size + item_slot_margin);
            if (point_in_rectangle(mx, my, sx, sy, sx + item_slot_size, sy + item_slot_size)) {
                if (i < array_length(inventory_view)) {
                    var s = inventory_view[i];
                    global.inv_press.active = true;
                    global.inv_press.category = current_category;
                    global.inv_press.index = i;
                    global.inv_press.item_id = s.id;
                    global.inv_press.start_x = mx;
                    global.inv_press.start_y = my;
                    global.inv_press.timer = 0;
                    global.inv_press.opened_menu = false;
                }
                break;
            }
        }
    }

    if (global.inv_press.active && mouse_check_button(mb_left) && !context_open && !inv_drag_active) {
        global.inv_press.timer += 1;
        var dx = mx - global.inv_press.start_x;
        var dy = my - global.inv_press.start_y;
        var moved = (abs(dx) > DRAG_DEADZONE) || (abs(dy) > DRAG_DEADZONE);

        if (moved) {
            if (!variable_struct_exists(global, "inv_drag")) {
                global.inv_drag = { active:false, category:"", from_index:-1, item_id:"", offset_x:0, offset_y:0 };
            }
            var i = global.inv_press.index;
            var col = i mod cols, row = i div cols;
            var slot_x = grid_x + col * (item_slot_size + item_slot_margin);
            var slot_y = grid_y + row * (item_slot_size + item_slot_margin);

            global.inv_drag.active = true;
            global.inv_drag.category = global.inv_press.category;
            global.inv_drag.from_index = global.inv_press.index;
            global.inv_drag.item_id = global.inv_press.item_id;
			global.inv_drag.offset_x = global.inv_press.start_x - (slot_x + item_slot_size/2);
			global.inv_drag.offset_y = global.inv_press.start_y - (slot_y + item_slot_size/2);


            inv_drag_active = true;
            global.inv_press.active = false;
        }
        else if (global.inv_press.timer >= LONGPRESS_STEPS && !global.inv_press.opened_menu) {
            var meta = variable_struct_get(global.item_data, global.inv_press.item_id);
            var opts = [];
            if (string_lower(meta.category) == "equipment") array_push(opts, {label:"Equip", action:"equip"});
            array_push(opts, {label:"Sort", action:"sort"});
            array_push(opts, {label:"Sell", action:"sell"});
            open_context_menu(mx + 8, my + 8, opts, global.inv_press.category, global.inv_press.index, global.inv_press.item_id);
            global.inv_press.opened_menu = true;
            global.inv_press.active = false;
        }
    }

    if (global.inv_press.active && mouse_check_button_released(mb_left) && !context_open && !inv_drag_active) {
        var meta = variable_struct_get(global.item_data, global.inv_press.item_id);
        var opts = [];
        if (string_lower(meta.category) == "equipment") array_push(opts, {label:"Equip", action:"equip"});
        array_push(opts, {label:"Sort", action:"sort"});
        array_push(opts, {label:"Sell", action:"sell"});
        open_context_menu(mx + 8, my + 8, opts, global.inv_press.category, global.inv_press.index, global.inv_press.item_id);
        global.inv_press.active = false;
    }

    // Draw slots + contents (with dragged hiding)
    for (var i = 0; i < total_slots; i++) {
        var col = i mod cols;
        var row = i div cols;

        var slot_x = grid_x + col * (item_slot_size + item_slot_margin);
        var slot_y = grid_y + row * (item_slot_size + item_slot_margin);

        draw_sprite(spr_inventory_slot, 0, slot_x, slot_y);

        if (i < array_length(inventory_view)) {
            var slot = inventory_view[i];
            var item_id = slot.id;
            var amount = slot.amount;

            var is_dragged =
                inv_drag_active &&
                variable_struct_exists(global, "inv_drag") &&
                (global.inv_drag.category == current_category) &&
                (global.inv_drag.from_index == i);

            var item = variable_struct_get(global.item_data, item_id);
            if (!is_undefined(item.icon)) {
                if (!is_dragged) {
                    draw_sprite(item.icon, 0, slot_x + item_slot_size div 2, slot_y + item_slot_size div 2);
                }
            }

            if (!is_dragged) {
                var amount_text = string(amount);
                var text_x = slot_x + item_slot_size - 2 - string_width(amount_text);
                var text_y = slot_y + item_slot_size - 14;
                draw_set_color(c_white);
                draw_text(text_x, text_y, amount_text);
            }

            var hovered = point_in_rectangle(mx, my, slot_x, slot_y, slot_x + item_slot_size, slot_y + item_slot_size);
            if (hovered) {
                global.ui_mouse_block = true;
                global.tooltip_item_id = item_id;
                global.tooltip_x = mx + 12;
                global.tooltip_y = my + 12;
                global.tooltip_sell_bronze = inv_get_sell_price_bronze(item_id);
            }
        }
    }

    // Drop handling (swap)
    if (inv_drag_active && mouse_check_button_released(mb_left)) {
        var from_idx = global.inv_drag.from_index;
        var drop_idx = -1;
        for (var i = 0; i < total_slots; i++) {
            var col = i mod cols;
            var row = i div cols;
            var slot_x = grid_x + col * (item_slot_size + item_slot_margin);
            var slot_y = grid_y + row * (item_slot_size + item_slot_margin);
            if (point_in_rectangle(mx, my, slot_x, slot_y, slot_x + item_slot_size, slot_y + item_slot_size)) {
                drop_idx = i; break;
            }
        }
        if (drop_idx >= 0 && drop_idx < array_length(inventory_view)) {
            inventory_swap_positions(current_category, from_idx, drop_idx);
        }
        global.inv_drag.active = false;
        global.inv_drag.category = "";
        global.inv_drag.from_index = -1;
        global.inv_drag.item_id = "";
        inv_drag_active = false;
    }

    // Draw dragged icon + amount
    if (inv_drag_active) {
        var drag_id = global.inv_drag.item_id;
        var meta = variable_struct_get(global.item_data, drag_id);
        if (!is_undefined(meta) && !is_undefined(meta.icon)) {
            var cx = mx - global.inv_drag.offset_x;
            var cy = my - global.inv_drag.offset_y;
            draw_sprite(meta.icon, 0, cx, cy);

            var amt = inventory_count(drag_id);
            if (amt > 0) {
                var amount_text = string(amt);
                var drag_slot_x = cx - item_slot_size div 2;
                var drag_slot_y = cy - item_slot_size div 2;
                var text_x = drag_slot_x + item_slot_size - 2 - string_width(amount_text);
                var text_y = drag_slot_y + item_slot_size - 14;
                draw_set_color(c_black);
                draw_text(text_x + 1, text_y + 1, amount_text);
                draw_set_color(c_white);
                draw_text(text_x, text_y, amount_text);
            }
        }
    }

    // === 4️⃣ EQUIPPED + STATS PANELS ===
    var group_total_w = equipped_w + stats_w + section_spacing;
    var group_x = x1 + (w - group_total_w) / 2;

    // Draw equipment slots (left side)
    var slot_margin = 12;
    var sx_base = group_x + equipped_w div 2 - item_slot_size div 2;
    var sy_base = bottom_area_y + slot_margin;
    var slot_names = ["helmet", "armor", "weapon", "amulet", "ring_1", "ring_2", "health"];

    for (var i = 0; i < array_length(slot_names); i++) {
        var slot_type = slot_names[i];

        // --- 3-rows-per-column layout ---
        var row = i mod 3;                // 0..2 (vertical)
        var col = i div 3;                // 0,1,2... (horizontal)
        var sx  = sx_base + col * (item_slot_size + slot_margin);
        var sy  = sy_base + row * (item_slot_size + slot_margin);

        // slot background
        draw_sprite(spr_inventory_slot, 0, sx, sy);

        // equipped item
        var equipped_item_id = variable_struct_get(global.save.equipment, slot_type);
        if (!is_undefined(equipped_item_id)) {
            var eq_item = variable_struct_get(global.item_data, equipped_item_id);
            if (!is_undefined(eq_item.icon)) {
                // center icon inside slot (assuming icon origin is 0,0)
                draw_sprite(eq_item.icon, 0, sx + item_slot_size div 2, sy + item_slot_size div 2);
            }

            var hovered_slot = point_in_rectangle(mx, my, sx, sy, sx + item_slot_size, sy + item_slot_size);
            if (hovered_slot) {
                global.ui_mouse_block = true;
                global.tooltip_item_id = equipped_item_id;
                global.tooltip_x = mx + 12;
                global.tooltip_y = my + 12;
                global.tooltip_sell_bronze = inv_get_sell_price_bronze(equipped_item_id);

                if (mouse_check_button_pressed(mb_left)) {
                    unequip_slot(slot_type);
                }
            }
        } else {
            // empty slot hover
            if (point_in_rectangle(mx, my, sx, sy, sx + item_slot_size, sy + item_slot_size)) {
                global.ui_mouse_block = true;
                global.tooltip_text = string_upper(slot_type);
                global.tooltip_x = mx + 12;
                global.tooltip_y = my + 12;
                // No item -> no sell price (avoid calling with undefined)
                global.tooltip_sell_bronze = 0;
            }
        }
    }

    // === Context Menu (draw + input) ===
    if (draw_context_menu_and_handle_input()) {
        // consumed click
    }

    // === Sell dialog (draw + input)
    if (draw_sell_dialog_and_handle_input()) {
        // modal consumes input
    }
}
