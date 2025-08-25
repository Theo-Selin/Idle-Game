function tile_is_blocked(tx, ty) {
    return (
        tx < 0 || ty < 0 || 
        tx >= global.path_grid_width || 
        ty >= global.path_grid_height || 
        global.walkable_grid[# tx, ty] == 1
    );
}