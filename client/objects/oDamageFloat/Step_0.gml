/// oDamageFloat — Step
// Motion
x += vx + sin(sway_theta) * sway_amp * 0.05;
y += vy;
vy += gravity;
vx *= friction;
sway_theta += sway_speed;

// Lifespan / fade
timer++;
var t = clamp(timer / lifespan, 0, 1);
alpha = 1 - t;

// Scale punch → settle
var sc;
if (timer <= punch_time) {
    var p = timer / punch_time;      // 0..1
    // easeOutBack-like punch
    sc = lerp(scale_base, scale_peak, (1 - (1 - p)*(1 - p)));
} else {
    var q = (timer - punch_time) / max(1, (lifespan - punch_time));
    sc = lerp(scale_peak, scale_end, q*q); // ease towards end
}
image_xscale = sc;
image_yscale = sc;

// Tiny rotation relax (optional)
rot += rot_speed;

// Done
if (timer >= lifespan) instance_destroy();
