/// @function enemy_die()
function enemy_die(enemy_id) {
    with (enemy_id) {
        if (is_dying) exit; // prevent double death

        is_dying = true;
        state = "dying";
        image_alpha = 1;
        path_end();
        path_active = false;

        if (path != -1) {
            path_delete(path);
            path = -1;
        }

        // Optional: play SFX, spawn death particles, drop loot
        var offset_x = (x > target.x) ? -24 : 24;
		drop_loot(x, y, "coin_copper", 1, id, offset_x, -64);
		//audio_play_sound(snd_slime_pop, 1, false);
		
		 if (instance_exists(path_target)) {
            instance_destroy(path_target);
        }
    }
}
