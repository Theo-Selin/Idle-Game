if (!fading_out && fade > 0) {
    fade -= fade_speed;
    if (fade < 0) fade = 0;
}

if (fading_out) {
    fade += fade_speed;
    show_debug_message("🔆 FADE: " + string(fade)); // 👈 Add this line
    if (fade >= 1) {
        fade = 1;
        fading_out = false;

        if (!is_undefined(on_fade_complete)) {
            script_execute(on_fade_complete);
        }
    }
}

