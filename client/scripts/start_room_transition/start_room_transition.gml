function start_room_transition(_target_room) {
    var fade;

    if (instance_exists(oFadeController)) {
        fade = oFadeController;
    } else {
        fade = instance_create_layer(0, 0, "Instances", oFadeController);
    }

    with (fade) {
        fading_out = true;

        target_room = _target_room; // ✅ Must assign to the instance
        on_fade_complete = function () {
            room_goto(target_room); // ✅ 'target_room' must be defined in this scope (the instance)
        };
    }
}
