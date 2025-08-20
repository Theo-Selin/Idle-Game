/// oPopupFloat — Step

// Pick who to follow: prefer explicit follow_id, else default to player
var fid = follow_id;
if (!instance_exists(fid) && variable_global_exists("player") && instance_exists(global.player)) {
    fid = global.player;
}

// Anchor + motion
if (instance_exists(fid)) {
    // Stable head anchor using sprite origin (no frame-to-frame bbox jitter)
    var s     = fid.sprite_index;
    var yoff  = (s != -1) ? sprite_get_yoffset(s) : 0;
    var top_y = fid.y - yoff;

    // Force exact head position every frame (so all popups start from same place)
    x = fid.x + follow_offset_x;
    y = top_y + follow_offset_y + rise_offset;

    // Float up over time
    rise_offset += rise_speed;
} else {
    // Free-floating fallback (only used if no player exists)
    y += rise_speed;
}

// Fade out
timer++;
alpha = 1 - (timer / lifespan);
if (alpha < 0) alpha = 0;

if (timer >= lifespan) instance_destroy();
