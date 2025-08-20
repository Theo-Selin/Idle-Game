var dt = delta_time * 0.000001;
age_sec += dt;

var t      = clamp(age_sec / life_sec, 0, 1);          // 0..1 lifetime
var anim_t = clamp(age_sec / anim_duration, 0, 1);     // 0..1 animation window

// Drive animation; then freeze on last frame
image_index = last_frame * anim_t;
if (anim_t >= 1) { image_index = last_frame; }

// Popup-style drift + fade
x = base_x;
y = base_y + lerp(0, -rise_total, t);
image_alpha = 1 - t;

if (age_sec >= life_sec) instance_destroy();
