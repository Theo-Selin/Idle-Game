/// oPopupFloat — Create
text = "";
color = c_white;
lifespan = 45;
timer = 0;

alpha = 1;
scale = 1;
icon_scale = 0.5;
depth = -100;

// Icon state
icon_sprite = -1;
icon_index  = 0;
// legacy compat
sprite      = -1;

rise_speed  = -0.5;
rise_offset = 0;

// Follow target (default to player so all popups behave the same)
follow_id        = noone;
follow_offset_x  = 0;
follow_offset_y  = -24;
padding          = 2;

// Background
bg_enabled = true;
bg_color   = c_black;
bg_opacity = 0.4;
bg_pad_x   = 4;
bg_pad_y   = 2;
bg_rounded = true;

// Stable anchor cache
__anchor_inited = false;
__anchor_fid    = noone;
__anchor_yoff   = 0;

// ✅ SNAP TO HEAD *NOW* so the first frame draws at the right spot
var fid = follow_id;
if (!instance_exists(fid) && variable_global_exists("player") && instance_exists(global.player)) {
    fid = global.player;
    follow_id = fid; // unify default
}
if (instance_exists(fid)) {
    var mask = fid.mask_index;
    if (mask != -1) {
        __anchor_yoff = sprite_get_yoffset(mask);
    } else {
        var s = fid.sprite_index;
        __anchor_yoff = (s != -1) ? sprite_get_yoffset(s) : 0;
    }
    __anchor_fid    = fid;
    __anchor_inited = true;

    var top_y = fid.y - __anchor_yoff;
    x = fid.x + follow_offset_x;
    y = top_y + follow_offset_y + rise_offset; // first draw = correct position
}

// mark initialized
__popup_inited = true;
