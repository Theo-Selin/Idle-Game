// === FOLLOWING SETUP ===
following = oPlayer;
h_border = camera_get_view_width(view_camera[0]) * 0.45;
v_border = camera_get_view_height(view_camera[0]) * 0.45;

// === CAMERA SHAKE VARIABLES ===
shake_active = false;
shake_timer = 0;
shake_total_duration = 0;
shake_magnitude_x = 0;
shake_magnitude_y = 0;
shake_bursts = 0;
shake_offset_x = 0;
shake_offset_y = 0;
