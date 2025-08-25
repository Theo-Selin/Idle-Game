/// @func combat_resolve_attack(attacker, defender, base_damage)
/// @param {Id.Instance} attacker
/// @param {Id.Instance} defender
/// @param {real}        base_damage
/// @return {struct} result  // fields: hit {bool}, crit {bool}, dmg {real}
function combat_resolve_attack(attacker, defender, base_damage) {
    // --- Read attacker chances (fallbacks if not set) ---
    var hc = variable_instance_exists(attacker, "hit_chance")  ? attacker.hit_chance  : 0.90; // 90% default
    var cc = variable_instance_exists(attacker, "crit_chance") ? attacker.crit_chance : 0.10; // 10% default
    var cm = variable_instance_exists(attacker, "crit_damage") ? attacker.crit_damage : 1.50; // 150% default

    hc = clamp(hc, 0.01, 0.99);
    cc = clamp(cc, 0.00, 0.95);
    cm = max(1.0, cm);

    // --- Roll hit ---
    var did_hit = (random(1) < hc);
    if (!did_hit) {
        return { hit:false, crit:false, dmg:0 };
    }

    // --- Base damage ---
    var dmg = base_damage;

    // --- Roll crit ---
    var did_crit = (random(1) < cc);
    if (did_crit) dmg = ceil(dmg * cm);

    // --- Apply defense once ---
    var def = (instance_exists(defender) && variable_instance_exists(defender, "defense")) ? max(0, defender.defense) : 0;
    dmg = max(1, dmg - def);

    return { hit:true, crit:did_crit, dmg:dmg };
}
