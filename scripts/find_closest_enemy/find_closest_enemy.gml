/// find_closest_enemy(x0, y0) -> instance id or noone
function find_closest_enemy(_x0, _y0) {
    // expose the search origin + accumulators on the caller instance
    __scan_x   = _x0;
    __scan_y   = _y0;
    __best     = noone;
    __best_d2  = 1000000000; // large "infinity"

    with (oEnemy) {
        if (!instance_exists(id)) continue;

        // defensively gate "alive" and "targetable"
        var alive_ok  = !variable_instance_exists(id, "hp") || (hp > 0);
        var target_ok = !variable_instance_exists(id, "targetable") || targetable;

        if (alive_ok && target_ok) {
            var dx = x - other.__scan_x;
            var dy = y - other.__scan_y;
            var d2 = dx*dx + dy*dy; // squared distance

            if (d2 < other.__best_d2) {
                other.__best_d2 = d2;
                other.__best    = id;
            }
        }
    }

    var result = __best;

    // tidy up (optional but nice)
    __scan_x  = undefined;
    __scan_y  = undefined;
    __best    = undefined;
    __best_d2 = undefined;

    return result;
}
