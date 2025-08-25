/// oCloudShadows.Draw
var angle_deg = radtodeg(wind_angle);
var ca = dcos(angle_deg), sa = dsin(angle_deg);

// Tangent unit (perpendicular to wind direction) to spread lobes sideways
var tx = -sa, ty = ca;

var ox_list = [-world_w, 0, world_w];
var oy_list = [-world_h, 0, world_h];

for (var i = 0; i < array_length(bands); i++) {
    var B = bands[i], arr = B.blobs;

    for (var j = 0; j < array_length(arr); j++) {
        var s = arr[j];

        var base_a = B.alpha * shadow_master * s.local_a;
        if (base_a <= 0.002) continue;

        // Base ellipse
        var sx_main = s.scale * blob_stretch_x;
        var sy_main = s.scale * blob_stretch_y * s.ymul;

        // 9-tile draw (base + lobes per wrapped copy)
        for (var ix = 0; ix < 3; ix++) {
            var px0 = s.x + ox_list[ix];
            for (var iy = 0; iy < 3; iy++) {
                var py0 = s.y + oy_list[iy];

                // --- main soft blob ---
                draw_set_alpha(base_a);
                draw_sprite_ext(spr_shadow_blob, 0, floor(px0), floor(py0), sx_main, sy_main, angle_deg, shadow_color, 1);

                // --- extra lobes (puffiness) ---
                if (s.lobes > 0) {
                    var pairs = s.lobes; // 2 or 3 typically
                    for (var k = 1; k <= pairs; k++) {
                        var tfrac  = k / (pairs + 1);       // (avoid var name 'frac')
                        var spread = s.lspread * tfrac;
                        var wig    = wiggle_amp_px * dsin((phase + s.seed * 0.001 + k * 0.31) * 360);
                        var off    = spread + wig;

                        // positions on both sides of tangent
                        var ox = tx * off, oy = ty * off;

                        // lobe scale tapers slightly with k
                        var sc_mul = s.lscale * (1.0 - 0.12 * (k - 1));
                        var sx = sx_main * sc_mul, sy = sy_main * sc_mul;

                        // softer than main
                        var a_lobe = base_a * lobe_alpha_mul * (1.0 - 0.08 * (k - 1));
                        draw_set_alpha(a_lobe);

                        // right side
                        draw_sprite_ext(spr_shadow_blob, 0, floor(px0 + ox), floor(py0 + oy), sx, sy, angle_deg, shadow_color, 1);
                        // left side
                        draw_sprite_ext(spr_shadow_blob, 0, floor(px0 - ox), floor(py0 - oy), sx, sy, angle_deg, shadow_color, 1);
                    }
                }
            }
        }
    }
}
draw_set_alpha(1);
