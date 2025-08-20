if (shake_active) {
    shake_timer++;

    var progress = shake_timer / shake_total_duration;

    if (shake_timer >= shake_total_duration) {
        shake_active = false;
        shake_offset_x = 0;
        shake_offset_y = 0;
    } else {
        var frequency = shake_bursts * 2 * pi;
        var strength = sin(progress * frequency + pi * 0.5) * (1 - progress);

        shake_offset_x = strength * shake_magnitude_x;
        shake_offset_y = strength * shake_magnitude_y;

        show_debug_message("Offset: " + string(shake_offset_x) + ", " + string(shake_offset_y));
    }
}

var final_x = round(x + shake_offset_x);
var final_y = round(y + shake_offset_y);
camera_set_view_pos(view_camera[0], final_x, final_y);
