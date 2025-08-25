function portal_register(portal_id, x, y) {
    if (!variable_global_exists("global.portal_tiles")) {
        global.portal_tiles = array_create(0);
    }

    var entry = {
        id: portal_id,
        x: x,
        y: y
    };

    array_push(global.portal_tiles, entry);
}
