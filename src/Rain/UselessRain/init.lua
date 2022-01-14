--> Services <--
local RunService = game:GetService('RunService');

--> Objects <--
local Particle = require(script:WaitForChild('attachmentthing')).Init(1, 1);
local Rand = Random.new();

local Rain = {};
Rain.__index = Rain;
local SplashQueue = {};

local function getEmptyIndex(tbl)
	local index = 0;
	for i in ipairs(tbl) do
		index = i;
	end
	return index+1;
end

function Rain.Init(Settings)

	local self = setmetatable({
		_Enabled = true,

		_Follow = Settings.Attach or error('Must specify attachment basepart.'),
		_Rate = Settings.Rate or 50,
		_Area = Settings.EmitArea or 50,
		_EmitOffset = Settings.EmitOffset or Vector3.yAxis * 50,
		_DropletSpeed = Settings.Speed or 100,
		_DropletMaxTravel = Settings.MaxTravel or 200
	}, Rain);

	Particle:Resize(self._Rate, self._DropletMaxTravel/self._DropletSpeed);
	self:_Reconnect();

	return self;
end

function Rain:Toggle(bool: boolean)
	if (self._Enabled == bool) then return end;
	self._Enabled = bool;

	if (bool) then
		Rain:_Reconnect();
	else
		RunService:UnbindFromRenderStep('RainDropletUpdate');
		RunService:UnbindFromRenderStep('RainSplashUpdate');
	end
end

function Rain:Clear()
	Particle:ClearParticles();
end

function Rain:_Reconnect()
	local t = 0;
	RunService:BindToRenderStep('RainDropletUpdate', Enum.RenderPriority.Camera.Value+1, function(deltaTime)
		t+=deltaTime;

		if (t >= 1 / self._Rate) then
			local Position = self._Follow.Position;

			local DropletSpeed = self._DropletSpeed;
			local DropletMaxTravel = self._DropletMaxTravel;

			local EmitArea = self._Area;
			local EmitOffset = self._EmitOffset;

			for _ = 1, t/(1 / self._Rate) do
				local RandomPosition =
					Position + EmitOffset + Vector3.new(
						Rand:NextNumber(-EmitArea, EmitArea), 0,
						Rand:NextNumber(-EmitArea, EmitArea)
					);

				local instance = Particle:GetAvailableDroplet();

				local RaycastResult = workspace:Raycast(RandomPosition, -Vector3.yAxis * DropletMaxTravel)
				if (RaycastResult) then
					local SplashPosition = RaycastResult.Position;

					instance.ParticleEmitter.Lifetime = NumberRange.new((RandomPosition.Y - SplashPosition.Y)/DropletSpeed);
					SplashQueue[getEmptyIndex(SplashQueue)] = {
						Position = SplashPosition,
						Time = os.clock() + (RandomPosition.Y - SplashPosition.Y)/DropletSpeed
					};
				end

				instance.Position = RandomPosition;
				instance.ParticleEmitter:Emit(1);
			end

			t=0;
		end
	end)

	--> Emit splash when timer is done
	RunService:BindToRenderStep('RainSplashUpdate', Enum.RenderPriority.Camera.Value+2, function()
		for i, v in pairs(SplashQueue) do
			if (v and os.clock() >= v.Time) then
				SplashQueue[i] = nil;
				local instance = Particle:GetAvailableSplash();

				instance.Position = v.Position;
				instance.ParticleEmitter:Emit(1);
			end

			--> Prevent the script from exhausting
			if (i%1000 == 0) then task.wait(.01); end
		end
	end)
end

return Rain;