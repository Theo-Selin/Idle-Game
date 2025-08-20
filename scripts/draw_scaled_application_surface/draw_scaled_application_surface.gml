function draw_scaled_application_surface(){
	/// scr_draw_scaled_application_surface()
	var target_w = 1280;
	var target_h = 720;

	var display_w = display_get_width();
	var display_h = display_get_height();

	var scale = min(display_w / target_w, display_h / target_h);
	var surf_w = target_w * scale;
	var surf_h = target_h * scale;

	x = (display_w - surf_w) * 0.5;
	y = (display_h - surf_h) * 0.5;

	draw_surface_ext(application_surface, x, y, scale, scale, 0, c_white, 1);

}