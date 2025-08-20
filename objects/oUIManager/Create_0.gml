/// oUIManager.Create
toggle_button_rect = [0, 0, 0, 0]; // Store toggle hitbox
auto_btn_rect = [0,0,0,0];   // store hitbox for Auto Combat
ui_tabs = ["character", "inventory", "crafting"]; // <— Character first
active_tab = "inventory";
ui_visible = false;

tab_x = 16;
tab_y = 64;
tab_spacing = 48;

// TOOLTIP
global.tooltip_text = "";
global.tooltip_x = 0;
global.tooltip_y = 0;
global.tooltip_item_id = undefined; // <-- add this

// INVENTORY
item_slot_size = 48;
item_slot_margin = 4.6;
item_slots_total = 48; // placeholder for now
global.current_inventory_category = "Gatherables";

// Context menu + drag state single-source-of-truth
if (!variable_struct_exists(global, "context_menu")) {
    global.context_menu = { is_open:false, x:0, y:0, options:[], source:{category:"", index:-1, item_id:""} };
}
if (!variable_struct_exists(global, "inv_drag")) {
    global.inv_drag = { active:false, category:"", from_index:-1, item_id:"", offset_x:0, offset_y:0 };
}

// CRAFTING
global.selected_recipe_index = -1;
global.crafting_progress = 0;
global.crafting_in_progress = false;
global.crafting_recipe = undefined;
global.current_craft_category = "Weapons";

// AFK GAINS
offline_visible    = (variable_global_exists("offline_report_ready") ? global.offline_report_ready : false);
offline_alpha_bg   = 0;    // 0..0.65
offline_alpha_card = 0;    // 0..1
offline_closing    = false;

// LEVEL
toasts = []; // queue of {text, age, ttl}
