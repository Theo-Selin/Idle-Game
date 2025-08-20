/// @function progress_init()
/// @desc Initializes global.progress from save or defaults (with migration).
function progress_init() {
    var data = undefined;

    if (file_exists("save.json")) {
        var loaded = progress_load();
        if (is_struct(loaded)) {
            data = loaded;
        }
    }

    if (is_struct(data)) {
        global.progress = progress_migrate(data);
    } else {
        global.progress = progress_defaults();
    }
}
