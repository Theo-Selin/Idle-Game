// Refresh equipment data (for icons/anim)
var weapon_id = variable_struct_get(global.equipment_slots, "weapon");
weapon_data   = variable_struct_exists(global.item_data, weapon_id) ? variable_struct_get(global.item_data, weapon_id) : undefined;

var armor_id  = variable_struct_get(global.equipment_slots, "armor");
armor_data    = variable_struct_exists(global.item_data, armor_id)  ? variable_struct_get(global.item_data, armor_id)  : undefined;

var helmet_id = variable_struct_get(global.equipment_slots, "helmet");
helmet_data   = variable_struct_exists(global.item_data, helmet_id) ? variable_struct_get(global.item_data, helmet_id) : undefined;

var ring_1_id = variable_struct_get(global.equipment_slots, "ring_1");
ring_1_data   = variable_struct_exists(global.item_data, ring_1_id) ? variable_struct_get(global.item_data, ring_1_id) : undefined;

var ring_2_id = variable_struct_get(global.equipment_slots, "ring_2");
ring_2_data   = variable_struct_exists(global.item_data, ring_2_id) ? variable_struct_get(global.item_data, ring_2_id) : undefined;

var amulet_id = variable_struct_get(global.equipment_slots, "amulet");
amulet_data   = variable_struct_exists(global.item_data, amulet_id) ? variable_struct_get(global.item_data, amulet_id) : undefined;

var health_id = variable_struct_get(global.equipment_slots, "health");
health_data   = variable_struct_exists(global.item_data, health_id) ? variable_struct_get(global.item_data, health_id) : undefined;

// Recalc final stats when equipment changed
var _eq_sig = string(weapon_id) + "|" + string(armor_id) + "|" + string(helmet_id);
if (__last_eq_sig != _eq_sig) {
    __last_eq_sig = _eq_sig;
    recalc_stats(id);
    // Reset cooldown state so equipping/unequipping never causes an immediate heal
    regen_cd_remaining_ms = regen_interval_ms;
    regen_ready_armed     = false;
}

// Helper: clear the visual target marker safely
function _clear_target_marker() {
    if (instance_exists(target_marker)) { instance_destroy(target_marker); target_marker = noone; }
}

// === Handle death ===
if (is_dead) {
    if (!death_started) {
        death_started = true;
        state = "dead";
        anim_state = "death";
        anim_dir = "down";
        image_index = 0;
        image_alpha = 1;

        var spr = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr != -1) { sprite_index = spr; image_speed = 1; }

        if (path_index != -1) path_end();
        if (path_move != -1) { path_delete(path_move); path_move = -1; }

        _clear_target_marker();
        set_movement_mode("walk");
        show_debug_message("💀 oPlayer death animation started");
    }

    if (image_index >= image_number - 1) {
        image_speed = 0;
        death_timer++;
        if (death_timer > 30) {
            if (instance_exists(oFadeController)) {
                with (oFadeController) {
                    fading_out = true;
                    on_fade_complete = function () { room_restart(); };
                }
            } else room_restart();
            instance_destroy();
        }
    }
    if (death_timer > 30) {
        image_alpha -= 0.05;
        if (image_alpha <= 0) room_restart();
    }
    exit;
}

var dt_ms = delta_time / 1000;

// === PASSIVE HP REGEN: 1-minute cooldown, armed-if-full (correct time units) ===
if (!is_dead) {
    var _has_regen = (hp_regen_per_min > 0);

    if (!_has_regen) {
        // No regen item → neutralize state
        regen_cd_remaining_ms = regen_interval_ms;
        regen_ready_armed     = false;
    } else {
        if (regen_ready_armed) {
            // Cooldown finished while full; heal immediately when HP drops below max
            if (hp < max_hp) {
                var _amt     = max(1, floor(hp_regen_per_min));
                var _missing = max_hp - hp;
                var _apply   = min(_amt, _missing);
                if (_apply > 0) {
                    hp += _apply;
                    damage_popup_show(id, _apply, "heal");
                }
                regen_ready_armed     = false;
                regen_cd_remaining_ms = regen_interval_ms;
            }
        } else {
            // Cooldown running
            regen_cd_remaining_ms -= dt_ms;

            // Handle long frame skips (keep at most one heal per frame if you prefer: add a 'break')
            while (regen_cd_remaining_ms <= 0) {
                if (hp < max_hp) {
                    var _amt2     = max(1, floor(hp_regen_per_min));
                    var _missing2 = max_hp - hp;
                    var _apply2   = min(_amt2, _missing2);
                    if (_apply2 > 0) {
                        hp += _apply2;
                        damage_popup_show(id, _apply2, "heal");
                    }
                    regen_cd_remaining_ms += regen_interval_ms;
                    // break; // uncomment to guarantee at most one heal per frame
                } else {
                    // Full when cooldown ends → arm and wait for damage
                    regen_ready_armed     = true;
                    regen_cd_remaining_ms = 0;
                    break;
                }
            }
        }
    }
}






// === HIT STATE HANDLING ===
if (is_hit) {
    if (anim_state != "get_hit") {
        anim_state = "get_hit";
        image_index = 0;
        image_speed = 1;
        var sprH = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (sprH != -1) sprite_index = sprH;
    }

    if (image_index >= image_number - 1) {
        is_hit = false;
        anim_state = (state == "combat") ? (combat_anim + "_idle") : "idle";
        image_index = 0;
        image_speed = 1;
        var sprHI = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (sprHI != -1) sprite_index = sprHI;
    }
    exit;
}

// World movement / anim (non-combat, non-gather)
if (state != "gathering" && state != "combat") {
    var dx = x - last_x, dy = y - last_y;
    var abs_dx = abs(dx), abs_dy = abs(dy);
    var threshold = 0.25;
    var is_moving = (dx != 0 || dy != 0);

    if (is_moving) {
        if (abs_dx > abs_dy + threshold)      anim_dir = (dx < 0) ? "left" : "right";
        else if (abs_dy > abs_dx + threshold) anim_dir = (dy < 0) ? "up"   : "down";
        else                                  anim_dir = (dy > 0) ? "down" : "up";
    }
    anim_state = is_moving
        ? ((state == "walking" || state == "moving_to_gather" || state == "moving_to_combat" || state == "moving_to_door")
            ? ((move_anim_mode == "run") ? "run" : "walk") : "walk")
        : "idle";

    last_x = x; last_y = y;

    var spr2 = get_anim_sprite(base_sprites, anim_state, anim_dir);
    if (spr2 != -1 && sprite_index != spr2) { sprite_index = spr2; image_index = 0; image_speed = 1; }
}

// ✅ MOVE: reached target (idle target object)
if (action_type == "move" && target != noone) {
    if (point_distance(x, y, target.x, target.y) < 4) {
        if (path_index != -1) path_end();
        if (path_move != -1) { path_delete(path_move); path_move = -1; }

        _clear_target_marker();
        with (target) instance_destroy();
        target = noone;
        state = "idle";
        anim_state = "idle";

        set_movement_mode("walk");

        var spr3 = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr3 != -1 && sprite_index != spr3) {
            sprite_index = spr3;
            image_index = 0;
            image_speed = 1;
        }
    }
}

// 🪓 GATHER: Move to target point
if (action_type == "gather" && state == "moving_to_gather") {
    var dist = point_distance(x, y, gather_dest_x, gather_dest_y);
    if (dist < 4) {
        if (path_move != -1) { path_end(); path_delete(path_move); path_move = -1; }

        x = gather_dest_x; y = gather_dest_y;

        if (target != noone && instance_exists(target)) anim_dir = (x > target.x) ? "left" : "right";
        else anim_dir = "right";

        set_movement_mode("walk");

        gather_timer = 0;
        gather_phase = "idle";
        state = "gathering";
        anim_state = gather_anim;

        var spr4 = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr4 != -1 && sprite_index != spr4) {
            sprite_index = spr4;
            image_index = 0;
            image_speed = 1;
        }

        show_debug_message("🪓 Reached gather point, starting work");
    }
}

// 🪓 GATHERING LOOP
if (action_type == "gather" && state == "gathering") {

    if (!instance_exists(target) || !target.is_gatherable) {
        state = "idle";
        target = noone;
        gather_phase = "idle";
        gather_timer = 0;
        anim_state = "idle";
        anim_dir = "down";

        set_movement_mode("walk");

        var spr5 = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr5 != -1) {
            sprite_index = spr5;
            image_index = 0;
            image_speed = 1;
        }
        exit;
    }

    anim_dir = (x > target.x) ? "left" : "right";

    switch (gather_phase) {
        case "idle":
            anim_state = gather_anim + "_idle";
            gather_timer++;

            var spr_idle = get_anim_sprite(base_sprites, anim_state, anim_dir);
            if (spr_idle != -1 && sprite_index != spr_idle) {
                sprite_index = spr_idle; image_index = 0; image_speed = 1;
            }

            if (gather_timer >= gather_cooldown) {
                gather_phase = "woodcutting";
                gather_timer = 0;

                anim_state = gather_anim;
                var spr_chop = get_anim_sprite(base_sprites, anim_state, anim_dir);
                if (spr_chop != -1) { sprite_index = spr_chop; image_index = 0; image_speed = 1; }
            }
            break;

        case "woodcutting":
            anim_state = gather_anim;

            if (gather_timer == 0 && !is_undefined(target.on_gather_hit)) target.on_gather_hit();

            gather_timer++;

            if (gather_timer >= gather_chop_duration) {
                gather_timer = 0;
                gather_phase = "idle";

                var offset_x = (x > target.x) ? -24 : 24;
                drop_loot(x, y, target.gather_type, 1, id, offset_x, -64);

                show_debug_message("🪓 Chop! " + target.gather_type);
            }
            break;
    }

    if (point_distance(x, y, gather_dest_x, gather_dest_y) > 48) {
        if (instance_exists(target)) target.selected = false;

        target = noone;
        state = "idle";
        gather_phase = "idle";
        gather_timer = 0;
        anim_state = "idle";
        anim_dir = "down";

        set_movement_mode("walk");

        var spr6 = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr6 != -1) {
            sprite_index = spr6;
            image_index = 0;
            image_speed = 1;
        }
    }
}

// === PLAYER COMBAT ARRIVAL ===
if (state == "moving_to_combat" && point_distance(x, y, combat_dest_x, combat_dest_y) < 2) {
    path_end();
    if (path_move != -1) { path_delete(path_move); path_move = -1; }

    if (target != noone && instance_exists(target)) {
        anim_dir = (x < target.x) ? "right" : "left";
        target.face_target = id;
        target.state = "combat";

        state = "combat";
        action_type = "combat";
        combat_phase = "idle";
        combat_timer = 0;

        anim_state = combat_anim + "_idle";
        var spr7 = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr7 != -1) { sprite_index = spr7; image_index = 0; image_speed = 1; }

        set_movement_mode("walk");

        show_debug_message("🗡️ Combat started with: " + string(target));
    } else {
        state = "idle"; action_type = "none"; target = noone;
        _clear_target_marker();
        set_movement_mode("walk");
    }
}

// === PLAYER COMBAT LOOP ===
if (action_type == "combat" && state == "combat") {
    if (global.turn_owner != "player") exit;

    if (!instance_exists(target)) {
        _clear_target_marker();
        state = "idle";
        target = noone;
        action_type = "none";
        combat_phase = "idle";
        combat_timer = 0;
        anim_state = "idle";
        anim_dir = "down";
        set_movement_mode("walk");

        var spr8 = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr8 != -1) { sprite_index = spr8; image_index = 0; image_speed = 1; }
        exit;
    }

    anim_dir = (x > target.x) ? "left" : "right";

    switch (combat_phase) {
        case "idle":
            combat_timer++;

            if (!is_hit) {
                anim_state = combat_anim + "_idle";
                var spr9 = get_anim_sprite(base_sprites, anim_state, anim_dir);
                if (spr9 != -1 && sprite_index != spr9) {
                    sprite_index = spr9; image_index = 0; image_speed = 1;
                }
            }

            if (combat_timer >= combat_cooldown) {
                combat_phase = "attacking";
                combat_timer = 0;

                if (!is_hit) {
                    anim_state = combat_anim;
                    var sprAtk = get_anim_sprite(base_sprites, anim_state, anim_dir);
                    if (sprAtk != -1) { sprite_index = sprAtk; image_index = 0; image_speed = 1; }
                }
            }
            break;

        case "attacking":
            combat_timer++;

            // 💥 Hit frame
            if (combat_timer == combat_hit_frame && instance_exists(target)) {
                var r = combat_resolve_attack(id, target, combat_damage);


                if (r.hit) {
                    target.take_damage(r.dmg, id, r.crit);
                    if (!is_undefined(snd_hit_default)) play_impact_sound(snd_hit_default);
                    if (r.crit && !is_undefined(snd_hit_crit)) play_impact_sound(snd_hit_crit);
                    if (variable_instance_exists(target, "combat_started")) target.combat_started = true;
                } else {
                    damage_popup_show(target.id, 0, "miss");
					if (!is_undefined(snd_swing_whoosh)) play_impact_sound(snd_swing_whoosh);
                }
            }

            if (combat_timer >= combat_attack_duration) {
                combat_phase = "waiting";
                combat_timer = 0;
                wait_timer   = 0;

                if (!is_hit) {
                    anim_state = combat_anim + "_idle";
                    var spr11 = get_anim_sprite(base_sprites, anim_state, anim_dir);
                    if (spr11 != -1 && sprite_index != spr11) {
                        sprite_index = spr11; image_index = 0; image_speed = 1;
                    }
                }
            }
            break;

        case "waiting":
            wait_timer++;
            if (wait_timer >= 60) {
                combat_phase = "idle";
                combat_timer = 0;
                wait_timer   = 0;

                // Hand off turn
                global.turn_owner  = "enemy";
                global.turn_timer  = 0;
                global.turn_active = false;
            }
            break;
    }

    if (point_distance(x, y, combat_dest_x, combat_dest_y) > 48) {
        _clear_target_marker();
        state = "idle";
        target = noone;
        action_type = "none";
        combat_phase = "idle";
        combat_timer = 0;
        anim_state = "idle";
        anim_dir = "down";
        set_movement_mode("walk");

        var spr12 = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr12 != -1) { sprite_index = spr12; image_index = 0; image_speed = 1; }
        exit;
    }

    var dead_flag = false;
    if (variable_instance_exists(target, "hp"))      dead_flag |= (target.hp <= 0);
    if (variable_instance_exists(target, "is_dead")) dead_flag |= target.is_dead;
    if (variable_instance_exists(target, "state"))   dead_flag |= (target.state == "dead");
    if (dead_flag) _clear_target_marker();
}

// 🚪 DOOR INTERACT
if (action_type == "door" && state == "moving_to_door" && target != noone) {
    var dist = point_distance(x, y, interact_dest_x, interact_dest_y);

    if (dist < 1.5 && !teleport_started) {
        teleport_started = true;

        if (path_index != -1) path_end();
        if (path_move != -1) { path_delete(path_move); path_move = -1; }

        set_movement_mode("walk");

        anim_state = "idle";
        anim_dir = "up";

        var spr13 = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr13 != -1 && sprite_index != spr13) {
            sprite_index = spr13;
            image_index = 0;
            image_speed = 1;
        }

        if (instance_exists(target)) {
            with (target) {
                is_opening = true;
                sprite_index = spr_home_door_open;
            }
        }

        alarm[0] = 30;
    }
    else if (path_index == -1 && path_move != -1) {
        show_debug_message("🔁 Resuming path to door");
        path_start(path_move, move_speed, path_action_stop, false);
    }
    else if (path_index == -1) {
        show_debug_message("❌ No path exists to door");

        state = "idle";
        target = noone;
        action_type = "none";
        anim_state = "idle";
        anim_dir = "up";

        set_movement_mode("walk");

        var spr14 = get_anim_sprite(base_sprites, anim_state, anim_dir);
        if (spr14 != -1) {
            sprite_index = spr14;
            image_index = 0;
            image_speed = 1;
        }
    }
}

// AUTO COMBAT
auto_combat_update(id);

// ❌ Fallback: target destroyed
if (target != noone && !instance_exists(target)) {
    _clear_target_marker();

    target = noone;
    state = "idle";
    action_type = "none";

    if (path_index != -1) path_end();
    if (path_move != -1) { path_delete(path_move); path_move = -1; }

    set_movement_mode("walk");

    anim_state = "idle";
    anim_dir = "down";

    var spr15 = get_anim_sprite(base_sprites, anim_state, anim_dir);
    if (spr15 != -1 && sprite_index != spr15) {
        sprite_index = spr15;
        image_index = 0;
        image_speed = 1;
    }
}
