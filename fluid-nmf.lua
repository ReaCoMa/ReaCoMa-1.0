local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.wrap_quotes(
    reacoma.settings.path .. "/fluid-nmf"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.archetype.nmf
    reacoma.params.check_params(processor)
    local param_names = "components,iterations,fftsettings"
    local param_values = reacoma.params.parse_params(param_names, processor)
    
    local confirm, user_inputs = reaper.GetUserInputs("NMF Parameters", 3, param_names, param_values)
    if confirm then
        reacoma.params.store_params(processor, param_names, user_inputs)

        local params = reacoma.utils.split_comma(user_inputs)
        local components = params[1]
        local iterations = params[2]
        local fftsettings = reacoma.utils.form_fft_string(params[3])

        local data = reacoma.layers.container

        data.outputs = {
            components = {}
        }

        for i=1, num_selected_items do

            reacoma.layers.get_data(i, data)

            table.insert(
                data.outputs.components,
                data.path[i] .. "_nmf_" .. reacoma.utils.uuid(i) .. ".wav"
            )

            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. reacoma.utils.wrap_quotes(data.full_path[i]) .. 
                " -resynth " .. reacoma.utils.wrap_quotes(data.outputs.components[i]) ..
                " -iterations " .. iterations ..
                " -components " .. components .. 
                " -fftsettings " .. fftsettings ..
                " -numframes " .. data.item_len_samples[i] .. 
                " -startframe " .. data.take_ofs_samples[i] ..
                " -resynthmode " .. 1
            )
        end

        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.cmd[i])
            reacoma.layers.exist(i, data)
        end
        
        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            reacoma.layers.process(i, data)
        end
        
        reacoma.utils.arrange("reacoma-nmf")
    end
end

