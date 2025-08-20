/// oFollowerFlame.Step
var dt = clamp(delta_time / 1000000.0, 0.000001, 0.1);

// Reacquire player if needed
if (!instance_exists(target) || target.object_index != oPlayer) {
    _reacq -= dt;
    if (_reacq <= 0) {
        target = object_exists(oPlayer) ? instance_find(oPlayer, 0) : noone;
        _reacq = 0.5;
    }
}

// ===== Fade progress (smoothstep) =====
if (fade_state == 1) {
    fade_t += dt / spawn_fade_in_s;
    if (fade_t >= 1) { fade_t = 1; fade_state = 0; }
} else if (fade_state == -1) {
    fade_t -= dt / despawn_fade_out_s;
    if (fade_t <= 0) { instance_destroy(); exit; }
}
var fade_k = fade_t * fade_t * (3 - 2 * fade_t); // smoothstep(0..1)

// ===== Target anchor (head) =====
var hx = x, hy = y;
if (instance_exists(target)) {
    var head_off = head_offset_px;
    if (variable_instance_exists(target, "head_height_px")) head_off = target.head_height_px;
    hx = target.x;
    hy = target.y - head_off - elevate_px;

    // --- MOVEMENT-FIRST direction (safe reads) ---
    var move_lr = 0; // +1=right, -1=left
    var _has_hs = variable_instance_exists(target, "hspeed");
    var _hs     = _has_hs ? variable_instance_get(target, "hspeed") : undefined;
    if (_has_hs && is_real(_hs) && abs(_hs) > 0.01) {
        move_lr = sign(_hs);
    } else {
        var _has_hsp = variable_instance_exists(target, "hsp");
        var _hsp     = _has_hsp ? variable_instance_get(target, "hsp") : undefined;
        if (_has_hsp && is_real(_hsp) && abs(_hsp) > 0.01) {
            move_lr = sign(_hsp);
        } else {
            var dx = target.x - __prev_tx;
            if (abs(dx) > 0.25) move_lr = sign(dx);
        }
    }
    if (move_lr != 0) __last_move_lr = move_lr;
    __prev_tx = target.x;

    // Opposite side of last movement
    side_sign_target = -__last_move_lr;
}

// Smooth side switching
var k_side = 1.0 - power(2, -dt / max(0.001, side_switch_half_s));
side_sign  = clamp(side_sign + (side_sign_target - side_sign) * k_side, -1, 1);

// ===== Side (radial) slither =====
ph_side += (2 * pi) * side_slither_sine_hz * dt;
var side_sine = side_slither_sine_amp_px * sin(ph_side);

side_slither_timer -= dt;
if (side_slither_timer <= 0) {
    side_slither_tgt   = random_range(-side_slither_rand_amp_px, side_slither_rand_amp_px);
    side_slither_timer = random_range(side_slither_target_min_s, side_slither_target_max_s);
}
var k_side_slew = 1.0 - power(2, -dt / max(0.001, side_slither_slew_half_s));
side_slither_cur += (side_slither_tgt - side_slither_cur) * k_side_slew;

var radial     = side_radius_px + side_sine + side_slither_cur;
var radial_max = side_radius_px + side_slither_rand_amp_px + side_slither_sine_amp_px;
radial = clamp(radial, side_min_radius_px, radial_max);
var off_x = side_sign * radial;

// ===== Vertical-only slither =====
ph_sine += (2 * pi) * slither_sine_hz * dt;
var slither_sine = slither_sine_amp_px * sin(ph_sine);

slither_timer -= dt;
if (slither_timer <= 0) {
    slither_tgt   = random_range(-slither_rand_amp_px, slither_rand_amp_px);
    slither_timer = random_range(slither_target_min_s, slither_target_max_s);
}
var k_slew = 1.0 - power(2, -dt / max(0.001, slither_slew_half_s));
slither_cur += (slither_tgt - slither_cur) * k_slew;

// Tiny bob
ph_bob += (2 * pi) * bob_hz * dt;
var bob = bob_amp_px * sin(ph_bob);

// ===== Subtle swirl around the head while fading =====
// angle advance
swirl_deg += 360 * swirl_hz * dt;
// radius eases from big→small during fade-in (and small→big when fading out)
var swirl_r = lerp(swirl_radius_start_px, swirl_radius_end_px, fade_k);
var swirl_ox = dcos(swirl_deg) * swirl_r;
var swirl_oy = dsin(swirl_deg) * swirl_r;

// Final target (base follow + swirl)
var tx = hx + off_x + swirl_ox;
var ty = hy + slither_sine + slither_cur + bob + swirl_oy;

// Exponential follow (half-time smoothing)
var k_follow = 1.0 - power(2, -dt / max(0.001, follow_half_time));
x += (tx - x) * k_follow;
y += (ty - y) * k_follow;

// ===== Flicker & final appearance =====
ph1 += (2 * pi) * flicker_hz1 * dt;
ph2 += (2 * pi) * flicker_hz2 * dt;

var f = 0.5 + 0.5 * (0.7 * sin(ph1) + 0.3 * sin(ph2 + 1.7));
f = clamp(f, 0, 1);

// Soft growth + fade
scale_now = base_scale * (1.0 + 0.05 * (1.0 - fade_k)) * (1.0 + scale_flicker_amp * ((f - 0.5) * 2.0));
alpha_now = (alpha_base * (0.82 + 0.38 * f)) * fade_k;