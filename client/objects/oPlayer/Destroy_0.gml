if (target != noone && instance_exists(target)) {
    target.selected = false;
}

if (path != -1) {
    path_delete(path);
}