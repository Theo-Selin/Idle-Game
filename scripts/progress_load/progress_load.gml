/// @function progress_load()
/// @desc Loads save.json and returns a struct (or undefined if invalid).
function progress_load() {
    if (!file_exists("save.json")) return undefined;
    var fh = file_text_open_read("save.json");
    var json = file_text_read_string(fh);
    file_text_close(fh);
    var data = json_parse(json);
    // Optional: migration hook by data.version
    return data;
}
