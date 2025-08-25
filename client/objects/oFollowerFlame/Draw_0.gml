/// oFollowerFlame.Draw
var s  = _spr;

// Early out until we have a positive fade (prevents 1-frame pop)
if (variable_instance_exists(id, "fade_t") && fade_t <= 0) exit;

var sc = (variable_instance_exists(id, "scale_now") ? scale_now : base_scale);
var al = (variable_instance_exists(id, "alpha_now") ? alpha_now : alpha_base);

if (s != -1) {
    gpu_set_blendmode_ext(bm_src_alpha, bm_one);

    // Core (tight, bright)
    draw_sprite_ext(s, 0, x, y, sc * 0.70, sc * 0.70, 0, col_core, al);

    // Mid glow
    draw_sprite_ext(s, 0, x, y, sc * 1.20, sc * 1.20, 0, col_mid,  al * 0.50);

    // Outer glow (very soft)
    draw_sprite_ext(s, 0, x, y, sc * 1.80, sc * 1.80, 0, col_glow, al * 0.25);

    gpu_set_blendmode(bm_normal);
} else {
    draw_set_color(col_mid);
    draw_set_alpha(al);
    draw_circle(x, y, max(2, 4 * sc), false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
