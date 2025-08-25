function progress_on_level_up(_skill, _new_level)
{
    var msg = string_upper(_skill) + " Lv." + string(_new_level);

    var spr_idx = -1;
    if (variable_global_exists("levelup_icon_for_skill")) {
        spr_idx = global.levelup_icon_for_skill(_skill, _new_level);
    }

    if (instance_exists(oUIManager)) {
        with (oUIManager) {
            if (!variable_instance_exists(id, "toasts") || !is_array(toasts)) toasts = [];
            var t = (spr_idx != -1)
                ? { text: msg, age: 0, ttl: 120, spr: spr_idx }
                : { text: msg, age: 0, ttl: 120 };
            array_push(toasts, t);

            var MAX_TOASTS = 8;
            while (array_length(toasts) > MAX_TOASTS) array_delete(toasts, 0, 1);
        }
    }

    // Level-up FX near head (unchanged)
    var player = noone;
    if (variable_global_exists("player") && instance_exists(global.player)) player = global.player;
    else if (object_exists(oPlayer) && instance_number(oPlayer) > 0)      player = instance_find(oPlayer, 0);

    if (player != noone) {
        var lay = layer_get_id("FX_Overlays");
        if (lay != -1) {
            var fx  = instance_create_layer(player.x, player.y, lay, oLevelUpFX);
            if (fx != noone) {
                fx.life_sec      = 1.84;
                fx.anim_frac     = 0.40;
                fx.anim_duration = max(0.001, fx.life_sec * fx.anim_frac);

                var ph = sprite_exists(player.sprite_index) ? sprite_get_height(player.sprite_index) : 96;
                var head_offset = max(64, ph * 0.55);
                fx.base_x = player.x;
                fx.base_y = player.y - head_offset;
            }
        }
    }

    if (variable_global_exists("progress") && is_struct(global.progress)) {
        global.progress.autosave_cooldown = 1;
    }
}
