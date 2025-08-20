/// oCloudShadows.Step
phase += wiggle_speed; // tiny organic motion for multi-lobes

// Movement (pure world space)
var wx = dcos(radtodeg(wind_angle));
var wy = dsin(radtodeg(wind_angle));

for (var i = 0; i < array_length(bands); i++) {
    var B   = bands[i];
    var spd = wind_speed * B.speed;
    var arr = B.blobs;
    for (var j = 0; j < array_length(arr); j++) {
        var s = arr[j];
        s.x += wx * spd;
        s.y += wy * spd;

        // Per-blob spawn fade-in only
        if (blob_spawn_fade && s.local_a < 1.0) {
            s.local_a = min(1.0, s.local_a + blob_fade_speed);
        }

        // Wrap without alpha reset (9-tile draw hides the jump)
        if (s.x < world_l) s.x += world_w; else if (s.x > world_r) s.x -= world_w;
        if (s.y < world_t) s.y += world_h; else if (s.y > world_b) s.y -= world_h;

        arr[j] = s;
    }
    B.blobs = arr;
    bands[i] = B;
}
