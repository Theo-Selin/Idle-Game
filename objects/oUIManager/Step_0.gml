/// oUIManager.Step

// Reset mouse block at start
global.ui_mouse_block = false;

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// Reset one-frame tooltip buffers; draw happens in UIManager.Draw at the end
global.tooltip_item_id = undefined;
global.tooltip_text    = undefined; // keep undefined when nothing requested this frame
global.tooltip_sell_bronze = undefined;

// --- Safety init for offline modal fields (in case Create missed it)
if (!variable_instance_exists(id, "offline_visible"))    offline_visible    = (variable_global_exists("offline_report_ready") ? global.offline_report_ready : false);
if (!variable_instance_exists(id, "offline_alpha_bg"))   offline_alpha_bg   = 0;
if (!variable_instance_exists(id, "offline_alpha_card")) offline_alpha_card = 0;
if (!variable_instance_exists(id, "offline_closing"))    offline_closing    = false;

// ====== OFFLINE MODAL HANDLING ======
if (offline_visible) {
    // Fade in/out
    var sp = 0.12;
    if (!offline_closing) {
        offline_alpha_bg   = clamp(offline_alpha_bg + sp, 0, 0.65);
        offline_alpha_card = clamp(offline_alpha_card + sp, 0, 1);
    } else {
        offline_alpha_bg   = clamp(offline_alpha_bg - sp, 0, 0.65);
        offline_alpha_card = clamp(offline_alpha_card - sp, 0, 1);
        if (offline_alpha_card <= 0.01) {
            offline_visible = false;
            global.offline_report_ready = false;
        }
    }

    // Block gameplay/UI clicks while modal is up
    global.ui_mouse_block = true;

    // Close on tap/click or Esc/Enter
    if (mouse_check_button_pressed(mb_left) || keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_enter)) {
        offline_closing = true;
    }
}

// ====== Only process toggle & tabs when no modal is visible ======
if (!offline_visible) {
    // Toggle button check
    if (point_in_rectangle(mx, my, toggle_button_rect[0], toggle_button_rect[1], toggle_button_rect[2], toggle_button_rect[3])) {
        global.ui_mouse_block = true; // block passthrough
        if (mouse_check_button_pressed(mb_left)) {
            ui_visible = !ui_visible;
        }
    }

    // === Tab switching ===
    if (ui_visible) {
        for (var i = 0; i < array_length(ui_tabs); i++) {
            var label = string_upper(ui_tabs[i]);
            var y_pos = tab_y + i * tab_spacing;
            var w = string_width(label);
            var h = string_height(label);
            var bx1 = tab_x;
            var by1 = y_pos;
            var bx2 = bx1 + w + 8;
            var by2 = by1 + h;

            if (point_in_rectangle(mx, my, bx1, by1, bx2, by2)) {
                if (mouse_check_button_pressed(mb_left)) {
                    active_tab = ui_tabs[i];
                }
            }
        }
    }
	// --- Auto Combat toggle button ---
	if (point_in_rectangle(mx, my, auto_btn_rect[0], auto_btn_rect[1], auto_btn_rect[2], auto_btn_rect[3])) {
	    global.ui_mouse_block = true;
	    if (mouse_check_button_pressed(mb_left)) {
	        global.auto_combat_enabled = !global.auto_combat_enabled;
	    }
	}

}

// --- Toast aging ---
if (array_length(toasts) > 0) {
    // Age and cull expired (iterate backwards for safe delete)
    for (var i = array_length(toasts) - 1; i >= 0; i--) {
        var t = toasts[i];
        t.age += 1;
        if (t.age >= t.ttl) {
            array_delete(toasts, i, 1);
        } else {
            toasts[i] = t; // write back (struct is by value in arrays)
        }
    }
}

// ====== CRAFTING (can keep progressing even if modal is up) ======
if (global.crafting_in_progress) {
    var progress_speed = 0.007; // 📈 Tune this as needed
    global.crafting_progress += progress_speed;

    if (global.crafting_progress >= 1) {
        global.crafting_progress = 0;
        global.crafting_in_progress = false;
        do_craft(global.crafting_recipe);
        global.crafting_recipe = undefined;
    }
}
