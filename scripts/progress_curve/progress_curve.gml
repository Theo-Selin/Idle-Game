/// @function progress_xp_to_next(level)
/// @desc Tweak one function = whole game feel changes.
/// Fast early levels, then steady growth for idle pacing.
function progress_xp_to_next(_level) {
    // 50, 59, 70, 83, ... nice smooth growth
    return floor(50 * power(1.18, max(1, _level) - 1));
}
