-- Race configuration
return {
	Laps = 3,
	CountdownSeconds = 3,
	RespawnHeight = -50,

	-- Track settings
	TrackWidth = 30,
	WallHeight = 5,
	WallThickness = 2,

	-- Boost pad positions (placed on specific track segments)
	-- Each entry is a track segment index where a boost pad is placed
	BoostPadSegments = { 2, 5, 8, 11 },
	BoostPadSize = Vector3.new(10, 0.3, 8),
}
