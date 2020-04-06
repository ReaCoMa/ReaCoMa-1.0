-- get src_fx (number as an integer)
-- original take data.take[item_index]
-- new take (as they are selected)
-- src_fx + number of existing fx's

-- GET BORING SHIT --
local item = reaper.GetSelectedMediaItem(0, 0)
local take = reaper.GetActiveTake(item)
local src = reaper.GetMediaItemTake_Source(take)
local src_parent = reaper.GetMediaSourceParent(src)
local sr = nil
local full_path = nil

if src_parent ~= nil then
    sr = reaper.GetMediaSourceSampleRate(src_parent)
    full_path = reaper.GetMediaSourceFileName(src_parent, "")
else
    sr = reaper.GetMediaSourceSampleRate(src)
    full_path = reaper.GetMediaSourceFileName(src, "")
end
-- GET BORING SHIT --


srcfxcount = reaper.TakeFX_GetCount(take)
srcenvcount = reaper.CountTakeEnvelopes(take)
srcfxparams = reaper.TakeFX_GetNumParams(take)

TrackEnvelope reaper.TakeFX_GetEnvelope(MediaItem_Take take, integer fxindex, integer parameterindex, boolean create)

reaper.InsertMedia("C:/Users/james/Documents/Max 8/Packages/FluidCorpusManipulation/media/Green-Box641.wav", 3)
sel_take = reaper.GetActiveTake(item)
reaper.TakeFX_CopyToTake(take, 0, sel_take, 0, false)