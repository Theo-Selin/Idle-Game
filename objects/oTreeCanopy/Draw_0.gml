var shake_x = 0;

// Apply sprite shake if active
if (shake_sprite_timer < shake_sprite_duration) {
    var progress = shake_sprite_timer / shake_sprite_duration;
    var frequency = 6 * 2 * pi; // 6 wiggles total
    var strength = sin(progress * frequency + pi * 0.5) * (1 - progress);

    shake_x = strength * shake_sprite_magnitude;
    shake_sprite_timer++;
}

// Draw the sprite with offset
draw_sprite(sprite_index, image_index, x + shake_x, y);
