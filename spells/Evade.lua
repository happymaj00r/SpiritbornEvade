local my_utility = require("my_utility/my_utility")


local menu_elements_Evade_base =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "Evade_main_bool_base")),
}
local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end
local function menu()
    
    if menu_elements_Evade_base.tree_tab:push("Evade")then
        menu_elements_Evade_base.main_boolean:render("Enable Spell", "")
 
        menu_elements_Evade_base.tree_tab:pop()
    end
end

local spell_id_Evade = 337031;

local spell_data_Evade = spell_data:new(
    0.2,                        -- radius
    1,                        -- range
    0.2,                        -- cast_delay
    1,                        -- projectile_speed
    true,                           -- has_collision
    spell_id_Evade,           -- spell_id
    spell_geometry.rectangular,          -- geometry_type
    targeting_type.targeted    --targeting_type
)
local next_time_allowed_cast = 0;
local function logics()
    --console.print(main.tablelength(main.SpellQ));
    local menu_boolean = menu_elements_Evade_base.main_boolean:get();
    local current_orb_mode = orbwalker.get_orb_mode()

    if current_orb_mode == orb_mode.none then
        return false
    end
	local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_Evade);

    if not is_logic_allowed then
        return false;
    end;
	
	
    local current_time = get_time_since_inject()
    if current_time < next_time_allowed_cast then
        return;
    end;
    

    
    local cursor_position = get_cursor_position();
    if cast_spell.position(spell_id_Evade, cursor_position, 0.10) then

        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.15;

        --console.print("Casted Evade");
        return true;
    end;
            
    return false;
end


return
{
    menu = menu,
    logics = logics,   
}