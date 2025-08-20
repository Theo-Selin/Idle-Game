if (instance_exists(visual_canopy)) {
    visual_canopy.sprite_index = spr_tree_oak_animation;
    visual_canopy.image_index = 0;
    visual_canopy.image_speed = 1;

    with (visual_canopy) {
		shake_sprite_timer = 0;
        shake_sprite_duration = 12; // ~0.2s
        shake_sprite_magnitude = 2.5; // pixels
    }
}

//global_camera_shake(oCamera, 3, 3.5, 0.5, 18);
