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

Music.Duck = 1

function Music.BedVolume()
	return Music.Volume() * RF.MusicBedVolume * Music.Duck
end

function Music.StepDuck()
	local target = CurTime() < Music.DuckUntil and RF.MusicDuck or 1
	local step = 0.05 / math.max(0.05, RF.MusicDuckRamp)

	if math.abs(Music.Duck - target) < 0.005 then
		Music.Duck = target
	else
		Music.Duck = Music.Duck + (target - Music.Duck > 0 and step or -step)
	end

	if IsValid(Music.Bed) then Music.Bed:SetVolume(Music.BedVolume()) end
end

function Music.StopBed()
	Music.Generation = Music.Generation + 1

	if IsValid(Music.Bed) then Music.Bed:Stop() end
	if IsValid(Music.Fading) then Music.Fading:Stop() end

	Music.Bed = nil
	Music.Fading = nil
	Music.Mood = nil
	Music.Track = nil
	Music.FadeStart = nil
	Music.CueState = nil
end

function Music.FadeOut(seconds)
	if not IsValid(Music.Bed) then return end

	if IsValid(Music.Fading) then Music.Fading:Stop() end

	Music.Generation = Music.Generation + 1
	Music.Fading = Music.Bed
	Music.FadeStart = CurTime()
	Music.FadeLength = seconds or RF.MusicFadeTime
	Music.FadeFrom = Music.Bed:GetVolume()

	Music.Bed = nil
	Music.Mood = nil
	Music.Track = nil
end

function Music.StepFade()
	if not IsValid(Music.Fading) then return end

	local frac = (CurTime() - (Music.FadeStart or 0)) / math.max(0.1, Music.FadeLength or 1)

	if frac >= 1 then
		Music.Fading:Stop()
		Music.Fading = nil

		return
	end

	Music.Fading:SetVolume((Music.FadeFrom or 1) * (1 - frac))
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

	if IsValid(Music.Sting) then Music.Sting:Stop() end

	Music.Sting = nil
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

function Music.PlayCue(cue)
	local track = RF.MusicCues[cue]
	if not track or not Music.Has(track) then return end
	if not Music.Enabled() then return end

	Music.StopBed()

	if IsValid(Music.Sting) then Music.Sting:Stop() end

	Music.Sting = nil
	Music.Mood = "cue"
	Music.Track = track
	Music.CueState = RF.GetState()

	local generation = Music.Generation

	sound.PlayFile("sound/" .. track, "noblock", function(channel)
		if not IsValid(channel) then
			Music.Unavailable = true
			Music.Mood = nil
			Music.CueState = nil

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

function Music.MoodFor()
	local ply = LocalPlayer()
	if not IsValid(ply) then return "waiting" end

	local state = RF.GetState()

	if state == RF.STATE_WAITING and not RF.IsTraining(ply) then return "lobby" end
	if state == RF.STATE_TEAMPICK then return "lobby" end
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

	local state = RF.GetState()

	if Music.CueState then
		if state ~= Music.CueState then
			Music.CueState = nil

			if IsValid(Music.Bed) then Music.FadeOut(RF.MusicFadeTime) end

			return
		end

		if IsValid(Music.Bed) and Music.Bed:GetState() ~= GMOD_CHANNEL_STOPPED then return end
		if Music.Mood == "cue" and not IsValid(Music.Bed) then return end

		Music.CueState = nil
		Music.Mood = nil
	end

	local mood = Music.MoodFor()

	if state == RF.STATE_POST or state == RF.STATE_INTERMISSION then
		if IsValid(Music.Bed) then Music.FadeOut(RF.MusicFadeTime) end

		return
	end

	local locked = state == RF.STATE_ACTIVE and IsValid(Music.Bed)

	if Music.Mood ~= mood and not locked then
		Music.PlayBed(mood)
		return
	end

	if not IsValid(Music.Bed) then return end

	if Music.Bed:GetState() == GMOD_CHANNEL_STOPPED then
		Music.PlayBed(mood, true)
	end
end

timer.Create("RF.MusicDirector", 0.5, 0, Music.Update)
timer.Create("RF.MusicFade", 0.05, 0, function()
	Music.StepFade()
	Music.StepDuck()
end)

concommand.Add("rf_music_skip", function()
	Music.PlayBed(Music.MoodFor(), true)
end)

concommand.Add("rf_music_stop", Music.StopAll)

net.Receive("rf_music_cue", function()
	local cue = net.ReadString()

	if RF.MusicCues[cue] then
		Music.PlayCue(cue)
	else
		Music.PlaySting(cue)
	end
end)

hook.Add("ShutDown", "RF.MusicStop", Music.StopAll)
