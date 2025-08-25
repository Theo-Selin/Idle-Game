function draw_crafting_ui(x1, y1, w, h) {
    // === SETTINGS ===
    var section_spacing = 16;
    var grid_padding = 8;
    var grid_max_rows = 3;

    var cat_tab_h = 38;
    var cat_tab_spacing = 24;
    var item_categories = ["Weapons", "Armors", "Processing"];
    var current_category = global.current_craft_category;

    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    // === CALCULATED AREAS ===
    var tab_area_y    = y1;
    var tab_area_h    = cat_tab_h + 4;
    var grid_area_y   = tab_area_y + tab_area_h + section_spacing;
    var grid_area_h   = floor(h * 0.45);
    var bottom_area_y = grid_area_y + grid_area_h + section_spacing;
    var bottom_area_h = h - (cat_tab_h + grid_area_h + section_spacing * 3);

    var equipped_w = floor((w - section_spacing) / 1.415);
    var stats_w    = w - equipped_w - section_spacing;
    var usable_w   = w - grid_padding * 2;

    // === CATEGORY TABS (hover + click SFX) ===
    var sfx_hover_tabs = snd_ui_hover;
    var sfx_tab_click  = snd_tab_click;
    if (!variable_instance_exists(id, "__craft_prev_hover")) __craft_prev_hover = -1;
    var hovered_tab_idx = -1;

    var total_tab_width = 0;
    var label_widths = [];
    for (var i = 0; i < array_length(item_categories); i++) {
        var label = string_upper(item_categories[i]);
        var label_w = string_width(label);
        label_widths[i] = label_w;
        total_tab_width += label_w + (i < array_length(item_categories) - 1 ? cat_tab_spacing : 0);
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
        if (is_hovered) { hovered_tab_idx = i; global.ui_mouse_block = true; }

        draw_set_color((is_selected || is_hovered) ? c_white : make_color_rgb(160,160,160));
        draw_text(draw_x, label_y, label);

        if (is_hovered && mouse_check_button_pressed(mb_left)) {
            if (item_categories[i] != current_category) {
                global.current_craft_category = item_categories[i];
                current_category = item_categories[i];
                if (audio_exists(sfx_tab_click)) play_impact_sound(sfx_tab_click, 1, 1.5, 2);
            }
        }
        draw_x += text_w + cat_tab_spacing;
    }

    if (hovered_tab_idx != -1 && hovered_tab_idx != __craft_prev_hover) {
        if (item_categories[hovered_tab_idx] != current_category) {
            if (audio_exists(sfx_hover_tabs)) play_impact_sound(sfx_hover_tabs, 0.2, 1.5, 1.5);
        }
    }
    __craft_prev_hover = hovered_tab_idx;

    // === 1️⃣ CRAFTING GRID ===
    var recipes_all = global.crafting_recipes;
    var recipes = [];
    for (var i = 0; i < array_length(recipes_all); i++) {
        var r = recipes_all[i];
        if (r.category == global.current_craft_category) array_push(recipes, r);
    }

    var total_slots = array_length(recipes);
    var cols = max(1, floor(usable_w / (item_slot_size + item_slot_margin)));
    var rows = grid_max_rows;

    var grid_total_w = cols * (item_slot_size + item_slot_margin) - item_slot_margin;
    var grid_total_h = rows * (item_slot_size + item_slot_margin) - item_slot_margin;

    var grid_x = x1 + (w - grid_total_w) / 2;
    var grid_y = grid_area_y + (grid_area_h - grid_total_h) / 2;

    for (var i = 0; i < cols * rows; i++) {
        var col = i mod cols;
        var row = i div cols;

        var slot_x = grid_x + col * (item_slot_size + item_slot_margin);
        var slot_y = grid_y + row * (item_slot_size + item_slot_margin);

        draw_sprite(spr_inventory_slot, 0, slot_x, slot_y);

        if (i < total_slots) {
            var recipe = recipes[i];
            var icon = sprite_get_index(recipe.icon_name);
            if (icon != -1) {
                draw_sprite(icon, 0, slot_x + item_slot_size div 2, slot_y + item_slot_size div 2);
            }

            if (point_in_rectangle(mx, my, slot_x, slot_y, slot_x + item_slot_size, slot_y + item_slot_size)) {
                global.ui_mouse_block = true;

                if (mouse_check_button_pressed(mb_left)) {
                    global.selected_recipe_index = i;
                }

                var out_id = string(recipe.output.id);
                if (variable_struct_exists(global.item_data, out_id)) {
                    global.tooltip_item_id = out_id;
                    global.tooltip_x = mx + 12;
                    global.tooltip_y = my + 12;
                }
            }
        }
    }

    // === 2️⃣ INGREDIENTS PANEL ===
    var group_total_w = equipped_w + stats_w + section_spacing;
    var group_x = x1 + (w - group_total_w) / 2;
    var ingredients_x = group_x + 24;
    var ingredients_y = bottom_area_y + 24;

    draw_set_color(c_white);
    draw_text(ingredients_x + 8, ingredients_y - 8, "Required:");

    if (global.selected_recipe_index >= 0 && global.selected_recipe_index < array_length(recipes)) {
        var selected_recipe = recipes[global.selected_recipe_index];
        var entry_spacing = 40;
        var icon_size = 32;
        var icon_x = ingredients_x + 12;
        var text_x = icon_x + icon_size + 8;

        for (var i = 0; i < array_length(selected_recipe.input); i++) {
            var req = selected_recipe.input[i];
            var in_id = string(req.id);
            var needed = req.amount;

            if (variable_struct_exists(global.item_data, in_id)) {
                var item = variable_struct_get(global.item_data, in_id);
                var icon = item.icon;
                var have = inventory_count(in_id);
                var entry_y = ingredients_y + 32 + i * entry_spacing;

                if (!is_undefined(icon)) {
                    draw_sprite(icon, 0, icon_x + icon_size / 2, entry_y + icon_size / 2);
                }

                var text = item.name + ": " + string(have) + " / " + string(needed);
                draw_text(text_x, entry_y + 8, text);

                if (point_in_rectangle(mx, my, icon_x, entry_y, icon_x + icon_size, entry_y + icon_size)) {
                    global.ui_mouse_block = true;
                    global.tooltip_item_id = in_id;
                    global.tooltip_x = mx + 12;
                    global.tooltip_y = my + 12;
                }
            }
        }
    }

    // === 3️⃣ CRAFTING PANEL ===
    var action_x = group_x + equipped_w + section_spacing;
    var action_y = bottom_area_y;
    var progress = clamp(global.crafting_progress, 0, 1);
    var bar_w = stats_w - 32;
    var bar_h = 8;
    var bar_x = action_x + 16;
    var bar_y = action_y + 40;

    draw_set_color(c_white);
    draw_text(bar_x, bar_y - 18, "Progress:");
    draw_set_color(make_color_rgb(40, 40, 40));
    draw_rectangle(bar_x - 1, bar_y - 1, bar_x + bar_w + 1, bar_y + bar_h + 1, false);
    draw_set_color(make_color_rgb(80, 80, 80));
    draw_rectangle(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, false);

    var interp_color = progress < 0.5
        ? merge_color(c_red, c_yellow, progress * 2)
        : merge_color(c_yellow, c_lime, (progress - 0.5) * 2);

    draw_set_color(interp_color);
    draw_rectangle(bar_x, bar_y, bar_x + (bar_w * progress), bar_y + bar_h, false);

    // ---------- CRAFT BUTTON (alpha hover + SFX like upgrade buttons) ----------
    var btn_w = 208;
    var btn_h = 29;
    var btn_x = action_x;
    var btn_y = bar_y + 40;

    // SFX & state
    var sfx_hover_btn = snd_ui_hover;
    var sfx_click_btn = snd_upgrade_click; // reuse click SFX used by upgrade
    if (!variable_instance_exists(id, "__craft_btn_alpha")) __craft_btn_alpha = 0.80;
    if (!variable_instance_exists(id, "__craft_btn_hover_prev")) __craft_btn_hover_prev = false;

    var selected_recipe = undefined;
    var can_craft_now = false;
    var is_disabled = true;

    if (global.selected_recipe_index >= 0 && global.selected_recipe_index < array_length(recipes)) {
        selected_recipe = recipes[global.selected_recipe_index];
        can_craft_now = can_craft(selected_recipe);
        is_disabled = !can_craft_now || global.crafting_in_progress;
    }

    var hovering_btn = point_in_rectangle(mx, my, btn_x, btn_y, btn_x + btn_w, btn_y + btn_h);
    if (hovering_btn) global.ui_mouse_block = true;

    // Alpha model (match upgrade buttons)
    var ALPHA_BASE     = 0.80;
    var ALPHA_HOVER    = 1.00;
    var ALPHA_DISABLED = 0.55;
    var HOVER_SNAP     = 0.60; // snappy

    var target_a = is_disabled ? ALPHA_DISABLED : (hovering_btn ? ALPHA_HOVER : ALPHA_BASE);
    __craft_btn_alpha = __craft_btn_alpha * (1 - HOVER_SNAP) + target_a * HOVER_SNAP;

    // Hover SFX once-on-enter (only when clickable)
    if (hovering_btn && !is_disabled && !__craft_btn_hover_prev) {
        if (audio_exists(sfx_hover_btn)) play_impact_sound(sfx_hover_btn, 0.2, 1.5, 1.6);
    }
    __craft_btn_hover_prev = hovering_btn && !is_disabled;

    // Draw button with alpha (no color-tinting)
    draw_set_alpha(__craft_btn_alpha);
    draw_set_color(c_white);
    draw_sprite(spr_ui_button, 0, btn_x, btn_y);
    draw_set_alpha(1);

    // Label (white when enabled, dim when disabled)
    var btn_text = "CRAFT";
    var text_x = btn_x + (btn_w - string_width(btn_text)) / 2;
    var text_y = btn_y + (btn_h - string_height(btn_text)) / 2;
    draw_set_color(is_disabled ? make_color_rgb(180,180,180) : c_white);
    draw_text(text_x, text_y, btn_text);

    // Click -> start crafting (and click SFX)
    if (!is_undefined(selected_recipe) && hovering_btn && !is_disabled && mouse_check_button_pressed(mb_left)) {
        if (audio_exists(sfx_click_btn)) audio_play_sound(sfx_click_btn, 0, false);
        start_crafting(selected_recipe);
    }
    // ---------------------------------------------------------------------------

    // ❌ Tooltip drawing stays centralized in oUIManager.Draw
}
