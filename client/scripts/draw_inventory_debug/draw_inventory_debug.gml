/// @function draw_inventory_debug()
function draw_inventory_debug() {
    var x_start = 16;
    var y_start = 16;
    var box_size = 32;
    var padding = 4;

    for (var i = 0; i < global.inventory_max_slots; i++) {
        var slot_x = x_start + (i % 6) * (box_size + padding); // 6 per row
        var slot_y = y_start + floor(i / 6) * (box_size + padding);

        // Draw slot background
        draw_set_color(c_white);
        draw_rectangle(slot_x, slot_y, slot_x + box_size, slot_y + box_size, false);

        var slot = global.inventory[i];
        if (is_struct(slot)) {
            draw_set_color(c_black);
            draw_text(slot_x + 2, slot_y + 2, slot.item + ": " + string(slot.amount));
        }
    }
}
