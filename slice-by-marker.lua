local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

-- This is where our selected items will be stored:
local d = reacoma.slicing.container

-- Count how many items we've selected:
local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    -- Getting params:
    local param_names = "keyword"
    local param_values = ""

    local confirm, user_inputs = reaper.GetUserInputs("Slice Parameters", 1, param_names, param_values)
    if confirm then
        
        -- Start doing shit:
        local params = reacoma.utils.commasplit(user_inputs)
        local keyword = params[1]

        -- Here we're filling data with the selected items:
        for i = 1, num_selected_items do 
            reacoma.slicing.get_data(i, d)
        end

        local num_markers = reaper.CountProjectMarkers(0)

        for i = 1, num_selected_items do
            if keyword == nil then
                -- If no keywords given, just chop at every single marker:
                for j = 1, num_markers - 1 do
                    retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, j)
                    -- boundary checking     
                    local item_end = d.item_pos[i] + d.item_len[i]                   
                    if pos > d.item_pos[i] and pos < item_end then
                        d.item[i] = reaper.SplitMediaItem(
                            d.item[i], 
                            pos
                        )
                    end
                end
            else
                -- Will only chop if the keyword is in the marker name:
                for j = 1, num_markers - 1 do
                    retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, j)
                    -- boundary checking     
                    if string.match(name, keyword) then
                        local item_end = d.item_pos[i] + d.item_len[i]                   
                        if pos > d.item_pos[i] and pos < item_end then
                            d.item[i] = reaper.SplitMediaItem(
                                d.item[i], 
                                pos
                            )
                        end
                    end
                end
            end
        end
    end
end