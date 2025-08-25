/// oFollowerFlame.Create

// --- Singleton guard & registration ---
// If another flame is already registered, this one self-destructs to prevent doubles.
if (instance_exists(global.fx_follow_flame) && global.fx_follow_flame != id) {
    instance_destroy();
    exit;
}
// Claim the global handle so future spawns are blocked correctly.
global.fx_follow_flame = id;

// Target to follow (player)
target = object_exists(oPlayer) ? instance_find(oPlayer, 0) : noone;

// ---- Positioning / smoothing ----
head_offset_px       = 24;
elevate_px           = 20;
side_radius_px       = 32;
side_min_radius_px   = 32;
follow_half_time     = 0.3;

// ---- Side switching (opposite of LAST MOVE direction) ----
side_switch_half_s   = 0.12;
side_sign            = 1.0;
side_sign_target     = 1.0;

// Track last *movement* direction ( +1=right, -1=left )
__prev_tx        = instance_exists(target) ? target.x : x;
__last_move_lr   = +1;
if (instance_exists(target)) {
    if (variable_instance_exists(target, "image_xscale")) {
        __last_move_lr = (target.image_xscale >= 0) ? +1 : -1;
    } else if (variable_instance_exists(target, "facing_right")) {
        __last_move_lr = (target.facing_right ? +1 : -1);
    } else if (variable_instance_exists(target, "direction")) {
        __last_move_lr = (dcos(target.direction) >= 0) ? +1 : -1;
    }
}
side_sign        = -__last_move_lr;
side_sign_target = side_sign;

// ---- Visuals (tiny fairy) ----
base_scale        = 0.16;
scale_flicker_amp = 0.10;
alpha_base        = 1;

// Warm fairy-fire palette
col_core = make_color_rgb(255, 230, 140);
col_mid  = make_color_rgb(255, 180,  80);
col_glow = make_color_rgb(255, 110,  50);

// ---- Vertical slither (only up/down), with random drift ----
slither_sine_amp_px   = 7;
slither_sine_hz       = 0.55;
slither_rand_amp_px   = 10;
slither_target_min_s  = 0.35;
slither_target_max_s  = 1.10;
slither_slew_half_s   = 0.15;

// ---- Side (radial) slither on the current side ----
side_slither_sine_amp_px  = 6;
side_slither_sine_hz      = 0.45;
side_slither_rand_amp_px  = 10;
side_slither_target_min_s = 0.45;
side_slither_target_max_s = 1.20;
side_slither_slew_half_s  = 0.18;

// Tiny bobbing (breathing)
bob_amp_px = 1.0;
bob_hz     = 0.6;

// Flicker (brightness) frequencies (Hz)
flicker_hz1 = 9.0;
flicker_hz2 = 12.5;

// Phases
ph_sine  = random(2 * pi);
ph_side  = random(2 * pi);
ph_bob   = random(2 * pi);
ph1      = random(2 * pi);
ph2      = random(2 * pi);

// Random slither state (vertical)
slither_cur   = 0.2;
slither_tgt   = random_range(-slither_rand_amp_px, slither_rand_amp_px);
slither_timer = random_range(slither_target_min_s, slither_target_max_s);

// Random side-slither state (radial)
side_slither_cur   = 0.2;
side_slither_tgt   = random_range(-side_slither_rand_amp_px, side_slither_rand_amp_px);
side_slither_timer = random_range(side_slither_target_min_s, side_slither_target_max_s);

// Cache sprite
_spr = sprite_exists(spr_mote_flare) ? spr_mote_flare : -1;

// Start near player if available
if (instance_exists(target)) {
    x = target.x;
    y = target.y - head_offset_px - elevate_px;
}

// ------- Subtle swirl + fade parameters -------
spawn_fade_in_s      = 0;   // slow, smooth
despawn_fade_out_s   = 2;
fade_t               = 0.0;    // 0..1
fade_state           = 1;      // 1=in, 0=hold, -1=out

swirl_hz             = 200;   // gentle angular speed (revs/sec)
swirl_radius_start_px= 1000;     // start wider then settle
swirl_radius_end_px  = 6;      // tiny residual swirl at rest
swirl_deg            = irandom(359);

// Public helpers (optional)
function flame_fade_in(_dur)  { if (is_real(_dur)) spawn_fade_in_s = max(0.05, _dur);  fade_state = 1; }
function flame_fade_out(_dur) { if (is_real(_dur)) despawn_fade_out_s = max(0.05, _dur); fade_state = -1; }

// Outputs
scale_now = base_scale;
alpha_now = alpha_base;

// Reacquire timer if player is recreated
_reacq = 0.0;
