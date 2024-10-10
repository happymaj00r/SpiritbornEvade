local local_player = get_local_player();
if local_player == nil then
    return
end

local character_id = local_player:get_character_class_id();
local is_spiritborn = character_id == 7;
if not is_spiritborn then
     return
end;

local menu = require("menu");



local spells =

{
    armored_hide = require("spells/armored_hide"),
    concussive_stomp = require("spells/concussive_stomp"),
    counterattack = require("spells/counterattack"),   
    ravager = require("spells/ravager"),
    the_devourer = require("spells/the_devourer"),  
    thunderspike = require("spells/thunderspike"),  
	evade = require("spells/Evade"),
}

local my_utility = require("my_utility/my_utility")
local normal_monster_threshold = slider_int:new(1, 10, 5, get_hash(my_utility.plugin_label .. "normal_monster_threshold"))


local function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end








on_render_menu(function ()

    if not menu.main_tree:push("Spiritborn: Evade Build") then
        return;
    end;

    menu.main_boolean:render("Enable Plugin", "");

    if menu.main_boolean:get() == false then
      -- plugin not enabled, stop rendering menu elements
      menu.main_tree:pop();
      return;
    end;
 
    normal_monster_threshold:render("Normal Monster Threshold", "Threshold for considering normal monsters in target selection")
    spells.armored_hide.menu()
    spells.concussive_stomp.menu()
    spells.counterattack.menu()
    spells.ravager.menu()
    spells.the_devourer.menu()
	spells.evade.menu()
    menu.main_tree:pop();

end)

local can_move = 0.0;
local cast_end_time = 0.0;

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList";
local mount_buff_name_hash = mount_buff_name;
local mount_buff_name_hash_c = 1923;

local my_utility = require("my_utility/my_utility");
local my_target_selector = require("my_utility/my_target_selector");

local max_hits = 0
local best_target = nil

-- Define scores for different enemy types
local normal_monster_value = 1
local elite_value = 2
local champion_value = 3
local boss_value = 20

-- Cache for heavy function results
local last_check_time = 0.0 -- Time of last check for most hits
local check_interval = 1.0 -- 1 second cooldown between checks

local function check_and_update_best_target(unit, player_position, max_range)
    local unit_position = unit:get_position()
    local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position)

    if distance_sqr < (max_range * max_range) then
        local area_data = target_selector.get_most_hits_target_circular_area_light(unit_position, 5, 4, false)
        
        if area_data then
            local total_score = 0
            local n_normals = area_data.n_hits
            local has_elite = unit:is_elite()
            local has_champion = unit:is_champion()
            local is_boss = unit:is_boss()

            -- Skip single normal monsters unless there are more than the threshold
            if n_normals < normal_monster_threshold:get() and not (has_elite or has_champion or is_boss) then
                return -- Don't target single normal monsters or groups below threshold
            end

            -- Calculate score for normal monsters
            total_score = n_normals * normal_monster_value

            -- Add extra points for elite, champion, or boss
            if is_boss then
                total_score = total_score + boss_value
            elseif has_champion then
                total_score = total_score + champion_value
            elseif has_elite then
                total_score = total_score + elite_value
            end

            -- Prioritize based on score
            if total_score > max_hits then
                max_hits = total_score
                best_target = unit
            end
        end
    end
end

-- Updated function to get the closest valid enemy target
local function closest_target(player_position, entity_list, max_range)
    if not entity_list then
        return nil
    end

    local closest = nil
    local closest_dist_sqr = max_range * max_range

    for _, unit in ipairs(entity_list) do
        if target_selector.is_valid_enemy(unit) and unit:is_enemy() then
            local unit_position = unit:get_position()
            local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position)
            if distance_sqr < closest_dist_sqr then
                closest = unit
                closest_dist_sqr = distance_sqr
            end
        end
    end

    return closest
end


-- on_update callback
on_update(function ()
	--console.print(tablelength(my_utility.SpellQ));
    local local_player = get_local_player();
    if not local_player or menu.main_boolean:get() == false then
        return;
    end;

    local current_time = get_time_since_inject()
    if current_time < cast_end_time then
        return;
    end;

    if not my_utility.is_action_allowed() then
        return;
    end  

    local player_position = get_player_position()

    local screen_range = 16.0;

    local collision_table = { false, 2.0 };
    local floor_table = { true, 5.0 };
    local angle_table = { false, 90.0 };

    local entity_list = my_target_selector.get_target_list(
        player_position,
        screen_range, 
        collision_table, 
        floor_table, 
        angle_table);

    local target_selector_data = my_target_selector.get_target_selector_data(
        player_position, 
        entity_list);

    
        
       
    
    if target_selector_data.is_valid then
        
		local is_auto_play_active = auto_play.is_active();
		local max_range = 17.0;
		if is_auto_play_active then
			max_range = 12.0;
		end
	
		-- Only update best_target if cooldown has expired
		if current_time >= last_check_time + check_interval then
			-- Use the already fetched entity_list here
			local target_selector_data = my_target_selector.get_target_selector_data(
				player_position, 
				entity_list);
	
			if target_selector_data and target_selector_data.is_valid then
				max_hits = 0
				best_target = nil
	
				-- Check normal units and apply the priority-based logic
				for _, unit in ipairs(target_selector_data.list) do
					check_and_update_best_target(unit, player_position, max_range)
				end
	
				-- Update last check time
				last_check_time = current_time
			end
		end	
		
		if best_target then
			local best_target_position = best_target:get_position();
			local distance_sqr = best_target_position:squared_dist_to_ignore_z(player_position);
		
			if distance_sqr > (max_range * max_range) then            
				return
			end
			
			-- Prioritize the_hunter
			if spells.the_hunter and spells.the_hunter.logics(best_target) then
				cast_end_time = current_time + 0.2;
				return
			end
			
			-- Attempt to use Rushing Claw frequently
			
			-- Simplified spell casting
			if spells.armored_hide and spells.armored_hide.logics() then
				cast_end_time = current_time +0.1;
				return
			end
			if spells.concussive_stomp and spells.concussive_stomp.logics(best_target) then
				cast_end_time = current_time + 0.2;
				return
			end
			if spells.counterattack and spells.counterattack.logics() then
				cast_end_time = current_time + 0.1;
				return
			end
			
			
			if spells.the_devourer and spells.the_devourer.logics() then
				cast_end_time = current_time + 0.2;
				return
			end
			
			if spells.ravager and spells.ravager.logics() then
				cast_end_time = current_time + 0.1;
				return
			end
		end
    end

    if spells.evade  and cast_end_time < current_time and spells.evade.logics() then
	end
	
	
	
  
   
	

    -- auto play engage far away monsters
    local move_timer = get_time_since_inject()
    if move_timer < can_move then
        return;
    end;

    

end)





local draw_player_circle = false;
local draw_enemy_circles = false;

on_render(function ()

    if menu.main_boolean:get() == false then
        return;
    end;

    local local_player = get_local_player();
    if not local_player then
        return;
    end

    local player_position = local_player:get_position();
    local player_screen_position = graphics.w2s(player_position);
    if player_screen_position:is_zero() then
        return;
    end

    if draw_player_circle then
        graphics.circle_3d(player_position, 8, color_white(85), 3.5, 144)
        graphics.circle_3d(player_position, 6, color_white(85), 2.5, 144)
    end    

   

end);



console.print("Lua Plugin - Spiritborn Base - Version 1.0");

