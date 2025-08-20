// oFadeController – Draw GUI Event

// Get GUI dimensions safely
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Fade overlay
draw_set_alpha(fade);
draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1);
