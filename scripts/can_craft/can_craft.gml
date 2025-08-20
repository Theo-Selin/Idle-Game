/// can_craft(recipe) → bool
function can_craft(recipe) {
    for (var i = 0; i < array_length(recipe.input); i++) {
        var req = recipe.input[i];
        var req_id = string(req.id);
        if (inventory_count(req_id) < req.amount) return false;
    }
    return true;
}
