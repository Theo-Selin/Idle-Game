function progress_on_level_up(_skill, _new_level) {
    if (instance_exists(oUIManager)) {
        ui_toast_add(string_upper(_skill) + " Lv." + string(_new_level) + "!");
    }

    var player = instance_find(oPlayer, 0);
    if (player != noone) {
        var lay = layer_get_id("FX_Overlays");
        var fx  = instance_create_layer(player.x, player.y, lay, oLevelUpFX);

        fx.life_sec      = 1.84;                 // ← fixed duration
        fx.anim_frac     = 0.40;
        fx.anim_duration = max(0.001, fx.life_sec * fx.anim_frac);

        var head_offset = max(64, sprite_get_height(player.sprite_index) * 0.55);
        fx.base_x = player.x;
        fx.base_y = player.y - head_offset;
    }

    if (variable_global_exists("progress") && is_struct(global.progress)) {
        global.progress.autosave_cooldown = 1;
    }
}
