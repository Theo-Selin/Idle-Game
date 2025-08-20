/// @function progress_save()
/// @desc Writes global.progress to save.json (safe for mobile/desktop).
function progress_save() {
    if (!is_struct(global.progress)) return;
    var json = json_stringify(global.progress);
    var fh = file_text_open_write("save.json");
    file_text_write_string(fh, json);
    file_text_close(fh);
}
