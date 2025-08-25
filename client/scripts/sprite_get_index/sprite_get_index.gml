/// Feather ignore GM1045    // suppress internal "Asset vs Asset.GMSprite" mismatch here

/// @func sprite_get_index(name)
/// @desc Strong-typed wrapper around asset_get_index for sprites.
/// @param {String} name
/// @return {Asset.GMSprite}   // what callers see & what draw_sprite expects
function sprite_get_index(name) {
    var _id = asset_get_index(name);

    // Optional safety while developing (remove if you want zero overhead):
    if (_id != -1 && asset_get_type(_id) != asset_sprite) {
        show_debug_message("sprite_get_index('" + string(name) + "') is not a sprite asset.");
    }

    return _id; // return the correct asset index
}
