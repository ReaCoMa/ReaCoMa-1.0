slicing = {}

slicing.container = {
    full_path = {},
    item_pos = {},
    item_pos_samples = {},
    take_ofs = {},
    take_ofs_samples = {},
    item_len_samples = {},
    cmd = {},
    slice_points_string = {},
    tmp = {},
    item = {},
    reverse = {},
    sr = {},
    playrate = {}
}

slicing.rm_dup = function(slice_table)
    -- Removes duplicate entries from a table
    local hash = {}
    local res = {}
    for _,v in ipairs(slice_table) do
        if not hash[v] then
            res[#res+1] = v -- you could print here instead of saving to result table if you wanted
            hash[v] = true
        end
    end
    return res
end

slicing.get_data = function (item_index, data)
    local item = reaper.GetSelectedMediaItem(0, item_index-1)
    local take = reaper.GetActiveTake(item)
    local src = reaper.GetMediaItemTake_Source(take)
    local src_parent = reaper.GetMediaSourceParent(src)
    local sr = nil
    local full_path = nil
    
    if src_parent ~= nil then
        sr = reaper.GetMediaSourceSampleRate(src_parent)
        full_path = reaper.GetMediaSourceFileName(src_parent, "")
        table.insert(data.reverse, true)
    else
        sr = reaper.GetMediaSourceSampleRate(src)
        full_path = reaper.GetMediaSourceFileName(src, "")
        table.insert(data.reverse, false)
    end

    reacoma.utils.check_extension(full_path)
    
    local tmp = full_path .. utils.uuid(item_index) .. "fs.csv"
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local src_len = reaper.GetMediaSourceLength(src)
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") * playrate

    if data.reverse[item_index] then
        take_ofs = math.abs(src_len - (item_len + take_ofs))
    end
    
    -- This line caps the analysis at one loop
    if (item_len + take_ofs) > (src_len * (1 / playrate)) then 
        item_len = (src_len * (1 / playrate))
    end

    local take_ofs_samples = utils.stosamps(take_ofs, sr)
    local item_pos_samples = utils.stosamps(item_pos, sr)
    local item_len_samples = math.floor(utils.stosamps(item_len, sr))

    table.insert(data.item, item)
    table.insert(data.sr, sr)
    table.insert(data.full_path, full_path)
    table.insert(data.take_ofs, take_ofs)
    table.insert(data.take_ofs_samples, take_ofs_samples)
    table.insert(data.item_pos, item_pos)
    table.insert(data.item_pos_samples, item_pos_samples)
    table.insert(data.item_len_samples, item_len_samples)
    table.insert(data.tmp, tmp)
    table.insert(data.playrate, playrate)
end

slicing.process = function (item_index, data, markers)
    -- Thank you to Francesco Cameli for helping me debug this absolute NIGHTMARE --
    local slice_points = utils.commasplit(data.slice_points_string[item_index])
    slice_points = slicing.rm_dup(slice_points)

    -- Invert the table around the middle point (mirror!)
    if data.reverse[item_index] then
        local half_length = (data.item_len_samples[item_index]) * 0.5
        for i=1, #slice_points do
            slice_points[i] = half_length + (half_length - slice_points[i])
        end
        utils.reversetable(slice_points)
    end
    
    -- if the left boundary is the start remove it
    if tonumber(slice_points[1]) == data.take_ofs_samples[item_index] then table.remove(slice_points, 1) end

    -- now sanitise the numbers to adjust for the take offset and playback rate
    for i=1, #slice_points do
        if data.reverse[item_index] then
            slice_points[i] = (slice_points[i] + data.take_ofs_samples[item_index]) * (1 / data.playrate[item_index])
        else
            slice_points[i] = (slice_points[i] - data.take_ofs_samples[item_index]) * (1 / data.playrate[item_index])
        end
    end

    for j=1, #slice_points do
        slice_pos = utils.sampstos(
            tonumber(slice_points[j]), 
            data.sr[item_index]
        )

        if slice == 1 then
            slice_pos = data.item_pos[item_index] + slice_pos
            data.item[item_index] = reaper.SplitMediaItem(
                data.item[item_index], 
                slice_pos
            )
        end

        local color = reaper.ColorToNative(30, 128, 100)
        if markers == 1 then
            -- reaper.AddProjectMarker2(ReaProject proj, boolean isrgn, number pos, number rgnend, string name, integer wantidx, integer color)
            reaper.AddProjectMarker2(0, false, slice_pos, 0, '', -1, color)

        end
    end
end

slicing.process_gate = function(item_index, data, init_state)
    local state = init_state
    local slice_points = utils.commasplit(data.slice_points_string[item_index])
    slice_points = slicing.rm_dup(slice_points)

    if slice_points[1] == "-1" or slice_points[2] == "-1" then 
        return 
    end

    -- Invert the table around the middle point (mirror!)
    if data.reverse[item_index] then
        local half_length = (data.item_len_samples[item_index]) * 0.5
        for i=1, #slice_points do
            slice_points[i] = half_length + (half_length - slice_points[i])
        end
        utils.reversetable(slice_points)
    end

    -- if the left boundary is the start remove it
    if tonumber(slice_points[1]) == data.take_ofs_samples[item_index] then table.remove(slice_points, 1) end

    -- now sanitise the numbers to adjust for the take offset and playback rate
    for i=1, #slice_points do
        if data.reverse[item_index] then
            slice_points[i] = (slice_points[i] + data.take_ofs_samples[item_index]) * (1 / data.playrate[item_index])
        else
            slice_points[i] = (slice_points[i] - data.take_ofs_samples[item_index]) * (1 / data.playrate[item_index])
        end
    end

    for j=1, #slice_points do
        slice_pos = utils.sampstos(
            tonumber(slice_points[j]), 
            data.sr[item_index]
        )
        
        slice_pos = data.item_pos[item_index] + slice_pos  -- account for playback rate
        reaper.SetMediaItemInfo_Value(data.item[item_index], "B_MUTE", state)
        data.item[item_index] = reaper.SplitMediaItem(
            data.item[item_index], 
            slice_pos
        )
        if state == 1 then state = 0 else state = 1 end
    end
    reaper.SetMediaItemInfo_Value(data.item[item_index], "B_MUTE", state)
end

return slicing
