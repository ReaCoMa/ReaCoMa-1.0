-- env_points_count = reaper.CountEnvelopePoints(env)

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

src_envcount = reaper.CountTakeEnvelopes(take)

for i=1, src_envcount do
    src_env = reaper.GetTakeEnvelope(take, i-1)
    num_points = reaper.CountEnvelopePoints(src_env)
    for j=1, num_points do
        reaper.GetEnvelopePoint(src_env, j)
    end
end
-- reaper.InsertMedia("C:/Users/james/Documents/Max 8/Packages/FluidCorpusManipulation/media/Green-Box641.wav", 3)
-- sel_take = reaper.GetActiveTake(item)
-- reaper.TakeFX_CopyToTake(take, 0, sel_take, 0, false)