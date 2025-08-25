/// @function progress_defaults()
/// @desc Returns a fresh default progress struct (skills, levels, xp, meta).
function progress_defaults() {
    return {
        version: 1,              // future-proofing for migrations
        autosave_cooldown: 0,    // internal debounce timer (frames)
        autosave_cooldown_max: 15, // ~0.25s @60fps

        skills: {
            combat:   { level: 1, xp: 0 },
            woodcutting: { level: 1, xp: 0 },
            // Add more later (e.g., mining) with a single line:
            // mining: { level: 1, xp: 0 },
        }
    };
}
