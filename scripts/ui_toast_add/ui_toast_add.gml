/// @function ui_toast_add(text, ttl_frames)
function ui_toast_add(_text, _ttl) {
    if (!instance_exists(oUIManager)) return;
    var ttl = is_undefined(_ttl) ? 120 : max(1, _ttl);
    with (oUIManager) {
        if (!variable_instance_exists(id, "toasts")) toasts = [];
        var t = { text: string(_text), age: 0, ttl: ttl };
        array_push(toasts, t);
    }
}
