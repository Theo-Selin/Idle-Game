/// oCloudShadows.Create
cam = view_camera[0];

if (instance_number(object_index) > 1) { instance_destroy(); exit; }

// ---------- Master tuning (shape-focused) ----------
shadow_master   = 0.40;
density_mul     = 0.35;   // fewer blobs
blob_stretch_x  = 3.50;   // less streaky
blob_stretch_y  = 1.30;   // a bit fuller vertically
blob_fade_speed = 0.03;

shadow_color = make_color_rgb(20, 30, 35);

// Spawn/Wrap behavior (visible + smooth by default)
blob_spawn_fade       = true;
blob_wrap_fade        = false;
avoid_view_on_spawn   = true;
spawn_avoid_margin_px = 96;
prewarm_steps         = 120;

// Wind
wind_angle = degtorad(18);
wind_speed = 0.3;

// ---------- World rect ----------
world_l = 0; world_t = 0;
world_r = room_width; world_b = room_height;
world_w = max(1, world_r - world_l);
world_h = max(1, world_b - world_t);

// ---------- Density scaling ----------
var ref_w = 1280, ref_h = 720;
area_mul  = clamp((world_w * world_h) / (ref_w * ref_h), 1.0, 3.0);
max_total = 220;

// ---------- Bands (fewer + bigger look) ----------
bands = [
    { speed: 0.28, alpha: 0.045, scale: 1.90, base: 12, blobs: [] },
    { speed: 0.48, alpha: 0.055, scale: 1.70, base: 14, blobs: [] },
    { speed: 0.72, alpha: 0.060, scale: 1.55, base: 10, blobs: [] }
];

// ---------- Extra shape controls ----------
use_multi_lobes    = true;
lobe_min           = 2;     // 2–3 lobes feels good
lobe_max           = 3;
lobe_spread_min_px = 36;    // distance from center along tangent
lobe_spread_max_px = 88;
lobe_scale_min     = 0.60;  // lobe size vs. main blob
lobe_scale_max     = 0.90;
lobe_alpha_mul     = 0.60;  // lobe alpha vs. main

// Subtle motion -> organic shape without texture
wiggle_speed  = 0.004; // per-step phase speed
wiggle_amp_px = 8;     // max offset added to spread

// Mild per-blob aspect variance (Y only)
aspect_min = 0.90;
aspect_max = 1.15;

// Helper: spawn outside current view (optional)
function __spawn_pos() {
    var cx = irandom_range(world_l, world_r);
    var cy = irandom_range(world_t, world_b);

    if (avoid_view_on_spawn) {
        var vx = 0, vy = 0, vw = 0, vh = 0;
        if (is_array(view_camera) && array_length(view_camera) > 0) {
            var cam0 = view_camera[0];
            vx = camera_get_view_x(cam0);
            vy = camera_get_view_y(cam0);
            vw = camera_get_view_width(cam0);
            vh = camera_get_view_height(cam0);
        }
        var tries = 0, max_tries = 12;
        var mx1 = vx - spawn_avoid_margin_px;
        var my1 = vy - spawn_avoid_margin_px;
        var mx2 = vx + vw + spawn_avoid_margin_px;
        var my2 = vy + vh + spawn_avoid_margin_px;

        while (tries < max_tries && cx >= mx1 && cx <= mx2 && cy >= my1 && cy <= my2) {
            cx = irandom_range(world_l, world_r);
            cy = irandom_range(world_t, world_b);
            tries++;
        }
    }
    return [cx, cy];
}

// Spawn (bigger scale range + per-blob shape fields)
function __spawn_blobs_for(_band) {
    var arr = _band.blobs; array_resize(arr, 0);

    var want = round(_band.base * density_mul * area_mul);

    var total_pre = 0;
    for (var k = 0; k < array_length(bands); k++) {
        total_pre += round(bands[k].base * density_mul * area_mul);
    }
    if (total_pre > max_total) {
        var kf = max_total / total_pre;
        want = max(4, round(want * kf));
    }

    var init_local_a = (blob_spawn_fade ? 0.0 : 1.0);

    for (var i = 0; i < want; i++) {
        var p  = __spawn_pos();
        var cx = p[0], cy = p[1];

        // Bias toward larger blobs
        var scl_bias = power(random(1), 0.35);
        var scl      = _band.scale * lerp(1.8, 3.0, scl_bias);
        var a        = _band.alpha * random_range(0.90, 1.10);

        var lobes    = (use_multi_lobes ? irandom_range(lobe_min, lobe_max) : 0);
        var lspread  = random_range(lobe_spread_min_px, lobe_spread_max_px);
        var lscale   = random_range(lobe_scale_min, lobe_scale_max);
        var y_aspect = random_range(aspect_min, aspect_max); // vertical only

        var blob = {
            x: cx, y: cy,
            scale: scl, alpha: a, local_a: init_local_a,
            lobes: lobes, lspread: lspread, lscale: lscale,
            ymul: y_aspect,
            seed: irandom(1000000) // unique wiggle
        };
        array_push(arr, blob);
    }
    _band.blobs = arr;
    return _band;
}

for (var b = 0; b < array_length(bands); b++) {
    bands[b] = __spawn_blobs_for(bands[b]);
}

// Pre-warm: desync fades and positions so nothing “pops” at t=0
if (prewarm_steps > 0) {
    var wx = dcos(radtodeg(wind_angle));
    var wy = dsin(radtodeg(wind_angle));
    for (var rep = 0; rep < prewarm_steps; rep++) {
        for (var i = 0; i < array_length(bands); i++) {
            var B   = bands[i];
            var spd = wind_speed * B.speed;
            var arr = B.blobs;
            for (var j = 0; j < array_length(arr); j++) {
                var s = arr[j];
                s.x += wx * spd; s.y += wy * spd;
                if (s.local_a < 1.0) s.local_a = min(1.0, s.local_a + blob_fade_speed);
                if (s.x < world_l) s.x += world_w; else if (s.x > world_r) s.x -= world_w;
                if (s.y < world_t) s.y += world_h; else if (s.y > world_b) s.y -= world_h;
                arr[j] = s;
            }
            B.blobs = arr; bands[i] = B;
        }
    }
}

// —— Bloom profile knobs (KEEP) ——
shade_core_rel  = 0.1;
shade_full_rel  = 1;
shade_curve_pow = 0.65;

// —— Public: bloom factor (INSTANCE METHOD) ———
// Returns occlusion factor at a world point (0=fully under core, 1=no occlusion).
bloom_factor_at_point = function(_u, _v) {
    var stretch_u = blob_stretch_x, stretch_v = blob_stretch_y;
    var ang_deg = radtodeg(wind_angle), ca = dcos(ang_deg), sa = dsin(ang_deg);

    var spr   = sprite_exists(spr_shadow_blob) ? spr_shadow_blob : -1;
    var sw    = (spr != -1) ? sprite_get_width(spr)  : 128;
    var sh    = (spr != -1) ? sprite_get_height(spr) : 128;
    var off_u = (spr != -1) ? sprite_get_xoffset(spr) : sw * 0.5;
    var off_v = (spr != -1) ? sprite_get_yoffset(spr) : sh * 0.5;
    var half_sw = sw * 0.5, half_sh = sh * 0.5;

    var got_any = false, min_d2 = 0.0;

    for (var i = 0; i < array_length(bands); i++) {
        var B = bands[i], arr = B.blobs;
        for (var j = 0; j < array_length(arr); j++) {
            var s = arr[j];
            if (s.local_a <= 0.01) continue;

            var sx = s.scale * stretch_u, sy = s.scale * stretch_v;
            var rx = max(1, half_sw * sx), ry = max(1, half_sh * sy);

            var off_local_u = (half_sw - off_u) * sx;
            var off_local_v = (half_sh - off_v) * sy;
            var cen_u = s.x + ( ca * off_local_u - sa * off_local_v);
            var cen_v = s.y + ( sa * off_local_u + ca * off_local_v);

            var du = _u - cen_u, dv = _v - cen_v;
            var u  =  ca * du + sa * dv;
            var v  = -sa * du + ca * dv;

            var d2 = (sqr(u)/sqr(rx)) + (sqr(v)/sqr(ry));
            if (!got_any || d2 < min_d2) {
                min_d2 = d2; got_any = true;
                if (min_d2 <= 0.0) return 0.0;
            }
        }
    }

    if (!got_any) return 1.0;

    var d = sqrt(max(0.0, min_d2)); // 1.0 = ellipse edge
    var c = max(0.0, shade_core_rel);
    var f = max(c + 0.01, shade_full_rel);

    if (d <= c) return 0.0;
    if (d >= f) return 1.0;

    var t = (d - c) / (f - c);
    t = t * t * (3 - 2 * t);
    t = power(clamp(t, 0, 1), shade_curve_pow);
    return t;
};

// --- lightweight phase for wiggle ---
phase = irandom(100000) * 0.0001;
