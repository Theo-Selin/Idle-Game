goto_portal_id = PORTAL_HOME_OUTSIDE;
glow_beam_width  = 230;
glow_beam_height = 256;
glow_rotation = 270;

// Example Creation Code on a portal that needs Combat level 5:
req_skill = "combat";   // or "chopping" (must match global.progress.skills keys)
req_level = 15;

// Optional visuals:
lock_sprite = spr_lock_small; // small lock icon sprite (optional)
lock_offset_y = 0;          // vertical offset for the lock+text above the portal
lock_offset_x = 32;
lock_text_color = make_color_rgb(255, 245, 140);