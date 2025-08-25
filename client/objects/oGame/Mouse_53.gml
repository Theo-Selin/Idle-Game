/// Global Left Pressed
if (global.ui_mouse_block) exit;

var _player = instance_find(oPlayer, 0);
if (!instance_exists(_player)) exit;

with (oTarget) {
    if (variable_instance_exists(id, "owner") && owner == _player) instance_destroy();
}

var gatherable    = instance_position(mouse_x, mouse_y, oSolid);
var door          = instance_position(mouse_x, mouse_y, oDoor);
var combat_target = instance_position(mouse_x, mouse_y, oEnemy);

if (gatherable != noone && gatherable.is_gatherable) {
    set_target_action(_player, gatherable, "gather");
}
else if (door != noone) {
    show_debug_message("🚪 Door clicked: " + string(door));
    set_target_action(_player, door, "door");
}
else if (combat_target != noone && combat_target.targetable) {
    show_debug_message("⚔️ Slime clicked: " + string(combat_target));
    set_target_action(_player, combat_target, "combat");
}
else {
    var _temp = instance_create_layer(mouse_x, mouse_y, "Instances", oTarget);
    _temp.x = floor(mouse_x / global.grid_cell_size) * global.grid_cell_size + global.grid_cell_size * 0.5;
    _temp.y = floor(mouse_y / global.grid_cell_size) * global.grid_cell_size + global.grid_cell_size * 0.5;
    _temp.owner = _player;
    set_target_action(_player, _temp, "move");
}
