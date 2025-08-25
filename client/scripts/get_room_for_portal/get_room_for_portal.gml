function get_room_for_portal(portal_id) {
    if (is_array(global.portal_data) && array_length(global.portal_data) > portal_id) {
        var portal = global.portal_data[portal_id];
        if (is_struct(portal) && variable_struct_exists(portal, "room")) {
            return portal.room;
        }
    }

    show_debug_message("❌ get_room_for_portal: Invalid portal_id " + string(portal_id));
    return noone; // This resolves to -4 internally — bad for room_goto
}
