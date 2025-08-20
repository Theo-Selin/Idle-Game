function draw_tooltip(){
	/// draw_tooltip(text, x, y)
	/// @arg text  // multiline string (use "\n" to break)
	/// @arg x
	/// @arg y

	var _text = argument0;
	var _x = argument1;
	var _y = argument2;

	var pad = 6;
	var line_height = string_height("A");
	var lines = string_count("\n", _text) + 1;

	var text_w = string_width_ext(_text, -1, 9999); // handles longest line
	var text_h = line_height * lines;

	var box_w = text_w + pad * 2;
	var box_h = text_h + pad * 2;

	// Prevent offscreen draw (right + bottom only)
	if (_x + box_w > display_get_gui_width()) {
	    _x = display_get_gui_width() - box_w - 4;
	}
	if (_y + box_h > display_get_gui_height()) {
	    _y = display_get_gui_height() - box_h - 4;
	}

	// Draw background
	draw_set_color(make_color_rgb(30, 30, 30));
	draw_rectangle(_x, _y, _x + box_w, _y + box_h, false);

	draw_set_color(make_color_rgb(0, 0, 0));
	draw_rectangle(_x + 1, _y + 1, _x + box_w - 1, _y + box_h - 1, true);

	// Draw text
	draw_set_color(c_white);
	draw_text(_x + pad, _y + pad, _text);

}