-- Client:
local MyController = {}

function MyController:Start()
    local didRespawn = self.Services.ExampleService:Respawn()
    print(didRespawn)
    if (didRespawn) then
        print("we respawned!")
    end

    self.Services.ExampleService.funny:Fire("random","args")
end

return MyController