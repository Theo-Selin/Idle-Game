/// oAmbienceGlade.Step

// --- Auto day/night sync (cheap, only triggers on flip) ---
var want_mode = (variable_global_exists("is_night") && global.is_night)
                ? AMBIENCE_MODE.NIGHT
                : AMBIENCE_MODE.DAY;
if (want_mode != mode) {
    set_ambience_mode(want_mode); // re-tints existing motes + adjusts glow
}

// Occasionally try to spawn, but keep it sparse
if (++_spawn_tick >= spawn_try_steps) {
    _spawn_tick = 0;
    if (random(1) < spawn_chance) {
        var cam = view_camera[0];
        var x1 = camera_get_view_x(cam), y1 = camera_get_view_y(cam);
        var w  = camera_get_view_width(cam), h  = camera_get_view_height(cam);
        _spawn_mote_at(x1 + random(w), y1 + random(h));
    }
}

// Update motes
var cam = view_camera[0];
var vx1 = camera_get_view_x(cam), vy1 = camera_get_view_y(cam);
var vw  = camera_get_view_width(cam), vh  = camera_get_view_height(cam);

var margin = edge_margin_pixels;

for (var i = 0; i < max_motes; i++) {
    var m = motes[i];
    if (is_undefined(m) || m == noone) continue;

    m.age++;

    var t = m.age / m.life; // 0..1 lifetime

    // Upward drift with strong late acceleration (t^3)
    var up_now = lerp(m.up0, m.up1, ease_pow_in(t, 3));
    m.y -= up_now;

    // Slither: immediate gentle wiggle
    m.x += sin(m.age * m.freq  + m.phase ) * wiggle_amp_x;
    m.y -= sin(m.age * m.freq2 + m.phase2) * wiggle_amp_y;

    // Recycle if life over or far off-screen
    if (m.age >= m.life
        || m.x < (vx1 - margin) || m.x > (vx1 + vw + margin)
        || m.y < (vy1 - margin) || m.y > (vy1 + vh + margin)) {
        motes[i] = noone;
        continue;
    }

    motes[i] = m;
}
