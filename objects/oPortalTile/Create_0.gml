/// oPortalTile: Create Event
depth = 0;
// Use instance check instead of local (since Creation Code runs after)
if (!variable_instance_exists(id, "goto_portal_id")) {
    goto_portal_id = ROOM_HOME_OUTSIDE; // fallback if not set via creation code
}
