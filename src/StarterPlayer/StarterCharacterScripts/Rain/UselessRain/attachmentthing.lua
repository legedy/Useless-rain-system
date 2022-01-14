local RunService = game:GetService('RunService');

local DROPLET = workspace.Terrain.Droplet;
local SPLASH = workspace.Terrain.Splash;

local thing = {};
thing.__index = thing;

function thing.Init(Rate, Lifetime)
	thing.Init = nil;

	local self = setmetatable({

		_CacheAmount = math.round(Rate/Lifetime),
		_LastAccessIndex = {
			Droplet = 1,
			Splash = 1
		},

		_Using = {
			Droplet = {},
			Splash = {}
		},

		_CacheStorage = {
			Droplet = {},
			Splash = {}
		}

	}, thing);

	for i = 1, self._CacheAmount do
		local Droplet = DROPLET:Clone();
		local Splash = SPLASH:Clone();

		self._CacheStorage.Droplet[i] = Droplet;
		self._CacheStorage.Splash[i] = Splash;

		Droplet.Parent = workspace.Terrain;
		Splash.Parent = workspace.Terrain;
	end

	local skip = false;
	RunService:BindToRenderStep('CleanDroplets', Enum.RenderPriority.Camera.Value+3, function()
		if (skip) then return end;
		skip = false;
		self:CleanUp();
	end);

	return self;
end

function thing:GetAvailableSplash(): Attachment
	local instance = self._CacheStorage.Splash[#self._CacheStorage.Splash];

	table.remove(self._CacheStorage.Splash, #self._CacheStorage.Splash);
	table.insert(self._Using.Splash, instance);

	return instance;
end

function thing:GetAvailableDroplet(): Attachment
	local instance = self._CacheStorage.Droplet[#self._CacheStorage.Droplet];

	table.remove(self._CacheStorage.Droplet, #self._CacheStorage.Droplet);
	table.insert(self._Using.Droplet, instance);

	return instance;
end

function thing:Resize(Rate, Lifetime)
	local LTRange = NumberRange.new(Lifetime);
	local lastAmount = self._CacheAmount;
	self._CacheAmount = math.round(Rate/Lifetime);

	if (lastAmount >= self._CacheAmount) then return end;

	for _, v in ipairs(self._CacheStorage.Droplet) do
		v.ParticleEmitter.Lifetime = LTRange;
	end

	for i = lastAmount, self._CacheAmount do
		local Droplet = DROPLET:Clone();
		local Splash = SPLASH:Clone();

		self._CacheStorage.Droplet[i] = Droplet;
		self._CacheStorage.Splash[i] = Splash;

		Droplet.Parent = workspace.Terrain;
		Splash.Parent = workspace.Terrain;
	end
end

function thing:ClearParticles()
	for i = 1, self._CacheAmount do
		self._CacheStorage.Droplet[i].ParticleEmitter:Clear();
		self._CacheStorage.Splash[i].ParticleEmitter:Clear();
	end
end

function thing:CleanUp()
	for i, v in pairs(self._Using.Droplet) do
		table.remove(self._Using.Droplet, i);
		table.insert(self._CacheStorage.Droplet, v);
	end

	for i, v in pairs(self._Using.Splash) do
		table.remove(self._Using.Splash, i);
		table.insert(self._CacheStorage.Splash, v);
	end
end

return thing;