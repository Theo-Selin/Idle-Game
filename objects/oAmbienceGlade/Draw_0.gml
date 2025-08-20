/// oAmbienceGlade.Draw
// Put this object on a back layer or give it a negative depth to draw behind gameplay.

// Keep the pipeline clean
draw_set_alpha(1);
gpu_set_blendmode(bm_normal);

for (var i = 0; i < max_motes; i++) {
    var m = motes[i];
    if (is_undefined(m) || m == noone) continue;

    // -------- Lifetime fade --------
    var t = m.age / m.life; // 0..1

    // Fade-in envelope (0..1)
    var ain = (t < fade_in_frac)
        ? (1 - cos((t / max(0.0001, fade_in_frac)) * (pi / 2))) // sine-in
        : 1.0;

    // Fade-out envelope (0..1)
    var aout = (t > 1.0 - fade_out_frac)
        ? (1.0 - (1 - cos(((t - (1.0 - fade_out_frac)) / max(0.0001, fade_out_frac)) * (pi / 2))))
        : 1.0;

    // Combined alpha for the mote right now
    var a = m.mid_alpha * ain * aout;

    // ---------- Core (normal blend) ----------
    if (a > 0.001) {
        if (sprite_exists(spr_mote_flare)) {
            draw_sprite_ext(spr_mote_flare, 0, m.x, m.y, m.scale, m.scale, 0, m.color, a);
        } else {
            draw_circle_color(m.x, m.y, max(1, 2 * m.scale), m.color, m.color, false);
        }
    }

    // ---------- Glow halo (additive) ----------
    if (glow_enabled) {
        var pulse = 1.0 + glow_pulse_amp * sin(m.age * glow_pulse_freq + m.glow_phase);
        var ga = a * m.glow_base * pulse; // halo alpha scales with current core 'a'

        if (ga > 0.001) {
            gpu_set_blendmode(bm_add);

            if (sprite_exists(spr_mote_flare)) {
                draw_sprite_ext(
                    spr_mote_flare, 0, m.x, m.y,
                    m.scale * glow_scale_mult, m.scale * glow_scale_mult,
                    0, m.color, ga
                );
            } else {
                draw_circle_color(m.x, m.y, max(2, 4 * m.scale * glow_scale_mult), m.color, m.color, false);
            }

            gpu_set_blendmode(bm_normal);
        }
    }
}

// Restore state
draw_set_alpha(1);
gpu_set_blendmode(bm_normal);
