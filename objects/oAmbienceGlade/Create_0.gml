/// oAmbienceGlade.Create
enum AMBIENCE_MODE { DAY, NIGHT }

mode = (variable_global_exists("is_night") && global.is_night)
       ? AMBIENCE_MODE.NIGHT
       : AMBIENCE_MODE.DAY;

// ---- Tuning: short life, instant slither, late acceleration ----
max_motes        = 12;     // sparse
spawn_try_steps  = 60;     // try to spawn ~once/sec
spawn_chance     = 1;      // 1.0 = 100% of tries succeed

size_min         = 0.05;
size_max         = 0.10;

// SHORT life (≈2–4s with your params)
life_min         = 120;
life_max         = 240;

// Upward speed ramps over lifetime (accelerates strongly at end)
up_speed_start   = 0.5;    // starts moving up immediately
up_speed_end     = 1.0;    // noticeably faster near the end
up_speed_jitter  = 0.020;

// Slither (make it read quickly)
wiggle_amp_x     = 0.30;
wiggle_amp_y     = 0.08;
freq_min         = 0.025;
freq_max         = 0.050;

// Fades (fit the shorter lifetime)
fade_in_frac     = 0.15;   // first 15% fades in
fade_out_frac    = 0.25;   // last 25% fades out

// Edge fade (keep OFF for now)
edge_fade_enabled      = false;
edge_fade_start_factor = 0.20;
edge_margin_pixels     = 64;

motes = array_create(max_motes, noone);
_spawn_tick = 0;

// ---- Glow settings (lightweight additive halo) ----
glow_enabled      = true;
glow_scale_mult   = 2.2;   // halo is this many times larger than the core
glow_alpha_day    = 0.30;  // base halo alpha (scaled by the mote's current a)
glow_alpha_night  = 0.50;  // fireflies glow brighter at night
glow_pulse_amp    = 0.10;  // subtle brightness wobble
glow_pulse_freq   = 0.09;  // radians/step (slow)

// Colors
function _day_color()   { return make_color_rgb(255, 255, 250); } // bright white pollen
function _night_color() { return make_color_rgb(100, 205, 100); } // firefly green

// Easing helpers
function ease_sine_in(t)   { return 1 - cos((t * pi) / 2); }             // fades
function ease_pow_in(t, p) { return power(max(0, min(1, t)), p); }       // strong end accel

// Helper to (re)spawn a mote
function _spawn_mote_at(_x, _y) {
    for (var i = 0; i < max_motes; i++) {
        if (is_undefined(motes[i]) || motes[i] == noone) {
            var life  = irandom_range(life_min, life_max);

            var col      = (mode == AMBIENCE_MODE.DAY) ? _day_color() : _night_color();
            var mid_a    = 1.0; // punchy core alpha
            var halo_base= (mode == AMBIENCE_MODE.DAY) ? glow_alpha_day : glow_alpha_night;

            var u0 = up_speed_start + random_range(-up_speed_jitter, up_speed_jitter);
            var u1 = up_speed_end   + random_range(-up_speed_jitter, up_speed_jitter);

            motes[i] = {
                x: _x, y: _y,
                age: 0, life: life,
                scale: random_range(size_min, size_max),

                // Slither params
                freq:   random_range(freq_min, freq_max),
                freq2:  random_range(freq_min * 0.6, freq_max * 0.9),
                phase:  random(2 * pi),
                phase2: random(2 * pi),

                // Color/alpha
                color: col,
                mid_alpha: mid_a,

                // Upward accel over life (lerp from up0->up1 with strong end ease)
                up0: max(0.0, u0),
                up1: max(0.0, u1),

                // Glow
                glow_base: halo_base,
                glow_phase: random(2 * pi)
            };
            break;
        }
    }
}

// Prefill a couple so screen isn’t empty at start
var cam = view_camera[0];
var x1 = camera_get_view_x(cam), y1 = camera_get_view_y(cam);
var w  = camera_get_view_width(cam), h  = camera_get_view_height(cam);
for (var k = 0; k < min(3, max_motes); k++) {
    _spawn_mote_at(x1 + random(w), y1 + random(h));
}

// Public API: switch day/night without recreating the object
function set_ambience_mode(_mode) {
    if (mode == _mode) return;
    mode = _mode;

    var col  = (mode == AMBIENCE_MODE.DAY) ? _day_color() : _night_color();
    var halo = (mode == AMBIENCE_MODE.DAY) ? glow_alpha_day : glow_alpha_night;

    for (var i = 0; i < max_motes; i++) {
        var m = motes[i];
        if (is_undefined(m) || m == noone) continue;
        m.color     = col;
        m.glow_base = halo;
        motes[i]    = m;
    }
}
