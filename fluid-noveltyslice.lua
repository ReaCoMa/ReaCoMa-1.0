local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.doublequote(
    reacoma.settings.path .. "/fluid-noveltyslice"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.archetype.noveltyslice
    reacoma.params.check_params(processor)
    local param_names = "feature,threshold,kernelsize,filtersize,fftsettings,minslicelength,markers,slicemode,label,colour"
    local param_values = reacoma.params.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Noveltyslice Parameters", 10, param_names, param_values)
    if confirm then
        reacoma.params.store_params(processor, param_names, user_inputs)

        local params = reacoma.utils.commasplit(user_inputs)
        local feature = params[1]
        local threshold = params[2]
        local kernelsize = params[3]
        local filtersize = params[4]
        local fftsettings = params[5]
        local minslicelength = params[6]
        local markers = tonumber(params[7])
        local slicemode = tonumber(params[8])
        local label = params[9]
        local colour = params[10]
        local data = reacoma.slicing.container

        for i=1, num_selected_items do
            reacoma.slicing.get_data(i, data)
            
            local cmd = exe .. 
            " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
            " -indices " .. reacoma.utils.doublequote(data.tmp[i]) .. 
            " -maxfftsize " .. reacoma.utils.getmaxfftsize(fftsettings) ..
            " -maxkernelsize " .. kernelsize ..
            " -maxfiltersize " .. filtersize ..
            " -feature " .. feature .. 
            " -kernelsize " .. kernelsize .. 
            " -threshold " .. threshold .. 
            " -filtersize " .. filtersize .. 
            " -fftsettings " .. fftsettings .. 
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

        reacoma.utils.arrange("reacoma-noveltyslice")
        reacoma.utils.cleanup(data.tmp)
    end
end

