/// @function play_impact_sound
/// @desc Play a one‑shot sound with slight pitch variation.
/// @param {Asset.GMSound} snd
/// @param {real} [vol=1]
/// @param {real} [pitch_min=0.92]
/// @param {real} [pitch_max=1.08]
/// @returns {Id.Sound}
function play_impact_sound(snd, vol, pitch_min, pitch_max)
{
    // ---- Defaults (robust for omitted args) ----
    if (is_undefined(vol))       vol = 1;
    if (is_undefined(pitch_min)) pitch_min = 0.9;
    if (is_undefined(pitch_max)) pitch_max = 1.1;

    // ---- Validate sound asset ----
    if (is_undefined(snd) || snd == -1) {
        show_debug_message("⚠️ play_impact_sound: Invalid or missing sound asset");
        return -1; // audio instance id on failure
    }

    // ---- Play and vary pitch ----
    // priority = vol (0..1). Not looping.
    var inst = audio_play_sound(snd, clamp(vol, 0, 1), false);
    if (inst != -1) {
        audio_sound_pitch(inst, random_range(pitch_min, pitch_max));
    }
    return inst;
}
