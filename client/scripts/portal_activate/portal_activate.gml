function portal_activate(portal_id) {
    show_debug_message("🚪 Activating portal: " + string(portal_id));

    handle_portal_audio(portal_id);

    // NEW: persist the facing to use in the next room
    if (instance_exists(global.player)) {
        global.portal_spawn_facing = global.player.anim_dir; // "up","down","left","right"
    }

    var target_room = get_room_for_portal(portal_id);
    if (target_room != noone) {
        start_room_transition(target_room);
    }
}
