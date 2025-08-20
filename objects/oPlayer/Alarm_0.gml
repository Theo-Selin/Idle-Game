if (target != noone && action_type == "door") {
    if (instance_exists(target) && variable_instance_exists(target, "portal_id")) {
        portal_activate(target.portal_id);
    } else {
        show_debug_message("❌ Door target has no portal_id");
    }
}
