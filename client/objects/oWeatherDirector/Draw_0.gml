/// oWeatherDirector.Draw
// Put on a TOP world layer (above gameplay, below UI)

// ----- Camera rect -----
var cam_id = -1;
for (var i = 0; i < 8; i++) if (view_get_visible(i)) { cam_id = view_get_camera(i); break; }
if (cam_id == -1 && is_array(view_camera) && array_length(view_camera) > 0) cam_id = view_camera[0];

var L, T, W, H;
if (cam_id != -1) {
    L = camera_get_view_x(cam_id);
    T = camera_get_view_y(cam_id);
    W = camera_get_view_width(cam_id);
    H = camera_get_view_height(cam_id);
} else {
    L = 0; T = 0; W = display_get_gui_width(); H = display_get_gui_height();
}

// ----- Read occlusion from clouds (independent of day/night) -----
var dt = clamp(delta_time / 1000000.0, 0.000001, 0.1);
var raw_bloom = 1.0; // 1 = full bloom (no occlusion)
if (bloom_force == 1) {
    raw_bloom = 1.0;
} else if (bloom_force == -1) {
    raw_bloom = 0.5;
} else {
    var ply = object_exists(oPlayer)       ? instance_find(oPlayer, 0)       : noone;
    var cls = object_exists(oCloudShadows) ? instance_find(oCloudShadows, 0) : noone;
    if (instance_exists(ply) && instance_exists(cls)
    &&  variable_instance_exists(cls, "bloom_factor_at_point")) {
        raw_bloom = clamp(cls.bloom_factor_at_point(ply.x, ply.y), 0, 1);
    }
}
// Smooth the occlusion
var k = clamp(wd_smooth_rate * dt, 0, 1);
wd_prev_bloom = lerp(wd_prev_bloom, raw_bloom, k);

// ----- Derived -----
var cen_u = L + W * 0.5;
var cen_v = T + H * 0.5;
var diag  = point_distance(0, 0, W, H);
var night_k = 1.0 - day_lerp; // 0=day, 1=night

// ================= Night Vignette (with player hole) =================
if (night_k > 0.001) {
    __ensure_vignette_surface(W, H);
    if (surface_exists(night_vignette_surf)) {
        surface_set_target(night_vignette_surf);
        draw_clear_alpha(c_black, 0);

        var CX = W * 0.5, CY = H * 0.5;
        var base = min(W, H);
        var r_px = (base * 0.5) * vignette_radius_frac;

        // Force a circle
        var RX = r_px, RY = r_px;

        var a_center = vignette_inner_alpha * night_k;
        var a_edge   = vignette_outer_alpha * night_k;
        __radial_overlay_local(CX, CY, RX, RY, vignette_color, a_center, a_edge);

        // ---- Player hole: fade strength matches flame alpha/fade ----
        var flm = object_exists(oFollowerFlame) ? instance_find(oFollowerFlame, 0) : noone;
        if (instance_exists(flm)) {
            var px_local = flm.x - L;
            var py_local = flm.y - T;

            // Read flame's visual alpha (fallback to 0 if not ready)
            var hole_fade = 0.0;
            if (variable_instance_exists(flm, "alpha_now")) {
                hole_fade = clamp(flm.alpha_now, 0, 1);
            } else if (variable_instance_exists(flm, "fade_t")) {
                hole_fade = clamp(flm.fade_t, 0, 1);
            }

            // Scale the erase by flame's current visibility so it **fades in/out together**
            var hole_strength = night_clear_strength * hole_fade;
            if (hole_strength > 0.001) {
                __erase_circle_local(px_local, py_local, night_clear_radius_px, night_clear_soft_px, hole_strength);
            }
        }

        // ---- Portal holes: make portals ignore the vignette ----
        if (object_exists(oPortalTile)) {
            var n = instance_number(oPortalTile);
            if (n > 0) {
                for (var i = 0; i < n; i++) {
                    var p = instance_find(oPortalTile, i);
                    if (!instance_exists(p)) continue;

                    // Local screen-space position; align to your glow base (y + 16)
                    var px_local = p.x - L;
                    var py_local = (p.y + 16) - T;

                    // --- Safe radius & params (all with fallbacks) ---
                    var rad = 56; // default radius

                    // Prefer explicit per-instance override if set:
                    if (variable_instance_exists(p, "vignette_clear_radius_px")) {
                        var rv = variable_instance_get(p, "vignette_clear_radius_px");
                        if (is_real(rv) && rv > 0) rad = rv;
                    } else {
                        // Derive from glow size if available (SAFE reads)
                        var bw = 128;
                        if (variable_instance_exists(p, "glow_beam_width")) {
                            var bwv = variable_instance_get(p, "glow_beam_width");
                            if (is_real(bwv)) bw = max(0, bwv);
                        }
                        var bh = 128;
                        if (variable_instance_exists(p, "glow_beam_height")) {
                            var bhv = variable_instance_get(p, "glow_beam_height");
                            if (is_real(bhv)) bh = max(0, bhv);
                        }
                        rad = max(rad, round(max(bw * 0.5, bh * 0.5)));
                    }

                    var soft  = 12;
                    if (variable_instance_exists(p, "vignette_clear_soft_px")) {
                        var sv = variable_instance_get(p, "vignette_clear_soft_px");
                        if (is_real(sv) && sv >= 0) soft = sv;
                    }

                    var _power = 0.5;
                    if (variable_instance_exists(p, "vignette_clear_strength")) {
                        var pv = variable_instance_get(p, "vignette_clear_strength");
                        if (is_real(pv)) _power = clamp(pv, 0, 0.5);
                    }

                    // Early cull if hole is off-screen (radius padded)
                    if (px_local < -rad || px_local > W + rad || py_local < -rad || py_local > H + rad) continue;

                    if (_power > 0.001) {
                        __erase_circle_local(px_local, py_local, rad, soft, _power);
                    }
                }
            }
        }

        surface_reset_target();
        draw_surface(night_vignette_surf, L, T);
    }
}

// ================= Day Bloom (warm) =================
if (day_lerp > 0.001) {
    var layers = max(1, center_bloom_layers);
    var spread = max(0, center_bloom_spread_frac);
    for (var li = 0; li < layers; li++) {
        var r_frac = center_bloom_radius_frac + (li * (spread / max(1, layers - 1)));
        var r_px   = diag * r_frac;
        var rx = (W / diag) * r_px;
        var ry = (H / diag) * r_px;
        var wght = 1.0 - (li / max(1, layers));
        // Bloom follows both: day brightness and cloud occlusion
        var a = center_bloom_strength * wght * wght * day_lerp * wd_prev_bloom;
        __radial_bloom(cen_u, cen_v, rx, ry, center_bloom_color, a);
    }
}

draw_set_alpha(1);
