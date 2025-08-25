function start_crafting(recipe) {
    // Block if already crafting
    if (global.crafting_in_progress) return;

    // Block if not enough ingredients (checks persisted inventory)
    if (!can_craft(recipe)) {
        show_debug_message("❌ Not enough materials to craft: " + string(recipe.name));
        audio_play_sound(snd_deny, 1, false);
        return;
    }

    global.crafting_in_progress = true;
    global.crafting_recipe = recipe;
    global.crafting_progress = 0;

    play_impact_sound(snd_crafting_anvil);
}
