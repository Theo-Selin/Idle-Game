/// do_craft(recipe) → bool
function do_craft(recipe) {
    if (!can_craft(recipe)) {
        show_debug_message("❌ Not enough materials to craft: " + string(recipe.name));
        audio_play_sound(snd_deny, 1, false);
        return false;
    }

    // Consume inputs
    for (var i = 0; i < array_length(recipe.input); i++) {
        var req = recipe.input[i];
        if (!remove_from_inventory(string(req.id), req.amount)) {
            // If removal fails mid-way, bail out (you could also rollback here)
            return false;
        }
    }

    // Grant output
    var out = recipe.output;
    collect_loot(string(out.id), out.amount);

    show_debug_message("✨ Crafted: " + string(out.id));
    audio_play_sound(snd_loot_bag, 1, false);
    return true;
}
