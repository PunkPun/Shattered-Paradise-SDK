--[[
   Copyright The OpenRA Developers (see AUTHORS)
   This file is part of OpenRA, which is free software. It is made
   available to you under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of
   the License, or (at your option) any later version. For more
   information, see COPYING.
]]

Difficulty = Map.LobbyOption("difficulty")

GDIWays ={
	{Reinforce_1.Location, Way1.Location, Way2.Location, Way2_up_1.Location, Way2_up_2.Location, Way2_up_3.Location},
	{Reinforce_1.Location, Way1.Location, Way2.Location, Way2_down_1.Location, Way2_down_2.Location, Way2_down_3.Location, Way2_down_4.Location}
}

GDIForces = {"hvr", "hvr", "apc", "mmch", "mmch", "sonic", "sonic", "g4tnk", "g4tnk", "mcv" }

MissionText = function()
	Objective1 = player.AddPrimaryObjective("Survive and protect MCV as many as you can!")
	SecondaryObjective1 = player.AddSecondaryObjective("Protect at least 4 MCVs.")
	Media.DisplayMessage("Select this defence and attack target manually!", "Tip", HSLColor.FromHex("29F3CF"))
	IonTur.Flash(HSLColor.FromHex("FFFFFF"), 15, DateTime.Seconds(1) / 4)
end

CheckObjectivesOnMissionEnd = function(survived)
	if survived then
		player.MarkCompletedObjective(Objective1)
	else
		player.MarkFailedObjective(Objective1)
	end

	if MCVprotected >= 4 then
		player.MarkCompletedObjective(SecondaryObjective1)
	else
		player.MarkFailedObjective(SecondaryObjective1)
	end
end

CivSquad = {Protester6, Protester5, Protester4, Protester3, Protester2, Protester1}
RandomHardModes = {"HackerMode", "VeinholeMode"}
DifficultySetUp = function()
	Actor.Create("upgrade.tiberium_gas_warheads", true, { Owner =  bandits_ai})
	Actor.Create("upgrade.lynx_rockets",  true, { Owner =  bandits_ai})
	Actor.Create("upgrade.tiberium_infusion", true, { Owner =  bandits_ai})

	if Difficulty == "easy" then
		bandits_ai.GrantCondition("easy-game")
		Utils.Do(CivSquad, function(a)
			a.Destroy()
		end)
		Eye1.Destroy()
		Eye2.Destroy()
	elseif Difficulty == "normal" then
		bandits_ai.GrantCondition("normal-game")
		Trigger.AfterDelay(1000, function()
			SendNukeLoop()
		end)
		Utils.Do(CivSquad, function(a)
			a.Destroy()
		end)
		Eye1.Destroy()
		Eye2.Destroy()
	else
		bandits_ai.GrantCondition("hard-game")

		Trigger.AfterDelay(800, function()
			SendNukeLoop()
		end)

		local mode = Utils.Random(RandomHardModes)
		if mode  == "VeinholeMode" then
			Trigger.AfterDelay(50, function()
				Veinhole1.Attack(IonTur, true, true)
			end)
			Trigger.AfterDelay(200, function()
				Media.DisplayMessage("Sorry man, I ate too much last night and I really feel sick today.", "Mr.Hole", HSLColor.FromHex("FF8812"))
				Veinhole1.GrantCondition("talking", 130)
				Veinhole1.Flash(HSLColor.FromHex("FFFFFF"), 10, DateTime.Seconds(1) / 3)
			end)
			Utils.Do(CivSquad, function(a)
				a.Destroy()
			end)
		elseif mode  == "HackerMode" then
			Trigger.AfterDelay(150, function()
				Media.DisplayMessage("This vile GDI machine brings only war to our home, we must turn it off!", "Protesters", HSLColor.FromHex("66AAFF"))
				SendHackerLoop()
			end)
			Trigger.AfterDelay(160, function()
				if Hacker == nil or Hacker.IsDead then
					return
				end
				Hacker.Flash(HSLColor.FromHex("FFFFFF"), 25, DateTime.Seconds(1) / 4)
			end)
			Utils.Do(CivSquad, function(a)
				CivRespawnOnKill(a, Cab_way1.Location)
			end)
			Eye1.Destroy()
			Eye2.Destroy()
		end
	end
end

SendWaveLoop = function()
	Reinforcements.Reinforce(gdi_ai, GDIForces, Utils.Random(GDIWays), 60,  function(a)
		if a.Type == "mcv" then
			MCVprotected = MCVprotected + 1
			Media.DisplayMessage(string.format("A MCV has been secured! You have saved %d.", MCVprotected), "Notification", HSLColor.FromHex("EEEE66"))
		end
		a.Destroy()
	end)

	Waves = Waves - 1
	if Waves <= 0 then
		return
	end

	Trigger.AfterDelay(1000, function()
		SendWaveLoop()
	end)
end

CabHackerPath = {Cab_way1.Location, Cab_way2.Location}
SendHackerLoop = function()
	if (Hacker == nil or Hacker.IsDead) and not IonTur.IsDead then
		Hacker = Utils.Random(Reinforcements.Reinforce(cab_ai, {"cabecm"}, CabHackerPath, 60, function(a)
			a.Attack(IonTur)
		end))
	end

	Trigger.AfterDelay(20, function()
		SendHackerLoop()
	end)
end

NukeSpawnPoints = {Mut_nuke1.Location, Mut_nuke2.Location, Mut_nuke3.Location}
NukeSounds = {"demotruckvoice0006.aud", "demotruckvoice0007.aud", "demotruckvoice0008.aud"}
NukeSpawnDelay = {700, 800, 1000, 1100, 1200}
SendNukeLoop = function()

	local nuke = Utils.Random(Reinforcements.Reinforce(bandits_ai, {"hvrtruk3"}, {Utils.Random(NukeSpawnPoints), IonTurLocation}, 10, function(a)
		if not IonTur.IsDead then
			a.Attack(IonTur)
		end
	end))

	Trigger.AfterDelay(1, function()
		nuke.Flash(HSLColor.FromHex("FFFFFF"), 25, DateTime.Seconds(1) / 4)
		Media.PlaySound(Utils.Random(NukeSounds))
	end)

	Trigger.AfterDelay(Utils.Random(NukeSpawnDelay), function()
		SendNukeLoop()
	end)
end

CivRespawnOnKill = function(actor, spawnLoc, toLoc)
	if (spawnLoc == nil) then
		return
	end

	Trigger.OnKilled(actor, function(s,k)
		respawned = Actor.Create(actor.Type, true, {Owner = actor.Owner, Location = spawnLoc})
		if respawned ~= nil then
			if (toLoc == nil) then
				toLoc = actor.Location
			end
			respawned.Move(toLoc)
			CivRespawnOnKill(respawned, spawnLoc, toLoc)
		end
	end)
end

Tick = function()
	if RemainingTime >= 0 then
		RemainingTime = RemainingTime - 1
		UserInterface.SetMissionText( "Remaining Time: " .. Utils.FormatTime(RemainingTime))
	else
		UserInterface.SetMissionText("You Survived!")
		CheckObjectivesOnMissionEnd(true)
	end

	--## Kodiak comes to save you plot
	if RemainingTime == 280 then
		Media.DisplayMessage("Hold on, we are going to pick you up!", "GDI Commander", HSLColor.FromHex("EEEE66"))

		local kodiak = Utils.Random(Reinforcements.Reinforce(gdi_ai, {"kodk"}, {Reinforce_1.Location, IonTurLocation}, 10, function(a)
			Trigger.AfterDelay(105, function()
				if not IonTur.IsDead then
					a.Land(IonTur)
				end
			end)
		end))

		Trigger.AfterDelay(100, function()
			Media.DisplayMessage("Orbital strikes! NOW!!!", "GDI Commander", HSLColor.FromHex("EEEE66"))
			kodiak.GrantCondition("can-active")
			Utils.Do(gdi_ai.GetActorsByType("orbit.dummy"), function(a)
				a.Attack(kodiak, true)
			end)
		end)
	end
end

WorldLoaded = function()
	bandits_ai = Player.GetPlayer("Bandits")
	cab_ai = Player.GetPlayer("Instigator")
	gdi_ai = Player.GetPlayer("GDI")
	player = Player.GetPlayer("You")
	MCVprotected = 0
	Waves = 6
	RemainingTime = 6800
	IonTurLocation = IonTur.Location
	Hacker = nil

	MissionText()
	DifficultySetUp()

	Trigger.AfterDelay(200, function()
		SendWaveLoop()
	end)

	Trigger.OnKilled(IonTur, function(s, k)
		CheckObjectivesOnMissionEnd(false)
	end)

	Utils.Do(bandits_ai.GetActorsByType("mutambush"), function(a)
		Actor.Create("orbit.dummy", true, {Owner = gdi_ai, Location = a.Location})
	end)
end
