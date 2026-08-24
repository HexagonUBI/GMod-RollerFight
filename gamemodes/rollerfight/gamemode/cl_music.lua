RF.Music = RF.Music or {}

local Music = RF.Music

Music.Bed = nil
Music.Sting = nil
Music.Mood = nil
Music.Track = nil
Music.Generation = 0
Music.DuckUntil = 0
Music.NextSting = 0
Music.Unavailable = false

function Music.Volume()
	local master = GetConVar("snd_musicvolume")

	return math.Clamp(RF.Get("MusicVolume"), 0, 1) * (master and math.Clamp(master:GetFloat(), 0, 1) or 1)
end

function Music.Enabled()
	return Music.Volume() > 0.001
end

function Music.BedVolume()
	local duck = CurTime() < Music.DuckUntil and RF.MusicDuck or 1

	return Music.Volume() * RF.MusicBedVolume * duck
end

function Music.StopBed()
	Music.Generation = Music.Generation + 1

	if IsValid(Music.Bed) then Music.Bed:Stop() end

	Music.Bed = nil
	Music.Mood = nil
	Music.Track = nil
end

function Music.StopAll()
	Music.StopBed()

	if IsValid(Music.Sting) then Music.Sting:Stop() end

	Music.Sting = nil
end

local Available = {}

function Music.Has(track)
	if Available[track] == nil then
		Available[track] = file.Exists("sound/" .. track, "GAME")

		if not Available[track] then
			MsgN("[RollerFight] music not mounted, skipping " .. track)
		end
	end

	return Available[track]
end

function Music.Pick(mood)
	local list = RF.MusicBeds[mood]
	if not list then return end

	local usable = {}

	for _, track in ipairs(list) do
		if Music.Has(track) and track ~= Music.Track then table.insert(usable, track) end
	end

	if #usable == 0 then
		for _, track in ipairs(list) do
			if Music.Has(track) then table.insert(usable, track) end
		end
	end

	if #usable == 0 then return end

	return usable[math.random(#usable)]
end

function Music.PlayBed(mood, force)
	if Music.Unavailable then return end
	if Music.Mood == mood and not force then return end

	local track = Music.Pick(mood)
	if not track then return end

	Music.StopBed()

	Music.Mood = mood
	Music.Track = track

	local generation = Music.Generation

	sound.PlayFile("sound/" .. track, "noblock", function(channel)
		if not IsValid(channel) then
			Music.Unavailable = true
			Music.Mood = nil

			return
		end

		if generation ~= Music.Generation then
			channel:Stop()
			return
		end

		Music.Bed = channel
		channel:SetVolume(Music.BedVolume())
		channel:Play()
	end)
end

function Music.PlaySting(cue)
	local track = RF.MusicStings[cue]
	if not track or not Music.Has(track) then return end
	if not Music.Enabled() then return end
	if CurTime() < Music.NextSting then return end

	Music.NextSting = CurTime() + RF.MusicStingGap
	Music.DuckUntil = CurTime() + RF.MusicDuckTime

	if IsValid(Music.Sting) then Music.Sting:Stop() end

	Music.Sting = nil

	sound.PlayFile("sound/" .. track, "noblock", function(channel)
		if not IsValid(channel) then
			surface.PlaySound(track)
			return
		end

		if IsValid(Music.Sting) then Music.Sting:Stop() end

		Music.Sting = channel
		channel:SetVolume(Music.Volume())
		channel:Play()
	end)
end

function Music.MoodFor()
	local ply = LocalPlayer()
	if not IsValid(ply) then return "waiting" end

	local state = RF.GetState()

	if state == RF.STATE_WAITING and not RF.IsTraining(ply) then return "lobby" end
	if state == RF.STATE_POST then return "lobby" end

	local mine = ply:GetNWEntity("rf_mine")
	if not IsValid(mine) or mine:GetDying() then return "waiting" end

	if mine:Health() / math.max(1, mine:GetMaxHealth()) <= RF.Get("MusicDangerAt") then return "danger" end

	return "combat"
end

function Music.Update()
	if not Music.Enabled() then
		Music.StopAll()
		return
	end

	if IsValid(Music.Bed) then
		Music.Bed:SetVolume(Music.BedVolume())
	end

	local mood = Music.MoodFor()

	if Music.Mood ~= mood then
		Music.PlayBed(mood)
		return
	end

	if not IsValid(Music.Bed) then return end

	if Music.Bed:GetState() == GMOD_CHANNEL_STOPPED then
		Music.PlayBed(mood, true)
	end
end

timer.Create("RF.MusicDirector", 0.5, 0, Music.Update)

concommand.Add("rf_music_skip", function()
	Music.PlayBed(Music.MoodFor(), true)
end)

concommand.Add("rf_music_stop", Music.StopAll)

net.Receive("rf_music_cue", function()
	Music.PlaySting(net.ReadString())
end)

hook.Add("ShutDown", "RF.MusicStop", Music.StopAll)
