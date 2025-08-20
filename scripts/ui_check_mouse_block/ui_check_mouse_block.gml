/// @function ui_check_mouse_block(x, y, w, h)
/// @desc Call this inside UI Draw to prevent click-through
/// @param x Top-left x of UI area
/// @param y Top-left y of UI area
/// @param w Width of UI area
/// @param h Height of UI area

function ui_check_mouse_block(x, y, w, h) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    if (point_in_rectangle(mx, my, x, y, x + w, y + h)) {
        global.ui_mouse_block = true;
    }
}
