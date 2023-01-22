--//Aero Game Framework Rewrite
--//Intended to replace the aging codebase on Nightfall
--//TODO: add middleware to remote functions
--//TODO: implement method and event caching

--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--//Constants

local IS_SERVER = RunService:IsServer()

--//Variables

local Shared = script.Parent.Parent:WaitForChild("Shared") --//explanation why we dont just index rep storage: it is possible our end user could move the rep storage folder (the parent parent folder) somewhere else
local ServicesFolder = IS_SERVER and Instance.new("Folder") or script:WaitForChild("Services")

local FastSignal = require(Shared:WaitForChild("FastSignal"))
local BridgeNet = require(Shared:WaitForChild("BridgeNet"))

local Aero = {
	Controllers = not IS_SERVER and {} or nil, --//client stuff is automatically removed
	Services = {},
	Modules = {},
	Shared = {},
	Player = Players.LocalPlayer --//will always be nil for the server
}
local ModulesAwaitingStart = {}

--//Metatable Initialization

Aero.__index = Aero

--//Private

local function PreventRegister()
	error("Cannot call register outside of the init function.")
end

local function LazyLoadModules(Table, Folder)
	setmetatable(Table, {
		__index = function(_, Index)
			local Child = Folder:FindFirstChild(Index)
			if Child and (Child:IsA("ModuleScript")) then
				local Module = require(Child)
				rawset(Table, Index, Module)
				if (type(Module) == "table") then
					local ModuleMeta = getmetatable(Module)
					if (not (ModuleMeta and ModuleMeta.__call)) then
						Aero:WrapModule(Module)
					end
				end
				return Module
			elseif Child and (Child:IsA("Folder")) then
				local NestedTable = {}
				rawset(Table, Index, NestedTable)
				LazyLoadModules(NestedTable, Child)
				return NestedTable
			end
		end;
	})
end
--//Public

function Aero:WrapModule(Table)
	assert(type(Table) == "table", "Expected table, got "..type(Table))
	Table._bridges = IS_SERVER and {} or nil
	Table._signals = {}
	if not Module.AeroStandaloneModule then
		setmetatable(Table, Aero)
	end
	Table.RegisterClientEvent = PreventRegister --//i need to figure out how to properly implement creating remotes into
	if type(Table.Init) == "function" then Table:Init() end
	Table.RegisterEvent = PreventRegister
	if type(Table.Start) == "function" then
		if (ModulesAwaitingStart) then
			table.insert(Table,ModulesAwaitingStart)
		else
			task.spawn(Table.Start, Table)
		end
	end
	return Table
end

function Aero:RegisterEvent(Name,InboundMiddleware,OutboundMiddleware)
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(not self._signals[Name],"A event with the name "..Name.." already exists.")
	local Signal = {
		Signal = FastSignal.new(),
		InboundMiddleware = type(InboundMiddleware) == "function" and InboundMiddleware or nil, --//Custom signal middleware implementation.
		OutboundMiddleware = type(OutboundMiddleware) == "function" and OutboundMiddleware or nil
	}
	self._signals[Name] = Signal
end

function Aero:RegisterClientEvent(Name,InboundMiddleware,OutboundMiddleware)
	assert(IS_SERVER,"RegisterClientEvent can only be called on the server!")
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(not self._bridges[Name],"A client event with the name "..Name.." already exists.")
	local Bridge = BridgeNet.CreateBridge(self._index.Name.."-"..Name)
	if type(InboundMiddleware) == "function" then
		Bridge:SetInboundMiddleware({InboundMiddleware})
	end
	if type(OutboundMiddleware) == "function" then
		Bridge:SetOutboundMiddleware({OutboundMiddleware})
	end
	self._index:SetAttribute(Name,"Event")
	self._bridges[Name] = Bridge
end

function Aero:ConnectEvent(Name,Callback)
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._signals[Name],"A event with the name "..Name.." does not exist.")
	assert(type(Callback) == "function","Expected function, got"..type(Callback))
	return self._signals[Name].Signal:Connect(function(...)
		Callback(self._signals[Name].InboundMiddleware and self._signals[Name].InboundMiddleware(...) or ...)
	end)
end

function Aero:ConnectClientEvent(Name,Callback)
	assert(IS_SERVER,"ConnectClientEvent can only be called on the server!")
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._bridges[Name],"A client event with the name "..Name.."does not exist.")
	assert(type(Callback) == "function","Expected function, got"..type(Callback))
	return self._bridges[Name]:Connect(Callback)
end

function Aero:WaitForEvent(Name)
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._signals[Name],"A event with the name "..Name.." does not exist.")
	return self._signals[Name].Signal:Wait()
end

function Aero:WaitForClientEvent(Name) --//makeshift Wait method for bridgenet
	assert(IS_SERVER,"WaitForClientEvent can only be called on the server!")
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._bridges[Name],"A client event with the name "..Name.." does not exist.")
	local Arguments = nil
	local Continue = false --//values could be nil so we need something like this.
	self._bridges[Name]:Once(function(...)
		Arguments = ...
		Continue = true
	end)
	repeat until Continue
	return Arguments
end

function Aero:FireEvent(Name,...)
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._signals[Name],"A event with the name "..Name.." does not exist.")
	self._signals[Name].Signal:Fire(self._signals[Name].OutboundMiddleware and self._signals[Name].OutboundMiddleware(...) or ...)
end

function Aero:FireClient(Name,Client,...)
	assert(IS_SERVER,"FireClient can only be called on the server!")
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._bridges[Name],"A client event with the name "..Name.."does not exist.")
	assert(typeof(Client) == "Instance" and Client:IsA("Player"),"Expected player, got"..typeof(Client))
	self._bridges[Name]:FireTo(Client,...)
end

function Aero:FireMultipleClients(Name,Clients,...)
	assert(IS_SERVER,"FireMultipleClients can only be called on the server!")
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._bridges[Name],"A client event with the name "..Name.."does not exist.")
	assert(type(Clients) == "table","Expected table, got"..type(Clients))
	self._bridges[Name]:FireToMultiple(Clients,...)
end

function Aero:FireAllClients(Name,...)
	assert(IS_SERVER,"FireAllClients can only be called on the server!")
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._bridges[Name],"A client event with the name "..Name.."does not exist.")
	self._bridges[Name]:FireAll(...)
end

function Aero:FireAllClientsInRange(Name,Origin,Range,...)
	assert(IS_SERVER,"FireAllClientsInRange can only be called on the server!")
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._bridges[Name],"A client event with the name "..Name.."does not exist.")
	assert(type(Origin) == "vector","Expected vector, got"..type(Origin))
	assert(type(Range) == "number","Expected number, got"..type(Range))
	self._bridges[Name]:FireAllInRange(Origin,Range,...)
end

function Aero:FireOtherClients(Name,Blacklisted,...)
	assert(IS_SERVER,"FireOtherClients can only be called on the server!")
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._bridges[Name],"A client event with the name "..Name.."does not exist.")
	assert(typeof(Blacklisted) == ("table" or "Instance" and Blacklisted:IsA("Player")),"Expected player, got"..typeof(Blacklisted))
	self._bridges[Name]:FireToAllExcept(Blacklisted,...)
end

function Aero:FireOtherClientsInRange(Name,Blacklisted,Origin,Range,...)
	assert(IS_SERVER,"FireOtherClientsInRange can only be called on the server!")
	assert(type(Name) == "string","Expected string, got"..type(Name))
	assert(self._bridges[Name],"A client event with the name "..Name.."does not exist.")
	assert(type(Origin) == "vector","Expected vector, got"..type(Origin))
	assert(type(Range) == "number","Expected number, got"..type(Range))
	assert(typeof(Blacklisted) == ("table" or "Instance" and Blacklisted:IsA("Player")),"Expected player, got"..typeof(Blacklisted))
	self._bridges[Name]:FireAllInRangeExcept(Blacklisted,Origin,Range,...)
end

return function (Source,Modules) --//source is just the services/controllers
	assert(not _G.Aero,"Aero can only be started once.")
	assert(typeof(Source) == "Instance","Expected Instance, got "..typeof(Source))
	assert(typeof(Modules) == "Instance","Expected Instance, got "..typeof(Modules))
	LazyLoadModules(Aero.Shared,Shared) --//typically id call this after variable declaration but imo it doesnt look good
	LazyLoadModules(Aero.Modules,Modules)
	for _,SourceFile in ipairs(Source:GetDescendants()) do
		local IsSourceFile = IS_SERVER and SourceFile.Name:match("Service$") or SourceFile.Name:match("Controller$") 
		if SourceFile:IsA("ModuleScript") and IsSourceFile then
			assert(not Aero[IS_SERVER and "Services" or "Controllers"][SourceFile.Name], "A source file with the name "..SourceFile.Name.." already exists.") --//should redo this cuz its ugly
			local RequiredSourceFile = require(SourceFile)
			RequiredSourceFile._signals = {}
			if IS_SERVER then
				local ServiceIndex = Instance.new("Folder")
				RequiredSourceFile._index = ServiceIndex
				RequiredSourceFile._bridges = {}
				if type(RequiredSourceFile.Client) == "table" then
					RequiredSourceFile.Client.Server = nil
					for FunctionName,RemoteFunction in pairs(RequiredSourceFile.Client) do
						assert(type(RemoteFunction) == "function", "Expected function got, "..type(RemoteFunction))
						local Bridge = BridgeNet.CreateBridge(SourceFile.Name.."-"..FunctionName)
						Bridge:OnInvoke(function(...) return RemoteFunction(RequiredSourceFile,...) end)
						ServiceIndex:SetAttribute(FunctionName,"Function")
						RequiredSourceFile._bridges[FunctionName] = Bridge
					end
					RequiredSourceFile.Client.Server = RequiredSourceFile
				end
				ServiceIndex.Name = SourceFile.Name
				ServiceIndex.Parent = ServicesFolder
			end
			setmetatable(RequiredSourceFile,Aero)
			Aero[IS_SERVER and "Services" or "Controllers"][SourceFile.Name] = RequiredSourceFile --//ALSO REALLY UGLY
		end
	end
	if not IS_SERVER then
		for _,Service in ipairs(ServicesFolder:GetChildren()) do
			if Service:IsA("Folder") then
				Aero.Services[Service.Name] = {}
				for AttributeName,AttributeValue in pairs(Service:GetAttributes()) do
					local Bridge = BridgeNet.CreateBridge(Service.Name.."-"..AttributeName)
					if AttributeValue == "Function" then
						Aero.Services[Service.Name][AttributeName] = function(_,...)
							return Bridge:InvokeServerAsync(...)
						end
					elseif AttributeValue == "Event" then
						Aero.Services[Service.Name][AttributeName] = Bridge
					end
				end
			end
		 end
	end
	for _,Table in pairs(IS_SERVER and Aero.Services or Aero.Controllers) do
		if type(Table.Init) == "function" then Table:Init() end
		Table.RegisterEvent = PreventRegister
		Table.RegisterClientEvent = PreventRegister
	end
	for _,Table in pairs(IS_SERVER and Aero.Services or Aero.Controllers) do
		if type(Table.Start) == "function" then task.spawn(Table.Start,Table) end
	end
	for _,Table in pairs(ModulesAwaitingStart) do
		task.spawn(Table.Start,Table)
	end
	ModulesAwaitingStart = nil
	ServicesFolder.Name = "Services"
	ServicesFolder.Parent = script
	_G.Aero = Aero
end
