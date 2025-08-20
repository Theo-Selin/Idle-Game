/// oPortalTile: Collision with oPlayer
if (!other.teleport_started) {
    other.teleport_started = true;
    portal_activate(goto_portal_id);
}
