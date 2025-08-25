/// @function fade_in_sound(sound_id, target_volume, duration_ms)
/// @desc Fades in a sound over time. If the sound is not playing, starts it at volume 0.
/// @param sound_id The sound asset to fade in.
/// @param target_volume Final volume to reach (0.0 to 1.0).
/// @param duration_ms Fade duration in milliseconds.

function fade_in_sound(sound_id, target_volume, duration_ms) {
    if (!audio_is_playing(sound_id)) {
        audio_play_sound(sound_id, 0, true);          // Priority 0, looped
        audio_sound_gain(sound_id, 0, 0);             // Start silent
    }

    audio_sound_gain(sound_id, target_volume, duration_ms); // Fade in over time
}
