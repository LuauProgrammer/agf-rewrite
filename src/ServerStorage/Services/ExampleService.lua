-- Server:
local MyService = {Client = {}}

function MyService.Client:Respawn(player)

    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")

    -- Only allow respawning if the player is dead:
    if ((not humanoid) or humanoid.Health == 0) then
        player:LoadCharacter()
        return true
    end

    return false
    
end

function MyService:Init()
	self:RegisterEvent("test",function(...)
		print(...)
	end)
	
	self:ConnectEvent("test",function(...)
		print("Test")
	end)
    self:RegisterClientEvent("funny",function(...)
        print(...)
        return false
    end)

    self:ConnectClientEvent("funny",function(...)
        print(...)
        print("this time we have it")
	end)
	
	self:Fire("test","lol")
end

return MyService