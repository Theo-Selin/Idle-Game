function change_tab(tab_name) {
    if (tab_name == active_tab) return;

    // Destroy old
    if (instance_exists(oInventoryUI)) instance_destroy(oInventoryUI);
    if (instance_exists(oCraftingUI)) instance_destroy(oCraftingUI);

    // Set new tab
    active_tab = tab_name;

    // Recreate corresponding panel
    if (!ui_visible) return;

    switch (active_tab) {
        case "inventory":
            instance_create_layer(0, 0, "GUI", oInventoryUI);
            break;
        case "crafting":
            instance_create_layer(0, 0, "GUI", oCraftingUI);
            break;
    }
}
