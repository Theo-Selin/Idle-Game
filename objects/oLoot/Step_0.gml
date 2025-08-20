// ⏱️ Log when pickup delay is reached
if (timer == pickup_delay) {
    show_debug_message("⏱️ Pickup delay reached for " + loot_type);
}

// 🪃 Arc Drop Animation
if (is_dropping) {
    drop_timer++;

    var t = clamp(drop_timer / drop_duration, 0, 1);
    var t_h = 1 - power(1 - t, 2); // easeOutQuad

    var height = -36;
    var arc_y = height * (4 * t * (1 - t)); // parabolic arc

	x = lerp(drop_start_x, drop_target_x, t);
	y = lerp(drop_start_y, drop_target_y, t) + sin(t * pi) * -28;


    // 🪄 Scale: 0.5 → 1 → 0.5
    var arc_t = 4 * t * (1 - t);
    scale = lerp(1, 0.5, t); // From big to small during arc
    fade_alpha = lerp(fade_alpha, 1, 0.1);

if (drop_timer >= drop_duration) {
	is_dropping = false;
    fade_alpha = 1;
    scale = 0.5;
    x = drop_target_x;
    y = drop_target_y;
	
	hover_timer = pi / 2; // Start hovering from the bottom of the wave
	
	// 🔊 Play drop sound based on loot type
    var drop_sound;
    switch (loot_type) {
        case "coin_copper":
            drop_sound = snd_loot_coin;
            break;
        default:
            drop_sound = snd_loot_drop_regular;
            break;
    }
	var snd_inst = audio_play_sound(drop_sound, 1, false);
    audio_sound_pitch(snd_inst, random_range(0.92, 1.08));
}
    exit;
}

// 📦 Idle + Pickup Logic
timer++;

// 🟡 Check if player is in range and loot isn't already collected
if (!collected && timer >= pickup_delay && instance_exists(oPlayer)) {
    var dist = point_distance(x, y, oPlayer.x, oPlayer.y);

    if (dist < 1200) {
        collected = true;
        fly_to_player = true;
		shadow_visible = false;
        show_debug_message("🟢 Loot picked up: starting fly-to-player for " + loot_type);
    }
}

// ✨ Fly-to-Player Animation
if (fly_to_player) {
    // Always get live player position (adjust for origin offset)
    var target_x = oPlayer.x;
    var target_y = oPlayer.y - 18; // Adjust for player’s visual center

    x = lerp(x, target_x, fly_speed);
    y = lerp(y, target_y, fly_speed);

    fade_alpha = lerp(fade_alpha, 0, 0.15);

    show_debug_message("💨 Flying to player... alpha: " + string(fade_alpha));

	if (fade_alpha < 0.05) {
	    show_debug_message("✅ Loot collected: " + loot_type + " x" + string(loot_amount));

	    // 🔊 Play pickup sound based on loot type
	    var sound_to_play;
	    switch (loot_type) {
	        case "coin_copper":
	            sound_to_play = snd_loot_coin;
	            break;
	        default:
	            sound_to_play = snd_loot_bag;
	            break;
	    }

	    var snd_inst = audio_play_sound(sound_to_play, 1, false);
	    audio_sound_pitch(snd_inst, random_range(0.92, 1.08));

	    // 💾 Add to inventory/resource pool
	    collect_loot(loot_type, loot_amount);

	    // 📝 Create popup
		var popup = instance_create_layer(oPlayer.x, oPlayer.y - 32, "Instances", oPopupFloat);
		with (popup) {

		    switch (other.loot_type) {
		        case "oak_log":
		            text = "+1 Oak Log";
		            sprite = spr_oak_log;
		            color = c_white;
		            break;
					
				case "mushroom":
		            text = "+1 Mushroom";
		            sprite = spr_mushroom;
		            color = c_white;
		            break;
				
				case "coin_copper":
		            text = "+1 Copper Coin";
		            sprite = spr_coin_copper;
		            color = c_white;
		            break;
					
				case "cloth":
		            text = "+1 Cloth";
		            sprite = spr_cloth;
		            color = c_white;
		            break;
					
		        default:
		            text = "+1 " + string(other.loot_type); // fallback
		            sprite = noone;
		            color = c_white;
		            break;
		    }
		}

	    // 🗑️ Remove the loot instance
	    instance_destroy();
	}
}
