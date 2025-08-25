/// @function xp_popup_show(skill, amount)
function xp_popup_show(_skill, _amount) {
    if (!variable_global_exists("player") || !instance_exists(global.player)) return;

    var p = global.player;

    // Create first (Create runs immediately), then configure and place using the same anchor math
    var pop = instance_create_layer(p.x, p.y, "Instances", oPopupFloat);
    if (!instance_exists(pop)) return;

    with (pop) {
        text       = "+" + string(_amount) + " " + string_upper(_skill) + " XP";
        color      = xp_popup_color_for(_skill);
        lifespan   = 36;
        rise_speed = -0.6;
        scale      = 1;

        follow_id        = global.player;
        follow_offset_x  = 0;
        follow_offset_y  = -28; // tweak height here if you want it even higher
        rise_offset      = 0;

        // Position immediately using the SAME anchor used in Step to avoid 1-frame snap
        var s    = follow_id.sprite_index;
        var yoff = (s != -1) ? sprite_get_yoffset(s) : 0;
        var top_y = follow_id.y - yoff;
        x = follow_id.x + follow_offset_x;
        y = top_y + follow_offset_y + rise_offset;

        // Optional icon
        // icon_sprite = spr_xp_star;
        // icon_index  = 0;
    }
}
