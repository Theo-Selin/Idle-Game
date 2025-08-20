if (instance_exists(following)) {
    var fx = following.x;
    var fy = following.y;

    var view_w = camera_get_view_width(view_camera[0]);
    var view_h = camera_get_view_height(view_camera[0]);

    // Get current camera top-left position
    var cam_x = x;
    var cam_y = y;

    // Calculate dead zone rectangle inside the view
    var left   = cam_x + h_border;
    var right  = cam_x + view_w - h_border;
    var top    = cam_y + v_border;
    var bottom = cam_y + view_h - v_border;

    // Move the camera object (self) only if the player leaves the dead zone
    if (fx < left) {
        x = fx - h_border;
    } else if (fx > right) {
        x = fx - view_w + h_border;
    }

    if (fy < top) {
        y = fy - v_border;
    } else if (fy > bottom) {
        y = fy - view_h + v_border;
    }

    // Clamp to room boundaries
    x = clamp(x, 0, room_width - view_w);
    y = clamp(y, 0, room_height - view_h);

    // Update camera view position
	x = round(x);
	y = round(y);
}
