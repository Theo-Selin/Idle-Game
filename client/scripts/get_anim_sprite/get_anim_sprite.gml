function get_anim_sprite(anim_map, state, direction) {
    if (!is_struct(anim_map)) return -1;

    // Try direct state
    if (variable_struct_exists(anim_map, state)) {
        var state_map = variable_struct_get(anim_map, state);
        if (is_struct(state_map)) {
            // Direct direction
            if (variable_struct_exists(state_map, direction)) {
                return variable_struct_get(state_map, direction);
            }

            // Mirror fallback (left → right)
            if (direction == "left" && variable_struct_exists(state_map, "right")) {
                return variable_struct_get(state_map, "right");
            }
            if (direction == "right" && variable_struct_exists(state_map, "left")) {
                return variable_struct_get(state_map, "left");
            }

            // Any available direction
            var keys = variable_struct_get_names(state_map);
            if (array_length(keys) > 0) {
                return variable_struct_get(state_map, keys[0]);
            }
        }
    }

    // Fallback to idle state
    if (state != "idle" && variable_struct_exists(anim_map, "idle")) {
        return get_anim_sprite(anim_map, "idle", direction);
    }

    return -1;
}
