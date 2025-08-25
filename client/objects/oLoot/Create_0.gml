/// oLoot Create Event
loot_type = "oak_log";     // string identifier
loot_amount = 1;           // how much of the resource
pickup_delay = 60;         // frames before it can be collected
timer = 0;
collected = false;
depth = 100

// Pick up
fly_to_player = false;
fly_speed = 0.1; // Controls interpolation speed
fade_alpha = 1; // Starts fully visible

drop_timer = 0;
drop_duration = 120; // around half a second at 60fps — visually satisfying
is_dropping = true;
drop_radius = 16 + random(128); // 16–32 px spread
drop_angle = random(360);
drop_start_x = x;
drop_start_y = y;
drop_target_x = x + lengthdir_x(drop_radius, drop_angle);
drop_target_y = y + lengthdir_y(drop_radius, drop_angle);

shadow_visible = true;

hover_timer = random_range(0, 2 * pi); // offset for variation
hover_amplitude = 3; // pixels up/down
hover_speed = 0.05;  // speed of hover cycle

start_y_offset = -28; // visually pops from the top of the tree
fade_alpha = 0;
scale = 0.5; // starts small, grows during drop



// Lookup sprite dynamically
if (loot_type == "oak_log") sprite_index = spr_oak_log;
if (loot_type == "mushroom") sprite_index = spr_mushroom;
if (loot_type == "coin_copper") sprite_index = spr_coin_copper;
if (loot_type == "cloth") sprite_index = spr_cloth;
//else if (loot_type == "stone") sprite_index = sStone;
//else if (loot_type == "coin") sprite_index = sCoin;
// Optional: use a loot_map or switch-case
