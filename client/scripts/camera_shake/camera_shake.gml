/// @function global_camera_shake(camera_instance, bursts, mag_x, mag_y, duration_frames)
/// @desc Triggers camera shake on the given camera instance.
/// @param camera_instance - Instance of the camera object (e.g., oCamera)
/// @param bursts - Number of full wiggle cycles
/// @param mag_x - Horizontal shake strength
/// @param mag_y - Vertical shake strength
/// @param duration_frames - Total duration in steps

function global_camera_shake(camera_instance, bursts, mag_x, mag_y, duration_frames) {
    if (!instance_exists(camera_instance)) return;

    show_debug_message("Shake triggered");

    with (camera_instance) {
        shake_active = true;
        shake_bursts = bursts;
        shake_magnitude_x = mag_x;
        shake_magnitude_y = mag_y;
        shake_total_duration = duration_frames;
        shake_timer = 0;
    }
}
