if (sprite_index == spr_tree_oak_animation) {
    if (image_index >= image_number - 1) {
        sprite_index = spr_tree_oak_canopy; // ← your normal canopy sprite
        image_index = 0;
        image_speed = 0;
    }
}