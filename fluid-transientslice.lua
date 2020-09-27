local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.doublequote(
    reacoma.settings.path .. "/fluid-transientslice"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.archetype.transientslice
    reacoma.params.check_params(processor)
    local param_names = "order,blocksize,padsize,skew,threshfwd,threshback,windowsize,clumplength,minslicelength,markers,slicemode,label,colour"
    local param_values = reacoma.params.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Transient Slice Parameters", 13, param_names, param_values)
    if confirm then
        reacoma.params.store_params(processor, param_names, user_inputs)
        
        local params = reacoma.utils.commasplit(user_inputs)
        local order = params[1]
        local blocksize = params[2]
        local padsize = params[3]
        local skew = params[4]
        local threshfwd = params[5]
        local threshback = params[6]
        local windowsize = params[7]
        local clumplength = params[8]
        local minslicelength = params[9]
        local markers = tonumber(params[10])
        local slicemode = tonumber(params[11])
        local label = params[12]
        local colour = params[13]

        local data = reacoma.slicing.container

        for i=1, num_selected_items do
            reacoma.slicing.get_data(i, data)

            local cmd = exe .. 
            " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
            " -indices " .. reacoma.utils.doublequote(data.tmp[i]) .. 
            " -order " .. order .. 
            " -blocksize " .. blocksize .. 
            " -padsize " .. padsize .. 
            " -skew " .. skew .. 
            " -threshfwd " .. threshfwd .. 
            " -threshback " .. threshback ..
            " -windowsize " .. windowsize .. 
            " -clumplength " .. clumplength .. 
            " -minslicelength " .. minslicelength ..
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]
            table.insert(data.cmd, cmd)
        end
        
        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.cmd[i])
            table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
            reacoma.slicing.process(i, data, markers, slicemode, label, colour)
        end

        reacoma.utils.arrange("reacoma-transientslice")
        reacoma.utils.cleanup(data.tmp)
    end
end

