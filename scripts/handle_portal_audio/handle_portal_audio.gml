function handle_portal_audio(portal_id) {
    // Fade out all current music/ambience
    audio_sound_gain(snd_music_forest, 0, 1000);
    audio_sound_gain(snd_ambience_birds, 0, 1000);

    // Get struct from portal_data
    if (portal_id < array_length(global.portal_data)) {
        var portal = global.portal_data[portal_id];

        if (is_struct(portal)) {
            if (portal.music != -1) {
                fade_in_sound(portal.music, 0.1, 2000);
            }
            if (portal.ambience != -1) {
                fade_in_sound(portal.ambience, 0.2, 2000);
            }
        }
    } else {
        show_debug_message("⚠ Tried to play audio for unknown portal ID: " + string(portal_id));
    }
}
