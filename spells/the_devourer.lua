local my_utility = require("my_utility/my_utility")

local menu_elements = {
    the_devourer_submenu           = tree_node:new(1),
    the_devourer_boolean           = checkbox:new(true, get_hash(my_utility.plugin_label .. "the_devourer_boolean_base")),
    the_devourer_mode              = combo_box:new(0, get_hash(my_utility.plugin_label .. "the_devourer_cast_modes_base")),
    min_hits_slider             = slider_int:new(0, 30, 5, get_hash(my_utility.plugin_label .. "the_devourer_min_hits_slider_base")),

    allow_elite_single_target   = checkbox:new(true, get_hash(my_utility.plugin_label .. "allow_elite_single_target_base")),
    effect_size_affix_mult      = slider_float:new(0.0, 200.0, 0.0, get_hash(my_utility.plugin_label .. "the_devourer_effect_size_affix_mult_slider_base")),
}

local function menu()
    if menu_elements.the_devourer_submenu:push("The Devourer") then
        menu_elements.the_devourer_boolean:render("Enable The Devourer Cast", "")

        if menu_elements.the_devourer_boolean:get() then
            -- create the combo box elements as a table
            local dropbox_options = {"Combo & Clear", "Combo Only", "Clear Only"}
            menu_elements.the_devourer_mode:render("Cast Modes", dropbox_options, "")
            menu_elements.min_hits_slider:render("Min Hits", "")
            menu_elements.allow_elite_single_target:render("Always Cast On Single Elite", "")
            menu_elements.effect_size_affix_mult:render("Effect Size Affix Mult", "", 1)
        end

        menu_elements.the_devourer_submenu:pop()
    end
end

local the_devourer_spell_id = 1663210

local last_the_devourer_cast_time = 0.0
local function logics()

    local menu_boolean = menu_elements.the_devourer_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                last_the_devourer_cast_time, 
                the_devourer_spell_id);

    if not is_logic_allowed then
        return false;
    end;

    local mult = menu_elements.effect_size_affix_mult:get() * 0.01

    local spell_effect_radius_raw = 3.90 -- radius of the_devourer
    local circle_radius = spell_effect_radius_raw * (1.0 + mult)

    local player_position = get_player_position();
    local area_data = target_selector.get_most_hits_target_circular_area_heavy(player_position, 9.0, circle_radius)
    local best_target = area_data.main_target;
    
    if not best_target then
        return;
    end

    local best_target_position = best_target:get_position();
    local best_cast_data = my_utility.get_best_point(best_target_position, circle_radius, area_data.victim_list);

    local best_hit_list = best_cast_data.victim_list

    local is_single_target_allowed = false;
    if menu_elements.allow_elite_single_target:get() then
        for _, unit in ipairs(best_hit_list) do
            local current_health_percentage = unit:get_current_health() / unit:get_max_health() * 100

            -- Check if the unit is a boss with more than 22% health
            if unit:is_boss() and current_health_percentage > 22 then
                is_single_target_allowed = true
                break -- Exit the loop as the condition has been met
            end
        
            -- Check if the unit is an elite with more than 45% health
            if unit:is_elite() and current_health_percentage > 45 then
                is_single_target_allowed = true
                break -- Exit the loop as the condition has been met
            end
        end
    end

    local best_cast_hits = best_cast_data.hits;
    if best_cast_hits < menu_elements.min_hits_slider:get() and not is_single_target_allowed then
        -- add your logs here if needed
        return false
    end

    local best_cast_position = best_cast_data.point;
    if cast_spell.position(the_devourer_spell_id, best_cast_position, 0.40) then
        
        local current_time = get_time_since_inject();
        last_the_devourer_cast_time = current_time + 1.2;
        console.print("Casted The Devourer, Target " .. best_target:get_skin_name() .. " Hits: " .. best_cast_hits);
        
        return true;
    end
    
    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}