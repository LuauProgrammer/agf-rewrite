--//Aero Game Framework Rewrite Client

--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Variables

local Framework = require(ReplicatedStorage:WaitForChild("Aero"):WaitForChild("Internal"):WaitForChild("AeroGameFramework"))
local Source = script.Parent.Parent:WaitForChild("Controllers")
local Modules = script.Parent.Parent:WaitForChild("Modules")

--//Main

Framework(Source,Modules)