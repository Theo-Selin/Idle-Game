// === SHADOW ===
var shadow_w = variable_instance_exists(id, "shadow_width") ? shadow_width : 10;
var shadow_h = variable_instance_exists(id, "shadow_height") ? shadow_height : 4;
var shadow_oy = variable_instance_exists(id, "shadow_offset_y") ? shadow_offset_y : 4;
var shadow_a = variable_instance_exists(id, "shadow_alpha") ? shadow_alpha : 0.2;

draw_set_color(c_black);
draw_set_alpha(shadow_a * image_alpha); // Sync shadow fade
draw_ellipse_color(x - shadow_w, y + shadow_oy - shadow_h, x + shadow_w, y + shadow_oy + shadow_h, c_black, c_black, false);

// === RESET
draw_set_alpha(1);
draw_set_color(c_white);

// === SPRITE WITH HIT SHAKE
var draw_x = x + hit_shake_x;
var draw_y = y + hit_shake_y;

draw_set_alpha(image_alpha);
draw_sprite(sprite_index, image_index, draw_x, draw_y);
draw_set_alpha(1);

// === FLASH EFFECT ON HIT
if (is_hit) {
    var flash_alpha = (hit_timer % 2 == 0) ? 1 : 0.5;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(flash_alpha * image_alpha); // Sync with fade
    draw_sprite(sprite_index, image_index, draw_x, draw_y);
    draw_set_alpha(1);
    gpu_set_blendmode(bm_normal);
}
