var frame = image_index;

// Base
var spr_base = get_anim_sprite(base_sprites, anim_state, anim_dir);
if (spr_base != -1) draw_sprite(spr_base, frame, x, y);

// Armor
if (armor_data != undefined) {
    var spr_armor = get_anim_sprite(armor_data.anim_sprites, anim_state, anim_dir);
    if (spr_armor != -1) draw_sprite(spr_armor, frame, x, y);
}

// Helmet
if (helmet_data != undefined) {
    var spr_helmet = get_anim_sprite(helmet_data.anim_sprites, anim_state, anim_dir);
    if (spr_helmet != -1) draw_sprite(spr_helmet, frame, x, y);
}

// Weapon
if (weapon_data != undefined) {
    var spr_weapon = get_anim_sprite(weapon_data.anim_sprites, anim_state, anim_dir);
    if (spr_weapon != -1) draw_sprite(spr_weapon, frame, x, y);
}

// === DRAW SHADOW ===
var shadow_offset_y = -2;        // Distance below feet
var shadow_width    = 12;       // Horizontal stretch
var shadow_height   = 4;        // Vertical squish
var shadow_alpha    = 0.2;      // Transparency

draw_set_color(c_black);
draw_set_alpha(shadow_alpha);

draw_ellipse_color(
    x - shadow_width,
    y + shadow_offset_y - shadow_height,
    x + shadow_width,
    y + shadow_offset_y + shadow_height,
    c_black, c_black, false
);

draw_set_alpha(1);
draw_set_color(c_white);

// === WHITE FLASH EFFECT
if (is_hit) {
    var flash_alpha = (hit_timer % 2 == 0) ? 1 : 0.5;
    gpu_set_blendmode(bm_add);
    draw_set_alpha(flash_alpha);
    draw_sprite(sprite_index, image_index, x, y);
    draw_set_alpha(1);
    gpu_set_blendmode(bm_normal);
}