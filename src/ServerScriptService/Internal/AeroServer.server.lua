--//Aero Game Framework Rewrite Server

--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--//Variables

local Framework = require(ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Internal"):WaitForChild("AeroGameFramework"))
local Source = ServerStorage:WaitForChild("Aero"):WaitForChild("Services")
local Modules = ServerStorage:WaitForChild("Aero"):WaitForChild("Modules")

--//Main

Framework(Source,Modules)