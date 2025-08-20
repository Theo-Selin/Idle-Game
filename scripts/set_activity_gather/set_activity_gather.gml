/// set_activity_gather(target_instance)
/// Reads simple data from the target to compute a per-sec rate.
function set_activity_gather(target) {
    // Defaults if target doesn’t expose these fields
    var resource_id = "oak_log";
    var cycle_secs  = 1.2; // seconds per successful gather loop
    var yield_per   = 1;   // items per cycle

    if (instance_exists(target)) {
        if (variable_instance_exists(target, "resource_id")) resource_id = target.resource_id;
        if (variable_instance_exists(target, "gather_cycle_secs")) cycle_secs = max(0.05, target.gather_cycle_secs);
        if (variable_instance_exists(target, "yield_per_cycle"))    yield_per = max(0, target.yield_per_cycle);
    }

    // Validate resource id via your item DB
    var item_def = variable_struct_get(global.item_data, resource_id);
    if (is_undefined(item_def)) {
        // Fallback to oak_log if the target has bad/missing data
        resource_id = "oak_log";
    }

    global.save.activity.type       = "gather";
    global.save.activity.portal_id  = global.current_portal;
    global.save.activity.resource_id = resource_id;
    global.save.activity.per_sec    = (cycle_secs <= 0) ? 0 : (yield_per / cycle_secs);

    global.__save_dirty = true;
}
