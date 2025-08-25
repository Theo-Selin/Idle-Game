/// oEnemy Step Event

// --- SPAWN FADE-IN ---
if (spawn_fading) {
    spawn_fade_timer++;
    var t = spawn_fade_timer / max(1, spawn_fade_duration);
    var eased = 1 - power(1 - clamp(t, 0, 1), 2);
    image_alpha = eased;
    targetable  = false;

    if (t >= 1) {
        spawn_fading = false;
        image_alpha  = 1;
        targetable   = true;
    }
}

// === DEATH HANDLING ===
if (is_dead) {
    targetable = false;
    if (!death_started) {
        death_started = true;
        state = "dead";
        anim_state = "death";
        image_index = 0;
        image_alpha = 1;

        var death_sprite = get_anim_sprite(base_sprites, "death", anim_dir);
        if (death_sprite != -1) sprite_index = death_sprite;

        if (path != -1) path_delete(path);
        if (instance_exists(path_target)) instance_destroy(path_target);
        path_target = noone;
        path_active = false;
    }

    if (image_index >= image_number - 1) {
        image_speed = 0;
        death_timer++;
        if (death_timer > 10) {
            image_alpha -= death_fade_speed;
            if (image_alpha <= 0) instance_destroy();
        }
    }
    exit;
}

// === HIT REACTION HANDLING (placed early!) ===
if (is_hit) {
    if (hit_timer == hit_flash_duration) {
        var hit_sprite = get_anim_sprite(base_sprites, "get_hit", anim_dir);
        if (hit_sprite != -1) { sprite_index = hit_sprite; image_index = 0; }
    }

    hit_shake_x = irandom_range(-2, 2);
    hit_shake_y = irandom_range(-2, 2);
    hit_timer--;

    if (is_dead) {
        if (!death_started) {
            death_started = true;
            anim_state = "death";
            anim_dir = (last_x < 0) ? "left" : "right";
            var death_sprite2 = get_anim_sprite(base_sprites, "death", anim_dir);
            if (death_sprite2 != -1) { sprite_index = death_sprite2; image_index = 0; image_speed = 0.3; }
        }
        if (image_index >= image_number - 1) {
            death_timer++;
            if (death_timer > 10) {
                if (object_index == oEnemy) instance_destroy();
                else if (object_index == oPlayer) show_debug_message("💀 Player died – insert respawn logic here");
            }
        }
        exit;
    }

    if (hit_timer <= 0) {
        is_hit = false; hit_shake_x = 0; hit_shake_y = 0;
        if (state == "combat") {
            var idle_sprite = get_anim_sprite(base_sprites, combat_anim + "_idle", anim_dir);
            if (idle_sprite != -1) { sprite_index = idle_sprite; image_index = 0; image_speed = 1; }
        } else {
            var spr_after = get_anim_sprite(base_sprites, anim_state, anim_dir);
            if (spr_after != -1) { sprite_index = spr_after; image_index = 0; image_speed = 1; }
        }
    }
    exit;
}

// === 1. SAFETY CHECK ===
if (!variable_instance_exists(id, "is_dying")) {
    show_debug_message("❌ oEnemy missing required variables: " + string(id));
    exit;
}

// === 2. DEATH FADE AND CLEANUP ===
if (is_dying) {
    image_alpha -= death_fade_speed;
    if (image_alpha <= 0) {
        if (path != -1) path_delete(path);
        if (instance_exists(path_target)) instance_destroy(path_target);
        instance_destroy();
    }
    exit;
}

// === 3. PLAYER/LOCK RESOLUTION (determine targeting first) ===
var player_exists = variable_global_exists("player") && instance_exists(global.player);
var p = player_exists ? global.player : noone;
var being_targeted = false;

if (player_exists) {
    being_targeted = (p.target == id) && (p.action_type == "combat" || p.state == "combat" || p.state == "moving_to_combat");

    if (being_targeted) {
        // Engage lock and initialize combat once
        is_locked = true;
        combat_lock_owner = p;
        if (variable_instance_exists(p, "lock_token")) combat_lock_token = p.lock_token;

        if (state != "combat" && state != "dying" && state != "dead") state = "combat";

        // Ensure combat loop is initialized so the enemy can take turns later
        if (!combat_started) {
            combat_started = true;
            combat_phase   = "idle";
            combat_timer   = 0;
            wait_timer     = 0;

            // Safe default for turn owner if unset
            if (global.turn_owner != "player" && global.turn_owner != "enemy") {
                global.turn_owner = "player";
                global.turn_timer = 0;
                global.turn_active = false;
            }
        }
    } else {
        // Not targeted anymore -> unlock & go idle if we were in combat
        if (is_locked && combat_lock_owner == p) {
            is_locked = false;
            combat_lock_owner = noone;
        }
        if (state == "combat") {
            state = "idle";
            combat_started = false;
            combat_phase = "idle";
            combat_timer = 0;
            wait_timer = 0;
        }
    }
} else {
    // No player -> unlock
    is_locked = false;
    combat_lock_owner = noone;
    if (state == "combat") {
        state = "idle";
        combat_started = false;
        combat_phase = "idle";
        combat_timer = 0;
        wait_timer = 0;
    }
}

// === 4. APPLY LOCK EFFECTS (kill motion while locked; no early exit) ===
if (is_locked) {
    if (path != -1) path_end();
    if (path != -1) { path_delete(path); path = -1; }
    if (instance_exists(path_target)) instance_destroy(path_target);
    path_target = noone;
    path_active = false;
    roam_timer = 0;

    // Face player visually
    if (player_exists) {
        anim_dir = (p.x < x) ? "left" : "right";
        anim_state = "idle";
    }
}

// === 5. PATH COMPLETION CHECK (always safe to run) ===
if (path_active) {
    if (!instance_exists(path_target)) {
        path_end(); path_active = false; path_target = noone;
        state = "idle"; roam_timer = 0; roam_delay = irandom_range(60, 180);
    }
    else if (point_distance(x, y, path_target.x, path_target.y) < 4) {
        path_end(); path_active = false; instance_destroy(path_target); path_target = noone;
        state = "idle"; roam_timer = 0; roam_delay = irandom_range(60, 180);
    }
}

// === 6. ROAM AI (only when allowed; never while locked or in combat) ===
var allow_ai = ai_enabled && !is_locked && state != "combat" && state != "moving_to_combat";

if (allow_ai && !path_active) {
    roam_timer++;
    if (roam_timer >= roam_delay) {
        roam_timer = 0;
        roam_delay = irandom_range(60, 180);

        var found = false;
        var attempts = 10;
        var cx = x div tile_size;
        var cy = y div tile_size;
        var radius = 5;
        var tx, ty;

        repeat (attempts) {
            tx = clamp(cx + irandom_range(-radius, radius), 0, global.path_grid_width - 1);
            ty = clamp(cy + irandom_range(-radius, radius), 0, global.path_grid_height - 1);

            if (
                global.walkable_grid[# tx, ty] == 0 &&
                !(tx >= global.exclusion_min_x && tx <= global.exclusion_max_x &&
                  ty >= global.exclusion_min_y && ty <= global.exclusion_max_y)
            ) {
                found = true;
                break;
            }
        }

        if (found) {
            var px = tx * tile_size + tile_size * 0.5;
            var py = ty * tile_size + tile_size * 0.5;

            if (instance_exists(path_target)) instance_destroy(path_target);
            path_target = instance_create_layer(px, py, "Instances", oTarget_enemy);

            if (path != -1) path_delete(path);
            path = path_add();

            if (mp_grid_path(global.path_grid, path, x, y, px, py, true)) {
                path_start(path, move_speed, path_action_stop, false);
                path_active = true;
                state = "walking";
            } else {
                if (path != -1) { path_delete(path); path = -1; }
                if (instance_exists(path_target)) instance_destroy(path_target);
                path_target = noone;
                state = "idle";
            }
        }
    }
}

// === 7. DIRECTION AND ANIMATION STATE (movement) ===
var dx = x - last_x;
var dy = y - last_y;
var abs_dx = abs(dx);
var abs_dy = abs(dy);
var threshold = 0.25;

if (dx == 0 && dy == 0) {
    anim_state = "idle";
} else {
    anim_state = "walk";
    if (abs_dx > abs_dy + threshold) {
        anim_dir = (dx < 0) ? "left" : "right";
    } else if (abs_dy > abs_dx + threshold) {
        anim_dir = (dy < 0) ? "up" : "down";
    } else {
        anim_dir = (dy > 0) ? "down" : "up";
    }
}

last_x = x;
last_y = y;

// === 8. FACE PLAYER WHEN LOCKED (visual) ===
if (is_locked && player_exists) {
    dx = p.x - x; dy = p.y - y;
    abs_dx = abs(dx); abs_dy = abs(dy);
    anim_state = "idle";
    if (abs_dx > abs_dy + threshold)      anim_dir = (dx < 0) ? "left" : "right";
    else if (abs_dy > abs_dx + threshold) anim_dir = (dy < 0) ? "up"   : "down";
    else                                  anim_dir = (dy > 0) ? "down" : "up";
}

// === 9. COMBAT LOGIC (runs even when locked) ===
if (state == "combat" && player_exists) {
    // Ensure a valid initial turn owner
    if (combat_started && global.turn_owner != "player" && global.turn_owner != "enemy") {
        global.turn_owner = "player";
        global.turn_timer = 0;
        global.turn_active = false;
    }

    // Face player
    anim_dir = (p.x < x) ? "left" : "right";

    switch (combat_phase) {
        case "idle":
            combat_timer++;

            if (!is_hit) {
                var idle_sprite2 = get_anim_sprite(base_sprites, combat_anim + "_idle", anim_dir);
                if (sprite_index != idle_sprite2 && idle_sprite2 != -1) {
                    sprite_index = idle_sprite2;
                    image_index = 0;
                    image_speed = 1;
                }
            }

            // Enemy may act only on its turn, after cooldown, and when player isn't mid-attack
            if (combat_started && global.turn_owner == "enemy" && combat_timer >= combat_cooldown && p.combat_phase == "idle") {
                combat_phase = "attacking";
                combat_timer = 0;

                if (!is_hit) {
                    var atk_sprite = get_anim_sprite(base_sprites, combat_anim, anim_dir);
                    if (atk_sprite != -1) { sprite_index = atk_sprite; image_index = 0; image_speed = 1; }
                }
            }
            break;

			case "attacking":
			    combat_timer++;

			    if (combat_timer == combat_hit_frame) {
			        if (instance_exists(p)) {
			            // Use this enemy's configured base damage; fallback to 1 if unset
			            var base = (!is_undefined(combat_damage)) ? combat_damage : 1;

			            // Resolve with the authoritative function
			            var r = combat_resolve_attack(id, p, base);

			            if (r.hit) {
			                if (variable_instance_exists(p, "take_damage")) {
			                    p.take_damage(r.dmg, id, r.crit); // amount is FINAL; no defense subtraction inside take_damage
			                }

			                // HIT SFX (no whoosh here)
			                if (!is_undefined(snd_hit_default)) play_impact_sound(snd_hit_default);
			                if (r.crit && !is_undefined(snd_hit_crit)) play_impact_sound(snd_hit_crit);
			            } else {
			                // MISS: number + whoosh
			                damage_popup_show(p, 0, "miss");
			                if (!is_undefined(snd_swing_whoosh)) play_impact_sound(snd_swing_whoosh);
			            }
			        }
			    }

			    if (combat_timer >= combat_attack_duration) {
			        combat_phase = "waiting";
			        combat_timer = 0;
			        wait_timer = 0;

			        if (!is_hit) {
			            var idle_sprite3 = get_anim_sprite(base_sprites, combat_anim + "_idle", anim_dir);
			            if (sprite_index != idle_sprite3 && idle_sprite3 != -1) {
			                sprite_index = idle_sprite3;
			                image_index = 0;
			                image_speed = 1;
			            }
			        }
			    }
			break;


        case "waiting":
            wait_timer++;
            if (wait_timer >= 30) {
                combat_phase = "idle";
                combat_timer = 0;
                wait_timer = 0;

                // Hand turn back to player
                global.turn_owner = "player";
                global.turn_timer = 0;
                global.turn_active = false;
            }
            break;
    }
}

// === 10. SPRITE HANDLING (non-combat) ===
if (state != "combat" && is_struct(base_sprites)) {
    var spr_idlewalk = get_anim_sprite(base_sprites, anim_state, anim_dir);
    if (spr_idlewalk != -1 && sprite_index != spr_idlewalk) {
        sprite_index = spr_idlewalk;
        image_index = 0;
    }
}
