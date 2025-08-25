/// draw_character_stats_ui(x, y, w, h)
function draw_character_stats_ui(_x, _y, _w, _h)
{
    // ---------------- THEME / COLORS ----------------
    var theme = {
        // spacing + sizing
        pad: 12,            // general padding
        gap: 26,            // vertical gap between rows / bars
        line: 24,           // line height for text rows
        bar_h: 6,           // progress bar height
        col_gap: 24,        // (kept for parity with other UIs)
        section_spacing: 16,
        cat_tab_h: 38,

        // palette
        col_text       : make_color_rgb(220,220,220),
        col_dim        : make_color_rgb(160,160,180),
        col_bar_bg     : make_color_rgb(32,32,38),
        col_bar_fill_hp: make_color_rgb(200,40,40),
        col_bar_fill_xp: make_color_rgb(255,191,0),
        col_divider    : make_color_rgb(64,64,70),
        col_outline    : make_color_rgb(16,16,20)
    };

    // === SECTION SIZES (mirror draw_inventory_ui) ===
    var section_spacing = theme.section_spacing;
    var cat_tab_h = theme.cat_tab_h;

    var tab_area_y = _y;
    var tab_area_h = cat_tab_h + 4;

    var grid_area_y = tab_area_y + tab_area_h + section_spacing;
    var grid_area_h = floor(_h * 0.45);

    var bottom_area_y = grid_area_y + grid_area_h + section_spacing;
    var bottom_area_h = _h - (tab_area_h + grid_area_h + section_spacing * 3);

    // bottom split identical to inventory
    var equipped_w = floor((_w - section_spacing) / 1.415);
    var stats_w = _w - equipped_w - section_spacing;

    var group_total_w = equipped_w + stats_w + section_spacing;
    var group_x = _x + (_w - group_total_w) / 2;

    var left_x1 = group_x;
    var left_y1 = bottom_area_y;
    var left_x2 = left_x1 + equipped_w;
    var left_y2 = left_y1 + bottom_area_h;

    var right_x1 = left_x2 + section_spacing;
    var right_y1 = bottom_area_y;
    var right_x2 = right_x1 + stats_w;
    var right_y2 = right_y1 + bottom_area_h;

    // ---------------- PLAYER / PROGRESS ----------------
    var p = noone;
    if (variable_global_exists("player") && instance_exists(global.player)) p = global.player;
    else if (instance_number(oPlayer) > 0) p = instance_find(oPlayer, 0);
    if (p == noone) return;

    if (!variable_global_exists("progress") || !is_struct(global.progress)) {
        global.progress = {
            skills: {
                combat  : { level: 1, xp: 0 },
                woodcutting: { level: 1, xp: 0 }
            }
        };
    }

    var hp_cur = (variable_instance_exists(p, "hp") && is_real(p.hp)) ? p.hp : 0;
    var hp_max = (variable_instance_exists(p, "max_hp") && is_real(p.max_hp)) ? p.max_hp : 1;
    hp_max = max(1, hp_max);

    var s = progress_get_skill("combat");
    var lvl = is_struct(s) ? s.level : 1;
    var xp_cur = is_struct(s) ? s.xp : 0;
    var xp_need = max(1, progress_xp_to_next(lvl));
    var xp_frac = clamp(xp_cur / xp_need, 0, 1); // kept in case you use it elsewhere

    var dmg  = (variable_instance_exists(p, "combat_damage") && is_real(p.combat_damage)) ? p.combat_damage : 1;
    var def  = (variable_instance_exists(p, "defense") && is_real(p.defense)) ? p.defense : 0;
    var hit  = (variable_instance_exists(p, "hit_chance") && is_real(p.hit_chance)) ? p.hit_chance : 0.8;
    var crit = (variable_instance_exists(p, "crit_chance") && is_real(p.crit_chance)) ? p.crit_chance : 0.05;
    var cdmg = (variable_instance_exists(p, "crit_damage") && is_real(p.crit_damage)) ? p.crit_damage : 1.5;

    // ---------------- DRAW CONFIG ----------------
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
    draw_set_color(theme.col_text);

    // =====================================================
    // TOP STRIP (kept empty – tabs live here in inventory UI)
    // =====================================================

	// =====================================================
	// MIDDLE “GRID AREA”: Player sprite (1/3) + HP/XP (2/3, shorter bars)
	// =====================================================
	{
	    var pad_m  = theme.pad;
	    var usable = _w - pad_m * 2;
	    var bars_h = theme.bar_h * 2 + theme.gap;

	    var gx = _x + pad_m;
	    var gy = grid_area_y + max(0, (grid_area_h - bars_h) div 2);

	    // ---------- LEFT THIRD: player idle-down sprite ----------
	    var left_w = usable div 3;
	    var left_x = gx;
	    var left_y = gy;
	    var left_h = bars_h;

	    var spr = noone;
	    if (instance_exists(p)) {
	        if (variable_instance_exists(p, "spr_idle_down")) spr = p.spr_idle_down;
	        else spr = p.sprite_index;
	    }
	    if (spr != noone) {
	        var sw = sprite_get_width(spr), sh = sprite_get_height(spr);
	        if (sw > 0 && sh > 0) {
	            var scale = min((left_w * 0.85) / sw, (left_h * 1.05) / sh);
	            var cx = left_x + left_w * 0.5;
	            var cy = left_y + left_h * 0.5;
	            draw_sprite_ext(spr, 0, cx, cy, scale, scale, 0, c_white, 1);
	        }
	    }

	    // ---------- RIGHT TWO-THIRDS: HP + XP ----------
	    var right_w_total = usable - left_w;
	    var right_x_total = gx + left_w;
	    var right_y = gy;

	    // shorten bars to 75% of right panel width
	    var bar_w   = floor(right_w_total * 0.5);
	    var right_x = right_x_total + (right_w_total - bar_w) div 2; // center bars

	    // HP (theme red)
	    ui_draw_value_meter("HP", hp_cur, hp_max, right_x, right_y, bar_w, theme.bar_h, theme.col_bar_fill_hp);

	    // XP below (theme amber)
	    right_y += theme.bar_h + theme.gap;
	    ui_draw_value_meter("XP", xp_cur, xp_need, right_x, right_y, bar_w, theme.bar_h, theme.col_bar_fill_xp);
	}




	// =====================================================
	// BOTTOM LEFT: Skill meters (PROFESSIONS) with extra padding
	// =====================================================
	{
	    // increase section padding uniformly on all edges (tweak multiplier as desired)
	    var section_pad = theme.pad * 4;

	    var ls_x1 = left_x1 + section_pad;
	    var ls_x2 = left_x2 - section_pad;
	    var ls_y1 = left_y1 + section_pad;
	    var ls_y2 = left_y2 - section_pad; // (not drawn to, but enforces bottom padding)

	    // Start drawing at the padded top
	    var ls_y = ls_y1;

	    // --- WOODCUTTING ---
	    var s2 = progress_get_skill("woodcutting");
	    var s2_lvl  = is_struct(s2) ? s2.level : 1;
	    var s2_xp   = is_struct(s2) ? s2.xp : 0;
	    var s2_need = max(1, progress_xp_to_next(s2_lvl));
	    var s2_r    = clamp(s2_xp / s2_need, 0, 1);

	    var label_y = ls_y - (theme.line - theme.bar_h) * 0.5 - (theme.bar_h + 2);

	    draw_set_halign(fa_left);  draw_set_color(theme.col_dim);
	    draw_text(ls_x1, label_y, "WOODCUTTING");
	    draw_set_halign(fa_right); draw_set_color(theme.col_text);
	    draw_text(ls_x2, label_y, "Lv." + string(s2_lvl));
	    draw_set_halign(fa_left);

	    // keep the bar within the padded vertical bounds
	    var x1 = ls_x1;
	    var x2 = ls_x2;
	    var y1 = ls_y;
	    var y2 = min(ls_y + theme.bar_h, ls_y2);

	    draw_set_color(theme.col_outline); draw_roundrect(x1-1, y1-1, x2+1, y2+1, false);
	    draw_set_color(theme.col_bar_bg);  draw_roundrect(x1,   y1,   x2,   y2,   false);

	    var fx2 = x1 + floor((x2 - x1) * s2_r);
	    if (fx2 > x1) {
	        draw_set_color(theme.col_divider);
	        draw_roundrect(x1, y1, fx2, y2, false);
	    }

	    // if you draw more meters below, advance by bar height + gap
	    ls_y += theme.bar_h + theme.gap;
	}


    // =====================================================
    // BOTTOM RIGHT: Level + core stats
    // =====================================================
    {
        var rs_x1 = right_x1 + theme.pad;
        var rs_y  = right_y1 + theme.pad;
        var rs_x2 = right_x2 - theme.pad;

        // Level row
        draw_set_halign(fa_left);  draw_set_color(theme.col_dim);
        draw_text(rs_x1, rs_y, "Level");
        draw_set_halign(fa_right); draw_set_color(theme.col_text);
        draw_text(rs_x2, rs_y, string(lvl));
        draw_set_halign(fa_left);
        rs_y += theme.line;

        // --- Single-column stats ---
        var lx = rs_x1;
        var ly = rs_y + theme.gap;

        // width for value alignment (right edge of the panel)
        var col_w = (rs_x2 - rs_x1);

        // Damage
        draw_set_halign(fa_left);  draw_set_color(theme.col_dim);
        draw_text(lx, ly, "Damage");
        draw_set_halign(fa_right); draw_set_color(theme.col_text);
        draw_text(lx + col_w, ly, string(dmg));
        ly += theme.line;

        // Defense
        draw_set_halign(fa_left);  draw_set_color(theme.col_dim);
        draw_text(lx, ly, "Defense");
        draw_set_halign(fa_right); draw_set_color(theme.col_text);
        draw_text(lx + col_w, ly, string(def));
        ly += theme.line;

        // Hit
        draw_set_halign(fa_left);  draw_set_color(theme.col_dim);
        draw_text(lx, ly, "Hit");
        draw_set_halign(fa_right); draw_set_color(theme.col_text);
        draw_text(lx + col_w, ly, string(floor(hit * 100)) + "%");
        ly += theme.line;

        // Crit
        draw_set_halign(fa_left);  draw_set_color(theme.col_dim);
        draw_text(lx, ly, "Crit");
        draw_set_halign(fa_right); draw_set_color(theme.col_text);
        draw_text(lx + col_w, ly, string(floor(crit * 100)) + "%");
        ly += theme.line;

        // Crit Dmg
        draw_set_halign(fa_left);  draw_set_color(theme.col_dim);
        draw_text(lx, ly, "Crit Dmg");
        draw_set_halign(fa_right); draw_set_color(theme.col_text);
        draw_text(lx + col_w, ly, "x" + string(cdmg));

        // Reset halign
        draw_set_halign(fa_left);
    }
}
