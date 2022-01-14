local PartCache = require(script:WaitForChild('PartCache'));

local RunService = game:GetService('RunService');
local Players = game:GetService('Players');

local Player = Players.LocalPlayer;
local Character = Player.Character or Player.CharacterAdded:Wait();

local HRP = Character.HumanoidRootPart;

--> Settings <--
local Rate = 1000;
local DropletSpeed = 100;
local DropletMaxTravel = 500;
local EmitOffset = Vector3.yAxis * DropletMaxTravel/2;
local EmitArea = 100;

require(script.UselessRain).Init{
	Attach = HRP,
	Rate = Rate,
	EmitArea = EmitArea,
	EmitOffset = EmitOffset,
	Speed = DropletSpeed,
	MaxTravel = DropletMaxTravel
}