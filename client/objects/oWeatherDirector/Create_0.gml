/// oWeatherDirector.Create
if (instance_number(object_index) > 1) { instance_destroy(); exit; }

// ====== Time-of-day (driven by oGame) ======
// 1 = full day, 0 = full night. oGame will call set_time_of_day().
day_lerp = 1.0;

// External API used by oGame:
function set_time_of_day(_t) { day_lerp = clamp(_t, 0, 1); }
function get_time_of_day()   { return day_lerp; }

// --- INIT FROM GLOBAL (so new rooms start at the correct time) ---
if (variable_global_exists("time_of_day")) {
    set_time_of_day(clamp(global.time_of_day, 0, 1));
}

// ====== Center Bloom (uses cloud occlusion only) ======
center_bloom_color       = make_color_rgb(155,155,0);
center_bloom_strength    = 0.02;   // try 0.16–0.26
center_bloom_radius_frac = 1.00;
center_bloom_layers      = 24;     // lighter for mobile
center_bloom_spread_frac = 1.00;

bloom_force = 0; // 0=auto, 1=force full, -1=half

// Smoothing to avoid flicker from moving clouds (used in Draw)
wd_prev_bloom  = 1.0;
wd_smooth_rate = 10.0;  // per-second LERP

// ====== Night Vignette Surface (with player hole) ======
vignette_color       = make_color_rgb(6, 10, 58); // cool dark
vignette_inner_alpha = 0.80; // center at full night
vignette_outer_alpha = 0.9; // edges at full night
vignette_radius_frac = 2.10; // vs view diagonal, kept circular

night_clear_radius_px = 0;    // fully clear core radius
night_clear_soft_px   = 150;  // soft falloff width
night_clear_strength  = 1.0; // 1=erase fully at center

night_vignette_surf = -1;

function __ensure_vignette_surface(_w, _h) {
    if (surface_exists(night_vignette_surf)) {
        if (surface_get_width(night_vignette_surf) != _w || surface_get_height(night_vignette_surf) != _h) {
            surface_free(night_vignette_surf);
            night_vignette_surf = -1;
        }
    }
    if (!surface_exists(night_vignette_surf)) night_vignette_surf = surface_create(_w, _h);
}

// ---- tiny helpers ----
function __add_on()  { gpu_set_blendmode_ext(bm_src_alpha, bm_one); }
function __add_off() { gpu_set_blendmode(bm_normal); }

function __radial_bloom(_cu, _cv, _rx, _ry, _col, _alpha) {
    if (_alpha <= 0) return;
    var steps = 28;
    __add_on();
    draw_primitive_begin(pr_trianglefan);
        draw_vertex_color(_cu, _cv, _col, _alpha);
        var step_deg = 360 / steps;
        for (var i = 0; i <= steps; i++) {
            var th = i * step_deg;
            var uu = _cu + _rx * dcos(th);
            var vv = _cv + _ry * dsin(th);
            draw_vertex_color(uu, vv, _col, 0);
        }
    draw_primitive_end();
    __add_off();
}

function __radial_overlay_local(_cx, _cy, _rx, _ry, _col, _alpha_center, _alpha_edge) {
    if (_alpha_center <= 0 && _alpha_edge <= 0) return;
    gpu_set_blendmode(bm_normal);
    var steps = 28;
    draw_primitive_begin(pr_trianglefan);
        draw_vertex_color(_cx, _cy, _col, _alpha_center);
        var step_deg = 360 / steps;
        for (var i = 0; i <= steps; i++) {
            var th = i * step_deg;
            var uu = _cx + _rx * dcos(th);
            var vv = _cy + _ry * dsin(th);
            draw_vertex_color(uu, vv, _col, _alpha_edge);
        }
    draw_primitive_end();
}

// Multiply destination by (1 - src_alpha), incl. dest alpha
function __erase_circle_local(_cx, _cy, _r_px, _soft_px, _strength) {
    var r_outer = max(1, _r_px + max(0, _soft_px));
    gpu_set_blendmode_ext_sepalpha(bm_zero, bm_inv_src_alpha, bm_zero, bm_inv_src_alpha);
    var steps = 28;
    draw_primitive_begin(pr_trianglefan);
        draw_vertex_color(_cx, _cy, c_white, clamp(_strength, 0, 1));
        var step_deg = 360 / steps;
        for (var i = 0; i <= steps; i++) {
            var th = i * step_deg;
            var uu = _cx + r_outer * dcos(th);
            var vv = _cy + r_outer * dsin(th);
            draw_vertex_color(uu, vv, c_white, 0);
        }
    draw_primitive_end();
    gpu_set_blendmode(bm_normal);
}
