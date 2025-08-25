function set_activity_idle() {
    global.save.activity.type = "idle";
    global.save.activity.portal_id = global.current_portal;
    global.__save_dirty = true;
}
