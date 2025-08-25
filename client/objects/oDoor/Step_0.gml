if (is_opening && !opened) {
    if (image_index >= image_number - 1) {
        opened = true;
        is_opening = false;

        // ✅ Trigger portal after opening
        if (variable_instance_exists(id, "portal_id")) {
            show_debug_message("🚪 Door finished opening. Activating portal " + string(portal_id));
            portal_activate(portal_id);
        } else {
            show_debug_message("❌ Door missing portal_id");
        }
    }
}
