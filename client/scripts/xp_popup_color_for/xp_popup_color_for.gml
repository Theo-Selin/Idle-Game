/// @function xp_popup_color_for(skill)
/// @returns a color for the given skill
function xp_popup_color_for(_skill) {
    switch (_skill) {
        case "combat":   return make_color_rgb(170, 200, 250);
        case "woodcutting": return make_color_rgb(90, 220, 120);
        case "mining":   return make_color_rgb(90, 220, 120);
        default:         return c_aqua;
    }
}
