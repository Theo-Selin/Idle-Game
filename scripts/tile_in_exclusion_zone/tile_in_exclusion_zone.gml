/// tile_in_exclusion_zone(tx, ty)
function tile_in_exclusion_zone(tx, ty) {
    return (
        tx >= global.exclusion_min_x && tx <= global.exclusion_max_x &&
        ty >= global.exclusion_min_y && ty <= global.exclusion_max_y
    );
}
