// oTree Create Event
is_gatherable = true;
gather_type = "oak_log";
gather_anim = "chop";
gather_time = 60;         // Time in steps between chops
gather_progress = 0;      // Can be used for upgrades or visual effects later
selected = false;
gather_sound = snd_tree_chop; // Replace with your actual sound asset name
canopy_animate_delay = -1; // Will be used with an alarm
marker_y_offset = -128; // negative = higher above the mask top

// Offline/gather tuning (lightweight defaults)
resource_id = "oak_log";
gather_cycle_secs = 1; // seconds per successful swing
yield_per_cycle = 0.5;

// 🧠 EXP settings owned by the tree (per successful swing)
xp_skill = "woodcutting";
xp_per_hit = 4; // tune per tree type (oak, birch etc.)

// oTree layers
visual_trunk = instance_create_layer(x, y, "tree_trunks", oTreeTrunk);
visual_canopy = instance_create_layer(x, y, "tree_canopies", oTreeCanopy);

/// Define the hit animation behavior
on_gather_hit = function () {
    // 🔊 Play sound effect
    if (audio_exists(gather_sound)) {
        play_impact_sound(snd_tree_chop);
    }

    // 🎓 Award EXP per hit (tree owns the amount)
    progress_award_xp(xp_skill, xp_per_hit);

    // 🟢 XP popup above player's head
    xp_popup_show(xp_skill, xp_per_hit);

    // ⏱ Trigger canopy animation with a slight delay
    canopy_animate_delay = 16;
    alarm[0] = canopy_animate_delay;
};


