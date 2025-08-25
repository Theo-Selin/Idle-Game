/// @function ui_toggle_button_toggle(state, rect, snd_open, snd_close)
/// @desc Handles toggle and mouse blocking
/// @returns new state
function ui_toggle_button_toggle(state, rect, sound_open, sound_close) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    if (mouse_check_button_pressed(mb_left)) {
        if (point_in_rectangle(mx, my, rect[0], rect[1], rect[2], rect[3])) {
            state = !state;
            audio_play_sound(state ? sound_open : sound_close, 1, false);
        }
    }
    return state;
}
