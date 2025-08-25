/// ui_toast_add(text_or_struct, ttl_frames [, kind_or_sprite] [, sprite_override])
function ui_toast_add(_text, _ttl, _kind_or_spr, _spr_override)
{
    // Helper to queue safely
    var __queue = function(_t, _tl, _kos, _ov) {
        if (!variable_global_exists("__toast_queue")) global.__toast_queue = [];
        array_push(global.__toast_queue, [_t, _tl, _kos, _ov]);
    };

    // Build message + metadata
    var msg = "";
    var ttl = is_undefined(_ttl) ? 120 : max(1, _ttl);
    var typ = undefined;
    var key = undefined;
    var spr = -1;

    var __apply_struct = function(opt) {
        if (!is_struct(opt)) return;
        if (variable_struct_exists(opt, "text")) msg = string(opt.text);
        if (variable_struct_exists(opt, "ttl"))  ttl = max(1, opt.ttl);
        if (variable_struct_exists(opt, "type")) typ = string(opt.type);
        if (variable_struct_exists(opt, "key"))  key = string(opt.key);
        if (variable_struct_exists(opt, "spr")) {
            var s_any = opt.spr;
            if (is_string(s_any)) s_any = sprite_get_index(s_any);
            if (is_real(s_any) && sprite_exists(s_any)) spr = s_any;
        }
    };

    if (is_struct(_text)) {
        __apply_struct(_text);
    } else {
        msg = is_string(_text) ? _text : string(_text);
        if (!is_undefined(_kind_or_spr)) {
            if (is_string(_kind_or_spr)) {
                var si = sprite_get_index(_kind_or_spr);
                if (si != -1 && sprite_exists(si)) spr = si; else typ = _kind_or_spr;
            } else if (is_real(_kind_or_spr)) {
                if (sprite_exists(_kind_or_spr)) spr = _kind_or_spr;
            } else if (is_struct(_kind_or_spr)) {
                __apply_struct(_kind_or_spr);
            }
        }
    }

    if (!is_undefined(_spr_override)) {
        var ov = _spr_override;
        if (is_string(ov)) ov = sprite_get_index(ov);
        if (is_real(ov) && sprite_exists(ov)) spr = ov;
    }

    if (msg == "") return;

    // If UI is missing OR not fully initialized, push to queue (flushed in Step)
    if (!instance_exists(oUIManager)) { __queue(_text, _ttl, _kind_or_spr, _spr_override); return; }

    var pushed = false;
    with (oUIManager) {
        if (variable_instance_exists(id, "toasts") && is_array(toasts)) {
            var t = { text: msg, age: 1, ttl: ttl };
            if (!is_undefined(typ)) t.type = typ;
            if (!is_undefined(key)) t.key  = key;
            if (spr != -1 && sprite_exists(spr)) t.spr = spr;
            array_push(toasts, t);

            var MAX_TOASTS = 8;
            while (array_length(toasts) > MAX_TOASTS) array_delete(toasts, 0, 1);
            pushed = true;
        }
    }

    // If the instance exists but its array wasn't ready yet this step, queue it
    if (!pushed) __queue(_text, _ttl, _kind_or_spr, _spr_override);
}
