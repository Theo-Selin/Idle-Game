function tile_within_bounds(tx, ty) {
    return (tx >= 0 && ty >= 0 && tx < global.path_grid_width && ty < global.path_grid_height);
}