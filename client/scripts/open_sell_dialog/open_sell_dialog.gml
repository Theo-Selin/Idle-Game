/// open_sell_dialog(_item_key)
function open_sell_dialog(_item_key) {
    var max_amt = inventory_count(_item_key);
    if (max_amt <= 0) return;

    if (!variable_struct_exists(global, "sell_dialog")) global.sell_dialog = {};
    var price = inv_get_sell_price_bronze(_item_key);

    variable_struct_set(global.sell_dialog, "is_open", true);
    variable_struct_set(global.sell_dialog, "item_key", _item_key);
    variable_struct_set(global.sell_dialog, "price_bronze", price);
    variable_struct_set(global.sell_dialog, "max_amount", max_amt);
    variable_struct_set(global.sell_dialog, "amount", 1);
    variable_struct_set(global.sell_dialog, "dragging", false);

    // Prevent click-through from the context menu press
    variable_struct_set(global.sell_dialog, "block_until_release", true);

    // Close context menu just in case
    if (variable_struct_exists(global, "context_menu")) global.context_menu.is_open = false;
}

function close_sell_dialog() {
    if (!variable_struct_exists(global, "sell_dialog")) return;
    global.sell_dialog.is_open = false;
}

/// draw_sell_dialog_and_handle_input() → bool (consumes input)
function draw_sell_dialog_and_handle_input() {
    if (!variable_struct_exists(global, "sell_dialog")) return false;
    if (!global.sell_dialog.is_open) return false;

    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    var gui_w = display_get_gui_width();
    var gui_h = display_get_gui_height();

    var W = 320, H = 170;
    var X = (gui_w - W) * 0.5;
    var Y = (gui_h - H) * 0.5;

    // Panel background
    var spr_panel = sprite_get_index("spr_ui_panel_medium");
    if (spr_panel != -1) {
        draw_sprite_stretched(spr_panel, 0, X, Y, W, H);
    } else {
        draw_set_color(make_color_rgb(20,20,20));
        draw_rectangle(X, Y, X+W, Y+H, false);
        draw_set_color(make_color_rgb(60,60,60));
        draw_rectangle(X+1, Y+1, X+W-1, Y+H-1, true);
    }

    // Safe reads
    var item_key    = string(variable_struct_get(global.sell_dialog, "item_key"));
    var price_each  = max(0, floor(variable_struct_get(global.sell_dialog, "price_bronze")));
    var max_amount  = max(1, floor(variable_struct_get(global.sell_dialog, "max_amount")));
    var amount      = clamp(max(1, floor(variable_struct_get(global.sell_dialog, "amount"))), 1, max_amount);
    var dragging    = (variable_struct_get(global.sell_dialog, "dragging") == true);
    var gated       = (variable_struct_get(global.sell_dialog, "block_until_release") == true);

    draw_set_color(c_white);
    draw_text(X + 12, Y + 10, "Sell " + item_key);

    // Currency sprites
    var spr_gold   = sprite_get_index("spr_coin_gold");
    var spr_silver = sprite_get_index("spr_coin_silver");
    var spr_bronze = sprite_get_index("spr_coin_copper");

    // Layout for coin rows
    var ICON_H    = 14;
    var TEXT_GAP  = 5;
    var BLOCK_GAP = 12;
    var th        = string_height("0");

    // Amount readout (right, inside panel)
    var amt_str = string(amount) + " / " + string(max_amount);
    draw_text(X + W - 12 - string_width(amt_str), Y + 36, amt_str);

    // Convert bronze → (g,s,b)
    var each_b  = price_each;
    var total_b = price_each * amount;

    var e_g = each_b div 1000000;
    var e_r = each_b mod 1000000;
    var e_s = e_r div 1000;
    var e_b = e_r mod 1000;

    var t_g = total_b div 1000000;
    var t_r = total_b mod 1000000;
    var t_s = t_r div 1000;
    var t_b = t_r mod 1000;

    // ---------- Each row (show ONLY non-zero denominations) ----------
    var label1 = "Each:";
    var l1x    = X + 12;
    var l1top  = Y + 32;
    var l1ty   = l1top + max(0, (ICON_H - th) div 2);

    draw_text(l1x, l1ty, label1);
    var xcur = l1x + string_width(label1) + 8;

    var sw, sh, sc, sws, tx, t;

    // GOLD (only if > 0)
    if (e_g > 0) {
        if (spr_gold != -1) {
            sw  = sprite_get_width(spr_gold);
            sh  = max(1, sprite_get_height(spr_gold));
            sc  = ICON_H / sh;
            sws = sw * sc;
            draw_sprite_ext(spr_gold, 0, xcur + sws * 0.5, l1top + ICON_H * 0.5, sc, sc, 0, c_white, 1);
            tx = xcur + sws + TEXT_GAP;
            draw_text(tx, l1ty, string(e_g));
            xcur = tx + string_width(string(e_g)) + BLOCK_GAP;
        } else {
            t = "G:" + string(e_g);
            draw_text(xcur, l1ty, t);
            xcur += string_width(t) + BLOCK_GAP;
        }
    }

    // SILVER (only if > 0)
    if (e_s > 0) {
        if (spr_silver != -1) {
            sw  = sprite_get_width(spr_silver);
            sh  = max(1, sprite_get_height(spr_silver));
            sc  = ICON_H / sh;
            sws = sw * sc;
            draw_sprite_ext(spr_silver, 0, xcur + sws * 0.5, l1top + ICON_H * 0.5, sc, sc, 0, c_white, 1);
            tx = xcur + sws + TEXT_GAP;
            draw_text(tx, l1ty, string(e_s));
            xcur = tx + string_width(string(e_s)) + BLOCK_GAP;
        } else {
            t = "S:" + string(e_s);
            draw_text(xcur, l1ty, t);
            xcur += string_width(t) + BLOCK_GAP;
        }
    }

    // BRONZE (always show; price is at least 1b if it's sellable)
    if (spr_bronze != -1) {
        sw  = sprite_get_width(spr_bronze);
        sh  = max(1, sprite_get_height(spr_bronze));
        sc  = ICON_H / sh;
        sws = sw * sc;
        draw_sprite_ext(spr_bronze, 0, xcur + sws * 0.5, l1top + ICON_H * 0.5, sc, sc, 0, c_white, 1);
        tx = xcur + sws + TEXT_GAP;
        draw_text(tx, l1ty, string(e_b));
        xcur = tx + string_width(string(e_b)) + BLOCK_GAP;
    } else {
        t = "B:" + string(e_b);
        draw_text(xcur, l1ty, t);
        xcur += string_width(t) + BLOCK_GAP;
    }

    // ---------- Total row (unchanged: shows all denominations) ----------
    var label2 = "Total:";
    var l2x    = X + 12;
    var l2top  = Y + 52;
    var l2ty   = l2top + max(0, (ICON_H - th) div 2);

    draw_text(l2x, l2ty, label2);
    xcur = l2x + string_width(label2) + 8;

    // GOLD
    if (spr_gold != -1) {
        sw  = sprite_get_width(spr_gold);
        sh  = max(1, sprite_get_height(spr_gold));
        sc  = ICON_H / sh;
        sws = sw * sc;
        draw_sprite_ext(spr_gold, 0, xcur + sws * 0.5, l2top + ICON_H * 0.5, sc, sc, 0, c_white, 1);
        tx = xcur + sws + TEXT_GAP;
        draw_text(tx, l2ty, string(t_g));
        xcur = tx + string_width(string(t_g)) + BLOCK_GAP;
    } else {
        t = "G:" + string(t_g);
        draw_text(xcur, l2ty, t);
        xcur += string_width(t) + BLOCK_GAP;
    }

    // SILVER
    if (spr_silver != -1) {
        sw  = sprite_get_width(spr_silver);
        sh  = max(1, sprite_get_height(spr_silver));
        sc  = ICON_H / sh;
        sws = sw * sc;
        draw_sprite_ext(spr_silver, 0, xcur + sws * 0.5, l2top + ICON_H * 0.5, sc, sc, 0, c_white, 1);
        tx = xcur + sws + TEXT_GAP;
        draw_text(tx, l2ty, string(t_s));
        xcur = tx + string_width(string(t_s)) + BLOCK_GAP;
    } else {
        t = "S:" + string(t_s);
        draw_text(xcur, l2ty, t);
        xcur += string_width(t) + BLOCK_GAP;
    }

    // BRONZE
    if (spr_bronze != -1) {
        sw  = sprite_get_width(spr_bronze);
        sh  = max(1, sprite_get_height(spr_bronze));
        sc  = ICON_H / sh;
        sws = sw * sc;
        draw_sprite_ext(spr_bronze, 0, xcur + sws * 0.5, l2top + ICON_H * 0.5, sc, sc, 0, c_white, 1);
        tx = xcur + sws + TEXT_GAP;
        draw_text(tx, l2ty, string(t_b));
        xcur = tx + string_width(string(t_b)) + BLOCK_GAP;
    } else {
        t = "B:" + string(t_b);
        draw_text(xcur, l2ty, t);
        xcur += string_width(t) + BLOCK_GAP;
    }

    // ==== Slider row ====
    var row_y   = Y + 88;
    var BTN     = 24;
    var GAP     = 8;
    var track_x = X + 12 + BTN + GAP;
    var track_w = W - (track_x - X) - (BTN + GAP + 12);
    var track_h = 6;
    var track_y = row_y + (BTN - track_h) * 0.5;

    // - button
    var minus_x1 = X + 12, minus_y1 = row_y, minus_x2 = minus_x1 + BTN, minus_y2 = minus_y1 + BTN;
    draw_sprite_stretched(spr_ui_button, 0, minus_x1, minus_y1, BTN, BTN);
    draw_set_color(c_white);
    draw_text(minus_x1 + (BTN - string_width("-")) * 0.5, minus_y1 + (BTN - string_height("-")) * 0.5, "-");

    // + button
    var plus_x2 = X + W - 12, plus_y1 = row_y, plus_x1 = plus_x2 - BTN, plus_y2 = plus_y1 + BTN;
    draw_sprite_stretched(spr_ui_button, 0, plus_x1, plus_y1, BTN, BTN);
    draw_set_color(c_white);
    draw_text(plus_x1 + (BTN - string_width("+")) * 0.5, plus_y1 + (BTN - string_height("+")) * 0.5, "+");

    // Track
    draw_set_color(make_color_rgb(120,120,120));
    draw_rectangle(track_x, track_y, track_x + track_w, track_y + track_h, false);

    // Handle
    var pos = (max_amount > 1) ? (amount - 1) / (max_amount - 1) : 0;
    var hx  = track_x + pos * track_w;
    var hy  = row_y + BTN * 0.5;
    var HR  = 7;
    draw_set_color(c_white);
    draw_circle(hx, hy, HR, false);

    // ==== Confirm / Cancel ====
    var bw = floor((W - 12 - 12 - GAP) * 0.5);
    var by = Y + H - 12 - 28;
    var bx1 = X + 12, bx2 = bx1 + bw + GAP;

    draw_sprite_stretched(spr_ui_button, 0, bx1, by, bw, 28);
    draw_set_color(c_white);
    draw_text(bx1 + (bw - string_width("Sell")) * 0.5, by + 6, "Sell");

    draw_sprite_stretched(spr_ui_button, 0, bx2, by, bw, 28);
    draw_set_color(c_white);
    draw_text(bx2 + (bw - string_width("Cancel")) * 0.5, by + 6, "Cancel");

    // ===== Modal input handling =====
    global.ui_mouse_block = true;

    if (gated) {
        if (!mouse_check_button(mb_left) && !mouse_check_button(mb_right)) {
            variable_struct_set(global.sell_dialog, "block_until_release", false);
        } else {
            return true;
        }
    }

    if (mouse_check_button_pressed(mb_left)) {
        if (point_in_rectangle(mx, my, minus_x1, minus_y1, minus_x2, minus_y2)) {
            amount = max(1, amount - 1);
        } else if (point_in_rectangle(mx, my, plus_x1, plus_y1, plus_x2, plus_y2)) {
            amount = min(max_amount, amount + 1);
        } else if (point_in_rectangle(mx, my, bx1, by, bx1 + bw, by + 28)) {
            inv_sell_amount(item_key, amount);
            close_sell_dialog();
            return true;
        } else if (point_in_rectangle(mx, my, bx2, by, bx2 + bw, by + 28)) {
            close_sell_dialog();
            return true;
        } else if (point_in_rectangle(mx, my, track_x - 6, track_y - 8, track_x + track_w + 6, track_y + track_h + 8)) {
            dragging = true;
        }
    }

    if (dragging) {
        if (mouse_check_button(mb_left)) {
            var tfrac = clamp((mx - track_x) / max(1, track_w), 0, 1);
            amount = 1 + round(tfrac * max(0, max_amount - 1));
        } else {
            dragging = false;
        }
    }

    if (!dragging && mouse_check_button_pressed(mb_left)) {
        if (!point_in_rectangle(mx, my, X, Y, X + W, Y + H)) {
            close_sell_dialog();
            return true;
        }
    }

    variable_struct_set(global.sell_dialog, "amount",   amount);
    variable_struct_set(global.sell_dialog, "dragging", dragging);

    return true;
}

