/// @function start_shake(_bursts, _mag_x, _mag_y, _duration)
/// @desc Triggers camera shake from anywhere
/// @param _bursts Number of bursts (cycles)
/// @param _mag_x Shake strength X
/// @param _mag_y Shake strength Y
/// @param _duration Duration in steps

function start_shake(_bursts, _mag_x, _mag_y, _duration) {
    if (!instance_exists(oCamera)) return;

    with (oCamera) {
        shake_active = true;
        shake_bursts = _bursts;
        shake_magnitude_x = _mag_x;
        shake_magnitude_y = _mag_y;
        shake_total_duration = _duration;
        shake_timer = 0;
    }
}
