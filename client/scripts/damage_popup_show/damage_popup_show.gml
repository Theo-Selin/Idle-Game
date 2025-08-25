/// @function damage_popup_show
/// @desc Spawns a world-anchored damage number near inst's head. `_kind` is one of: "hit","crit","heal","block","miss".
/// @param {Id.Instance|Asset.GMObject} _inst   Instance id or object asset
/// @param {real|string} _amt                   Number (e.g., 12) or text ("MISS")
/// @param {string} _kind                       Affects style: "hit","crit","heal","block","miss"
function damage_popup_show(_inst, _amt, _kind) {
    if (!instance_exists(_inst)) return;

    // Stable initial anchor: prefer mask (consistent across anims)
    var yoff = 0;
    var mask = _inst.mask_index;
    if (mask != -1) {
        yoff = sprite_get_yoffset(mask);
    } else {
        var s = _inst.sprite_index;
        yoff = (s != -1) ? sprite_get_yoffset(s) : 0;
    }

    var head_x = _inst.x;
    var head_y = _inst.y - yoff - 8;

    var obj = instance_create_layer(head_x, head_y, "Instances", oDamageFloat);
    if (!instance_exists(obj)) return;

    with (obj) {
        kind  = is_string(_kind) ? _kind : "hit";
        value = _amt;
        label = is_string(_amt) ? _amt : string(_amt);

        switch (kind) {
            case "crit":
                col_start  = c_yellow;
                col_end    = c_yellow;
                scale_base = 1.20;
                scale_peak = 2.00;
                scale_end  = 1.35;
                vx         = irandom_range(-10, 10) * 0.03;
                vy         = -2;
                gravity    = 0.06;
                bg_enabled = false;
            break;

            case "heal":
                col_start  = make_color_rgb(120, 255, 160);
                col_end    = make_color_rgb(60, 200, 120);
                scale_base = 1.10;
                scale_peak = 1.55;
                scale_end  = 1.05;
                vx         = irandom_range(-8, 8) * 0.025;
                vy         = -1.0;
                gravity    = 0.05;
                rot        = 0;
                label      = "+" + label;
            break;

            case "block":
                col_start  = make_color_rgb(200, 200, 220);
                col_end    = make_color_rgb(160, 160, 190);
                scale_base = 1.05;
                scale_peak = 1.35;
                scale_end  = 1.00;
                vx         = irandom_range(-6, 6) * 0.02;
                vy         = -0.6;
                gravity    = 0.04;
                label      = "BLOCK";
            break;

            case "miss":
                col_start  = make_color_rgb(180, 200, 255);
                col_end    = make_color_rgb(120, 160, 240);
                scale_base = 1.05;
                scale_peak = 1.40;
                scale_end  = 1.00;
                vx         = irandom_range(-12, 12) * 0.03;
                vy         = -0.9;
                gravity    = 0.05;
                label      = "MISS";
            break;

            default: // "hit"
                col_start  = c_white;
                col_end    = c_white;
                scale_base = 1.00;
                scale_peak = 1.50;
                scale_end  = 1.00;
                vx         = irandom_range(-10, 10) * 0.03;
                vy         = -1.5;
                gravity    = 0.10;
            break;
        }
    }
}
