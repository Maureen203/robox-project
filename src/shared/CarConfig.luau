-- Car configuration for the racing game

export type CarType = {
	Name: string,
	MaxSpeed: number,
	Torque: number,
	TurnSpeed: number,
	BodySize: Vector3,
	SeatOffset: Vector3,
	WheelRadius: number,
	WheelWidth: number,
	RoofStyle: string, -- "sedan", "sport", "truck"
	Description: string,
}

local CarConfig = {
	-- Different car models players can choose
	CarTypes = {
		Sport = {
			Name = "Sport",
			MaxSpeed = 50,
			Torque = 80,
			TurnSpeed = 3.5,
			BodySize = Vector3.new(5.5, 1.2, 11),
			SeatOffset = Vector3.new(0, 0.6, -1),
			WheelRadius = 1.0,
			WheelWidth = 0.9,
			RoofStyle = "sport",
			Description = "Fast & agile, but light",
		} :: CarType,

		Muscle = {
			Name = "Muscle",
			MaxSpeed = 45,
			Torque = 120,
			TurnSpeed = 2.5,
			BodySize = Vector3.new(6.5, 1.5, 11),
			SeatOffset = Vector3.new(0, 0.8, -1),
			WheelRadius = 1.3,
			WheelWidth = 1.0,
			RoofStyle = "sedan",
			Description = "Raw power, slower turns",
		} :: CarType,

		Truck = {
			Name = "Truck",
			MaxSpeed = 35,
			Torque = 150,
			TurnSpeed = 2.0,
			BodySize = Vector3.new(7, 2.5, 12),
			SeatOffset = Vector3.new(0, 1.2, -1),
			WheelRadius = 1.6,
			WheelWidth = 1.2,
			RoofStyle = "truck",
			Description = "Heavy & tough, hard to stop",
		} :: CarType,

		Racer = {
			Name = "Racer",
			MaxSpeed = 60,
			Torque = 70,
			TurnSpeed = 4.0,
			BodySize = Vector3.new(5, 1.0, 12),
			SeatOffset = Vector3.new(0, 0.5, -1),
			WheelRadius = 0.9,
			WheelWidth = 1.1,
			RoofStyle = "sport",
			Description = "Top speed, needs skill",
		} :: CarType,
	},

	-- Default car type
	DefaultCarType = "Sport",

	-- Colors for each player (cycles through)
	Colors = {
		BrickColor.new("Bright red"),
		BrickColor.new("Bright blue"),
		BrickColor.new("Bright green"),
		BrickColor.new("Bright yellow"),
		BrickColor.new("Bright orange"),
		BrickColor.new("Bright violet"),
		BrickColor.new("Hot pink"),
		BrickColor.new("Cyan"),
	},

	-- Boost pad settings
	BoostMultiplier = 1.5, -- speed multiplier when hitting a boost pad
	BoostDuration = 2.0, -- seconds the boost lasts

	-- Crash settings
	CrashSpeedThreshold = 10, -- minimum speed to trigger a crash on wall hit
	CrashCooldown = 3, -- seconds before another crash can be detected

	-- Sound IDs (Roblox asset IDs)
	Sounds = {
		Engine = "rbxassetid://9125402735",       -- engine loop
		Boost = "rbxassetid://9125958726",         -- boost whoosh
		Countdown = "rbxassetid://9125624735",     -- countdown beep
		Go = "rbxassetid://9125624735",            -- go sound
		LapComplete = "rbxassetid://9125402735",   -- lap ding
		Finish = "rbxassetid://9125958726",        -- finish fanfare
		Crash = "rbxassetid://9125402735",         -- crash/bump
	},
}

return CarConfig
