// --- Timing (seconds) defaults ---
life_sec      = 1.84;      // spawner can override after creation
anim_frac     = 0.40;      // 40% of life animating
anim_duration = max(0.001, life_sec * anim_frac);

// Motion/appearance
rise_total   = 28;
sprite_index = spr_level_up;
image_index  = 0;
image_speed  = 0;          // manual frame drive in Step
image_alpha  = 1;

// Precompute last frame index
last_frame = max(0, sprite_get_number(sprite_index) - 1);

// Position baseline (set defaults unconditionally; spawner may override later)
base_x = x;
base_y = y;

// Timer
age_sec = 0;

// Play SFX once
audio_play_sound(snd_level_up, 1, false);
