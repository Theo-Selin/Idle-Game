/// set_target_action(player, _target, _action_type)
/// Decides intent (move / gather / combat / door), sets speed & anim mode (walk/run),
/// computes a reachable destination, places a marker, and starts pathing.
function set_target_action(player, _target, _action_type) {
    with (player) {
        var __cell = global.grid_cell_size;
        if (!is_real(__cell) || __cell <= 0) __cell = 32;

        // ---------------------------------------
        // 0) Ensure fields & helpers exist
        // ---------------------------------------
        if (is_undefined(walk_speed))     walk_speed = 2.25;
        if (is_undefined(run_speed))      run_speed  = 3.5;
        if (is_undefined(move_speed))     move_speed = walk_speed;
        if (is_undefined(move_anim_mode)) move_anim_mode = "walk";
        if (is_undefined(path_move))      path_move = -1;

        if (is_undefined(set_movement_mode)) {
            function set_movement_mode(_mode) {
                if (_mode == "run") { move_speed = run_speed;  move_anim_mode = "run"; }
                else                 { move_speed = walk_speed; move_anim_mode = "walk"; }
            }
        }

        if (!variable_instance_exists(id, "target_marker")) target_marker = noone;
        if (!variable_instance_exists(id, "lock_token"))    lock_token    = 0;

        // ------------------------------------------------------------
        // Helpers (marker & coords)
        // ------------------------------------------------------------
        function __place_marker_at(_mx, _my, _layer_id) {
            var m = (layer_exists("FX_Targets"))
                ? instance_create_layer(_mx, _my, layer_get_id("FX_Targets"), oTarget)
                : instance_create_depth(_mx, _my, -100000, oTarget);
            m.owner = id;
            target_marker = m;
        }

        function __calc_marker_pos(_target, _action_type, _dest_x, _dest_y) {
            if (_action_type == "move" || _target == noone) return { x: _dest_x, y: _dest_y };
            var base_x = (_target.bbox_left + _target.bbox_right) * 0.5;
            var base_y = _target.bbox_top;
            var off_x = variable_instance_exists(_target, "marker_x_offset") ? _target.marker_x_offset : 0;
            var off_y = variable_instance_exists(_target, "marker_y_offset") ? _target.marker_y_offset : 0;
            return { x: base_x + off_x, y: base_y + off_y };
        }

        function __tile_from_world(_wx, _wy) {
            var cs = global.grid_cell_size;
            return [ floor(_wx / cs), floor(_wy / cs) ];
        }
        function __world_center_from_tile(_tx, _ty) {
            var cs = global.grid_cell_size;
            return [ _tx * cs + cs * 0.5, _ty * cs + cs * 0.5 ];
        }
        function __cell_is_blocked(_tx, _ty) { return tile_is_blocked(_tx, _ty); }

        function __feet_world_y(_inst) {
            if (variable_instance_exists(_inst, "origin_is_feet") && _inst.origin_is_feet) return _inst.y;
            return _inst.bbox_bottom - 1;
        }

        // STRICT WORLD-SPACE SIDE RESOLUTION (no tile-centering)
        function __resolve_side_world(_target, _prefer_left, _offset_px) {
            var feet_y = __feet_world_y(_target);
            var left_x  = _target.bbox_left  - _offset_px;
            var right_x = _target.bbox_right + _offset_px;

            var cand = [];
            if (_prefer_left) {
                array_push(cand, [left_x, feet_y, true]);
                array_push(cand, [right_x, feet_y, false]);
            } else {
                array_push(cand, [right_x, feet_y, false]);
                array_push(cand, [left_x,  feet_y, true]);
            }

            for (var i = 0; i < array_length(cand); i++) {
                var wx = cand[i][0];
                var wy = cand[i][1];
                var from_left = cand[i][2];

                var t = __tile_from_world(wx, wy);
                if (__cell_is_blocked(t[0], t[1])) continue;

                var tmp = path_add();
                var ok = mp_grid_path(global.path_grid, tmp, x, y, wx, wy, true);
                if (path_exists(tmp)) path_delete(tmp);

                if (ok) return { x: wx, y: wy, from_left: from_left };
            }
            return undefined;
        }

        // ------------------------------------------------------------
        // NEW: Alternate-target selection helpers
        // ------------------------------------------------------------

        /// Returns true if candidate matches the "kind" we want for this action.
        function __matches_kind(_cand, _action_type, _orig_obj) {
            if (!instance_exists(_cand)) return false;
            if (!variable_instance_exists(_cand, "targetable") || !_cand.targetable) return false;

            if (_action_type == "gather") {
                // Option A: trait flag (preferred)
                if (variable_instance_exists(_cand, "is_gatherable") && _cand.is_gatherable) return true;
                // Option B: same object_index fallback (comment out if you only want trait)
                if (_cand.object_index == _orig_obj) return true;
                return false;
            }
            if (_action_type == "combat") {
                if (variable_instance_exists(_cand, "is_enemy") && _cand.is_enemy) return true;
                if (_cand.object_index == _orig_obj) return true; // fallback, optional
                return false;
            }
            return false; // no alternates for move/door by design
        }

        /// Scan for nearest reachable alternate target of same "kind".
        /// Returns { target: inst, dest_x, dest_y } or undefined
        function __find_alternate_target(_orig_target, _action_type, _prefer_left, _offset_px) {
            if (_action_type != "gather" && _action_type != "combat") return undefined;

            var __ALT_RADIUS = 640; // tune: keep modest for mobile perf (~20 tiles @ 32px)
            var best_inst = noone;
            var best_dx = 0;
            var best_dy = 0;
            var best_d2 = 999999999;

            // Choose a pool to scan: parent/trait preferred, but we don't assume parent usage.
            // We'll just iterate all instances and filter with __matches_kind.
            // If you have parent types (oGatherable, oEnemy), replace 'all' with that for speed.
            with (all) {
                // Early distance cull to keep the loop cheap on mobile
                var dx = other.x - x;
                var dy = other.y - y;
                var d2 = dx*dx + dy*dy;
                if (d2 > (__ALT_RADIUS * __ALT_RADIUS)) continue;

                if (!other.__matches_kind(id, other.action_type, _orig_target.object_index)) continue;
                if (id == _orig_target.id) continue; // skip original

                // quick reachability probe using the same strict side resolution
                var pos = other.__resolve_side_world(id, _prefer_left, _offset_px);
                if (is_undefined(pos)) {
                    // try opposite preference once more before skipping
                    pos = other.__resolve_side_world(id, !_prefer_left, _offset_px);
                }
                if (!is_undefined(pos)) {
                    // choose nearest to the player
                    if (d2 < best_d2) {
                        best_d2 = d2;
                        best_inst = id;
                        best_dx = pos.x;
                        best_dy = pos.y;
                    }
                }
            }

            if (instance_exists(best_inst)) {
                return { target: best_inst, dest_x: best_dx, dest_y: best_dy };
            }
            return undefined;
        }

        // ---- Enemy lock helpers (unchanged) ----
        function __hard_interrupt_enemy(_e, _owner, _token) {
            if (!instance_exists(_e)) return;
            with (_e) {
                if (!variable_instance_exists(id,"ai_enabled")) ai_enabled = true;
                if (!variable_instance_exists(id,"is_locked"))  is_locked  = false;
                if (!variable_instance_exists(id,"combat_lock_owner"))  combat_lock_owner = noone;
                if (!variable_instance_exists(id,"combat_lock_token"))  combat_lock_token = 0;

                ai_enabled         = false;
                is_locked          = true;
                combat_lock_owner  = _owner;
                combat_lock_token  = _token;

                if (path_index != -1) path_end();

                if (variable_instance_exists(id,"path_move")) {
                    if (is_real(path_move) && path_move != -1 && path_exists(path_move)) path_delete(path_move);
                    path_move = -1;
                }
                if (variable_instance_exists(id,"path")) {
                    if (is_real(path) && path != -1 && path_exists(path)) path_delete(path);
                    path = -1;
                }
                if (variable_instance_exists(id,"path_target") && instance_exists(path_target)) {
                    with (path_target) instance_destroy();
                    path_target = noone;
                }

                if (variable_instance_exists(id,"hsp")) hsp = 0;
                if (variable_instance_exists(id,"vsp")) vsp = 0;
                if (variable_instance_exists(id,"moving")) moving = false;

                if (variable_instance_exists(id,"state")) {
                    if (state != "dead") state = "idle";
                }
            }
        }
        function __unlock_enemy_if_owned(_e) {
            if (!instance_exists(_e)) return;
            with (_e) {
                if (!variable_instance_exists(id,"combat_lock_owner")) exit;
                if (combat_lock_owner == other.id) {
                    ai_enabled = true;
                    is_locked  = false;
                    combat_lock_owner = noone;
                }
            }
        }

        // ------------------------------------------------------------
        // 1) Clean previous movement/state (SAFE)
        // ------------------------------------------------------------
        if (path_index != -1) path_end();

        if (is_real(path_move) && path_move != -1) {
            if (path_exists(path_move)) path_delete(path_move);
            path_move = -1;
        }

        set_movement_mode("walk");

        switch (state) {
            case "gathering":
            case "moving_to_gather": gather_dest_x = 0; gather_dest_y = 0; break;
            case "moving_to_door":   interact_dest_x = x; interact_dest_y = y; teleport_started = false; break;
            case "combat":
            case "moving_to_combat": combat_dest_x = 0; combat_dest_y = 0; break;
        }

        if (target != noone && instance_exists(target)) {
            if (variable_instance_exists(target, "selected"))   target.selected   = false;
            if (variable_instance_exists(target, "targeted"))   target.targeted   = false;
            if (variable_instance_exists(target, "targetable")) target.targetable = true;
            __unlock_enemy_if_owned(target);
            if (target.object_index == oTarget && variable_instance_exists(target, "owner") && target.owner == id) {
                with (target) instance_destroy();
            }
        }
        if (instance_exists(target_marker)) { instance_destroy(target_marker); target_marker = noone; }

        // ------------------------------------------------------------
        // 2) Assign new target & action
        // ------------------------------------------------------------
        target = _target;
        action_type = _action_type;

        if (target != noone) {
            if (variable_instance_exists(target, "selected"))   target.selected   = true;
            if (variable_instance_exists(target, "targeted"))   target.targeted   = true;
            if (variable_instance_exists(target, "targetable")) target.targetable = false;
            show_debug_message("🎯 Target assigned: " + string(target));
        }

        switch (action_type) {
            case "gather": if (target != noone) set_activity_gather(target); else set_activity_idle(); break;
            case "combat": if (target != noone) set_activity_combat(target); else set_activity_idle(); break;
            default:       set_activity_idle(); break;
        }

        // ------------------------------------------------------------
        // 2.5) Lock enemy if entering combat
        // ------------------------------------------------------------
        var __this_lock_token = 0;
        if (action_type == "combat" && target != noone) {
            lock_token += 1;
            __this_lock_token = lock_token;
            __hard_interrupt_enemy(target, id, __this_lock_token);
        }

        switch (action_type) {
            case "gather":
            case "combat": set_movement_mode("run");  break;
            case "move":
            case "door":
            default:       set_movement_mode("walk"); break;
        }

        // ------------------------------------------------------------
        // 3) Compute destination (with alternate-target fallback)
        // ------------------------------------------------------------
        var dest_x = x, dest_y = y;
        var prefer_left = (target != noone) && (x < target.x);

        // Helper to reassign to a new target cleanly (selection flags + lock)
        function __adopt_new_target(_new_tgt) {
            // deselect current
            if (target != noone && instance_exists(target)) {
                if (variable_instance_exists(target, "selected"))   target.selected   = false;
                if (variable_instance_exists(target, "targeted"))   target.targeted   = false;
                if (variable_instance_exists(target, "targetable")) target.targetable = true;
                __unlock_enemy_if_owned(target);
            }
            target = _new_tgt;
            if (variable_instance_exists(target, "selected"))   target.selected   = true;
            if (variable_instance_exists(target, "targeted"))   target.targeted   = true;
            if (variable_instance_exists(target, "targetable")) target.targetable = false;

            if (action_type == "combat" && instance_exists(target)) {
                lock_token += 1;
                __this_lock_token = lock_token;
                __hard_interrupt_enemy(target, id, __this_lock_token);
            }
            show_debug_message("🔁 Switched to alternate target: " + string(target));
        }

        var need_alt = false;

        switch (action_type) {
            case "gather":
                if (target != noone) {
                    var gpos = __resolve_side_world(target, prefer_left, 32);
                    if (is_undefined(gpos)) {
                        // try alternate target
                        var alt = __find_alternate_target(target, "gather", prefer_left, 32);
                        if (!is_undefined(alt)) {
                            __adopt_new_target(alt.target);
                            dest_x = alt.dest_x; dest_y = alt.dest_y;
                        } else {
                            need_alt = true; // signal failure to path stage
                        }
                    } else {
                        dest_x = gpos.x; dest_y = gpos.y;
                    }
                    if (!need_alt) {
                        gather_dest_x = dest_x; gather_dest_y = dest_y;
                    }
                    gather_anim = variable_instance_exists(target, "gather_anim") ? target.gather_anim : "chop";
                }
                break;

            case "combat":
                if (target != noone) {
                    var cpos = __resolve_side_world(target, prefer_left, 32);
                    if (is_undefined(cpos)) {
                        var altc = __find_alternate_target(target, "combat", prefer_left, 32);
                        if (!is_undefined(altc)) {
                            __adopt_new_target(altc.target);
                            dest_x = altc.dest_x; dest_y = altc.dest_y;
                        } else {
                            need_alt = true;
                        }
                    } else {
                        dest_x = cpos.x; dest_y = cpos.y;
                    }
                    if (!need_alt) {
                        combat_dest_x = dest_x; combat_dest_y = dest_y;
                    }
                    combat_anim = variable_instance_exists(target, "combat_anim") ? target.combat_anim : "combat";
                }
                break;

            case "door":
                if (target != noone) {
                    var bb_left   = target.bbox_left;
                    var bb_right  = target.bbox_right;
                    var bb_bottom = target.bbox_bottom;
                    var dcx = (bb_left + bb_right) * 0.5;
                    var feet_ty   = floor((bb_bottom - 1) / __cell);
                    var ty_below  = feet_ty + 1;
                    var tx_left   = floor((dcx - 1) / __cell);
                    var tx_right  = tx_left + 1;

                    var left_ok   = !__cell_is_blocked(tx_left,  ty_below);
                    var right_ok  = !__cell_is_blocked(tx_right, ty_below);
                    var y_center_below = ty_below * __cell + __cell * 0.5;

                    var dest_x_candidate = dcx;
                    if (left_ok && right_ok) dest_x_candidate = dcx;
                    else if (left_ok)  dest_x_candidate = tx_left  * __cell + __cell * 0.5;
                    else if (right_ok) dest_x_candidate = tx_right * __cell + __cell * 0.5;

                    dest_x = dest_x_candidate;
                    dest_y = y_center_below;

                    interact_dest_x = dest_x;
                    interact_dest_y = dest_y;

                    __door_micro_offsets = [
                        [  0,  0 ],
                        [  __cell * 0.25,  0 ],
                        [ -__cell * 0.25,  0 ]
                    ];
                }
                break;

            case "move":
            default:
                if (target != noone) { dest_x = target.x; dest_y = target.y; }
                break;
        }

        if (!is_real(dest_x)) dest_x = x;
        if (!is_real(dest_y)) dest_y = y;

        // If both sides failed and no alternate target found, bail gracefully.
        if (need_alt) {
            if (instance_exists(target_marker)) { instance_destroy(target_marker); target_marker = noone; }
            show_debug_message("❌ No reachable side and no alternate target for " + action_type);
            state = "idle"; target = noone; action_type = "none";
            set_activity_idle();
            set_movement_mode("walk");
            exit;
        }

        var __mp = __calc_marker_pos(target, action_type, dest_x, dest_y);
        __place_marker_at(__mp.x, __mp.y, -1);

        // ------------------------------------------------------------
        // 4) Pathfinding with 8-neighbor fallback
        // ------------------------------------------------------------
        var final_x = dest_x, final_y = dest_y;
        var found = false;

        var p = path_add();
        if (mp_grid_path(global.path_grid, p, x, y, dest_x, dest_y, true)) found = true;
        if (path_exists(p)) path_delete(p);

        // Only allow neighbor nudge for move/door (not combat/gather)
        if (!found && (action_type == "move" || action_type == "door")) {
            var best_dist = 999999;
            for (var xx = -1; xx <= 1; xx++) {
                for (var yy = -1; yy <= 1; yy++) {
                    var txn = dest_x + xx * __cell;
                    var tyn = dest_y + yy * __cell;
                    var temp_path = path_add();
                    if (mp_grid_path(global.path_grid, temp_path, x, y, txn, tyn, true)) {
                        var dist = point_distance(x, y, txn, tyn);
                        if (dist < best_dist) { best_dist = dist; final_x = txn; final_y = tyn; found = true; }
                    }
                    if (path_exists(temp_path)) path_delete(temp_path);
                }
            }
        }

        // ------------------------------------------------------------
        // 5) Start movement or fail gracefully
        // ------------------------------------------------------------
        if (found) {
            path_move = path_add();
            if (mp_grid_path(global.path_grid, path_move, x, y, final_x, final_y, true)) {
                path_start(path_move, move_speed, path_action_stop, false);

                switch (action_type) {
                    case "gather": state = "moving_to_gather";  break;
                    case "door":   state = "moving_to_door";    break;
                    case "move":   state = "walking";           break;
                    case "combat": state = "moving_to_combat";  break;
                }

                show_debug_message("✅ Path to " + action_type + " target set (speed=" + string(move_speed) + ")");
            } else {
                if (path_exists(path_move)) path_delete(path_move);
                path_move = -1;

                state = "idle"; target = noone; action_type = "none";
                if (instance_exists(target_marker)) { instance_destroy(target_marker); target_marker = noone; }
                set_activity_idle();
                set_movement_mode("walk");

                show_debug_message("❌ Final fallback path failed.");
            }
        } else {
            if (instance_exists(target_marker)) { instance_destroy(target_marker); target_marker = noone; }
            show_debug_message("❌ No valid path found for " + action_type);

            state = "idle"; target = noone; action_type = "none";
            set_activity_idle();
            set_movement_mode("walk");
        }
    }
}
