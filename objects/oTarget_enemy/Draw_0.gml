// Optional: draw sprite if using one
draw_self();

// Check if the target was created on an interactable object
if (instance_exists(target_instance)) {
    // Interaction target (like a tree) — draw a green circle
    draw_set_color(c_lime);
    draw_set_alpha(1);
    draw_circle(x, y, 7, false); // Slightly larger circle
} else {
    // Ground target — draw a yellow circle
    draw_set_color(c_yellow);
    draw_set_alpha(1);
    draw_circle(x, y, 5, false);
}
