/// oDamageFloat — Create
value        = 0;          // number or string (e.g., "MISS")
kind         = "hit";      // "hit" | "crit" | "heal" | "block" | "miss"
lifespan     = 32;         // shorter than XP popups; feels snappier
timer        = 0;
alpha        = 1;

// Motion
vx           = irandom_range(-15, 15) * 0.02; // small horizontal drift
vy           = -1.1;                          // initial upward kick
gravity      = 0.06;                          // slows ascent then drops a touch
friction     = 0.92;                          // damp side drift
sway_amp     = 0.8;                           // subtle sine sway
sway_theta   = irandom_range(0, 628) * 0.01;  // random starting phase
sway_speed   = 0.18;

// Scale / punch
scale_base   = 1.0;
scale_peak   = 1.25;       // quick punch then ease back
scale_end    = 0.95;       // settle slightly smaller
punch_time   = 6;          // frames for punch

// Style colors (set by script; defaults)
col_start    = c_white;
col_end      = c_white;

// Rotation (very small—keeps it readable)
rot          = irandom_range(-5, 5);
rot_speed    = 0.0;

// Background (soft)
bg_enabled   = false; // damage numbers usually don’t need it; can toggle per instance
bg_color     = c_black;
bg_opacity   = 0.35;
bg_pad_x     = 3;
bg_pad_y     = 1;
bg_rounded   = true;

// Draw
depth        = -300;       // above popups

// Font: reuse your popup font to avoid missing resources
font_damage  = fDamageBold;

// Precomputed string
label        = string(value);

// World-anchored: damage numbers DO NOT follow targets (classic feel)
