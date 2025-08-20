// 1. Hover offset (used only if not dropping)
var hover_offset = 0;
if (!is_dropping) {
    hover_timer += hover_speed;
    hover_offset = sin(hover_timer) * hover_amplitude;
}

// 2. Shadow position fallback
var sx = drop_target_x;
var sy = drop_target_y + 6;

if (sx == 0 && sy == 6) {
    sx = x;
    sy = y + 6;
}

// 3. Draw shadow
if (shadow_visible) {
    draw_set_color(c_black);

    if (is_dropping) {
        // DROP ARC shadow: scale/alpha based on t
        var t = clamp(drop_timer / drop_duration, 0, 1);
        var drop_shadow_scale = lerp(3.0, 1.5, t);     // From large → small
        var drop_shadow_alpha = lerp(0.1, 0.4, t);     // From faint → dark

        draw_set_alpha(drop_shadow_alpha);
        draw_ellipse_color(
            sx - 5 * drop_shadow_scale,
            sy - 3 * drop_shadow_scale,
            sx + 5 * drop_shadow_scale,
            sy + 3 * drop_shadow_scale,
            c_black, c_black, false
        );

    } else {
        // HOVER shadow: looped based on hover height
        var hover_progress = (hover_offset + hover_amplitude) / (2 * hover_amplitude);
        var hover_shadow_scale = lerp(2.0, 1.5, hover_progress);   // Bigger when higher
        var hover_shadow_alpha = lerp(0.1, 0.4, hover_progress);   // Darker when closer

        draw_set_alpha(hover_shadow_alpha);
        draw_ellipse_color(
            sx - 5 * hover_shadow_scale,
            sy - 3 * hover_shadow_scale,
            sx + 5 * hover_shadow_scale,
            sy + 3 * hover_shadow_scale,
            c_black, c_black, false
        );
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
}

// 4. Draw loot sprite
var draw_y = y;
if (!is_dropping) draw_y += hover_offset;

draw_set_alpha(fade_alpha);
draw_sprite_ext(sprite_index, image_index, x, draw_y, scale, scale, 0, c_white, 1);
draw_set_alpha(1);
