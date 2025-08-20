/// --- Portal half-ellipse glow (additive, rotatable, reversed gradient, soft edges, earlier fade) ---
// Origin at the flat base line. Per-instance adjustable: width, height, rotation, room.

// --- Safe reads for optional per-instance overrides (avoid ternary eager eval) ---
var draw_room; if (variable_instance_exists(id,"glow_room")) draw_room = variable_instance_get(id,"glow_room"); else draw_room = room;
if (draw_room != room) exit;

// Beam width (px) and height (vertical radius in px)
var beam_width;  if (variable_instance_exists(id,"glow_beam_width"))  beam_width  = variable_instance_get(id,"glow_beam_width");  else beam_width  = 64;
var beam_height; if (variable_instance_exists(id,"glow_beam_height")) beam_height = variable_instance_get(id,"glow_beam_height"); else beam_height = 64;

var rx = beam_width * 0.5;
var ry = beam_height;

var glow_color = make_color_rgb(255, 245, 140);
var edge_color = make_color_rgb(180, 220, 255);

// Rotation (degrees)
var rot_deg; if (variable_instance_exists(id,"glow_rotation")) rot_deg = variable_instance_get(id,"glow_rotation"); else rot_deg = 0;

// Edge feathering (px) for left/right borders
var edge_soft_px; if (variable_instance_exists(id,"glow_edge_soft_px")) edge_soft_px = variable_instance_get(id,"glow_edge_soft_px"); else edge_soft_px = 4;

// Extra: proportional feathering so it fades sooner horizontally on every row
var edge_soft_ratio; if (variable_instance_exists(id,"glow_edge_soft_ratio")) edge_soft_ratio = variable_instance_get(id,"glow_edge_soft_ratio"); else edge_soft_ratio = 0.35;

// Vertical controls
var fade_power;  if (variable_instance_exists(id,"glow_fade_power"))  fade_power  = variable_instance_get(id,"glow_fade_power");  else fade_power  = 3.0;
var arc_clear_px;if (variable_instance_exists(id,"glow_arc_clear_px"))arc_clear_px= variable_instance_get(id,"glow_arc_clear_px");else arc_clear_px = 2;

// NEW: bottom-edge softening (near base Y=0)
var base_soft_px;        if (variable_instance_exists(id,"glow_base_soft_px"))        base_soft_px        = max(0, variable_instance_get(id,"glow_base_soft_px")); else base_soft_px = 2;
var base_soft_strength;  if (variable_instance_exists(id,"glow_base_soft_strength"))  base_soft_strength  = clamp(variable_instance_get(id,"glow_base_soft_strength"), 0, 1); else base_soft_strength = 0.2;
var base_soft_curve;     if (variable_instance_exists(id,"glow_base_soft_curve"))     base_soft_curve     = max(1, variable_instance_get(id,"glow_base_soft_curve")); else base_soft_curve = 2.0;

var cx = x;
var cy = y + 16;

var shimmer   = 1 + 0.1 * sin(current_time / 220);
var alpha_cap = 0.6;

gpu_set_blendmode(bm_add);
var _m = matrix_build(cx, cy, 0, 0, 0, rot_deg, 1, 1, 1);
matrix_set(matrix_world, _m);
draw_set_alpha(1);

// LOCAL space: base at Y=0, arc toward negative Y
var denom = max(1, ry - arc_clear_px);
for (var i = 0; i < ry; i++) {
    if (i < arc_clear_px) continue;

    var yrow_local = -ry + i; // top (-ry) .. base (0)
    var dy = yrow_local;

    // Half-ellipse cross-section
    var t_ell = 1 - ((dy * dy) / (ry * ry));
    if (t_ell <= 0) continue;
    var halfw = rx * sqrt(t_ell);

    var left  = -halfw;
    var right =  halfw;

    // Reversed vertical gradient (thin at arc → full at base)
    var t = (i - arc_clear_px) / denom; // 0..1
    var a = power(t, fade_power) * (alpha_cap * shimmer);

    var c_arc  = merge_color(glow_color, edge_color, 0.2);
    var c_base = glow_color;

    // Horizontal feather (sides)
    var soft_target = max(edge_soft_px, halfw * edge_soft_ratio);
    var soft_max    = max(0, halfw - 0.5);
    var soft        = min(soft_target, soft_max);

    var il = left  + soft;
    var ir = right - soft;

    // ---- Bottom-band softening: apply to BOTH top & bottom verts in the band ----
    var rows_from_base = ry - i; // 1 at the last strip touching base
    var soft_t = 0;
    if (base_soft_px > 0) soft_t = 1 - clamp(rows_from_base / (base_soft_px + 0.0001), 0, 1);
    var fall = power(soft_t, base_soft_curve);

    // Scale alphas (bottom slightly stronger)
    var a_top    = a * (1 - base_soft_strength * (fall * 0.6));
    var a_bottom = a * (1 - base_soft_strength * fall);

    // 1px-high strip
    draw_primitive_begin(pr_trianglestrip);
        // Left edge (transparent)
        draw_vertex_color(left,  yrow_local,     c_arc,  0);
        draw_vertex_color(left,  yrow_local + 1, c_base, 0);

        // Inner-left
        draw_vertex_color(il,    yrow_local,     c_arc,  a_top);
        draw_vertex_color(il,    yrow_local + 1, c_base, a_bottom);

        // Inner-right
        draw_vertex_color(ir,    yrow_local,     c_arc,  a_top);
        draw_vertex_color(ir,    yrow_local + 1, c_base, a_bottom);

        // Right edge (transparent)
        draw_vertex_color(right, yrow_local,     c_arc,  0);
        draw_vertex_color(right, yrow_local + 1, c_base, 0);
    draw_primitive_end();
}

// Reset state
matrix_set(matrix_world, matrix_build_identity());
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
