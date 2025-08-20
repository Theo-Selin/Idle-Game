// Spawning config
spawn_interval = 120;   // steps between spawn attempts
spawn_timer    = 0;
spawn_limit    = 12;

// What to spawn (make this configurable per spawner/room)
enemy_object = oEnemy;  // <— default; set to any child like oSlime/oGoblin in Room Editor

// Track enemies spawned by THIS spawner (multiple spawners are safe)
spawned_enemies = [];
