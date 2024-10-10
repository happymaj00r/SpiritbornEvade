local my_utility = require("my_utility/my_utility")

local menu_elements = {
    the_hunter_submenu           = tree_node:new(1),
    the_hunter_boolean           = checkbox:new(true, get_hash(my_utility.plugin_label .. "the_hunter_boolean_base")),
    
    

    allow_elite_single_target   = checkbox:new(true, get_hash(my_utility.plugin_label .. "allow_elite_single_target_base")),
	Keep_up_buff   = checkbox:new(true, get_hash(my_utility.plugin_label .. "Keep_up_buff_base")),
   
}

local function menu()
    if menu_elements.the_hunter_submenu:push("The Hunter") then
        menu_elements.the_hunter_boolean:render("Enable The Hunter Cast", "")

        if menu_elements.the_hunter_boolean:get() then
            -- create the combo box elements as a table                       
          
            
        end

        menu_elements.the_hunter_submenu:pop()
    end
end

local the_hunter_spell_id = 1663206
local The_hunter_spell_data = spell_data:new(
    2.0,                        -- radius
    1,                        -- range
    0.6,                        -- cast_delay
    0.5,                        -- projectile_speed
    true,                      -- has_collision
    the_hunter_spell_id,           -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    --targeting_type
)


local last_the_hunter_cast_time = 0.0
local function logics(target)


	local local_player = get_local_player();
	if local_player:get_active_spell_id() == 1663206 and last_the_hunter_cast_time < get_time_since_inject() then 
		last_the_hunter_cast_time = get_time_since_inject() + 7
	end
    local menu_boolean = menu_elements.the_hunter_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                last_the_hunter_cast_time, 
                the_hunter_spell_id);

    if not is_logic_allowed then
        return false;
    end;
	

	--local Has_dmgbuff = false
	
	
	
	
	if last_the_hunter_cast_time > get_time_since_inject() then
		return false;
	end
    --Buffs are broken so we use a timer 
	--local buffs = local_player:get_buffs()
    --if buffs then
    --    for i, buff in ipairs(buffs) do
    --        local buff_hash = buff.name_hash
    --        if buff_hash == 1663206 then
    --            Has_dmgbuff = true
	--			console.print("Has buff Skipping");
    --            break
    --        end
    --    end
    --end
	--
    --if Has_dmgbuff then
	--console.print("Has buff Skipping");
    --    return false
    --end
--console.print("Has buff Skipping");
   
	local target_position = target:get_position();
	local player_position = get_player_position();
    if target_position then
		local distance = player_position:dist_to_ignore_z(target_position);
		
		if distance > 16.0 then
			
			return false;
		end
		
		if cast_spell.target(target, The_hunter_spell_data, false) then
			console.print("Casted The Hunter");
			return true;
		end
	end
    
    
    
    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}