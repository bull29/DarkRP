AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props/cs_assault/Billboard.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()

    if phys and phys:IsValid() then
        phys:Wake()
        phys:EnableMotion(false)
    end
end

local hookcanAdvert = {canAdvert = function(_, ply, action, args)
    return true
end}

function ENT:SetDefaults(txt)
    txt = string.gsub(string.gsub(txt or "", "//", "\n"), "\\n", "\n")
    local split = string.Split(txt, "\n") or {}
    local hasTitle = #split > 1
    if not hasTitle then split = string.Split(txt, " ") end

    self:SetTopText(split[1] or "Placeholder")
    self:SetBottomText(table.concat(split, hasTitle and "\n" or " ", 2))

    self:SetBarColor(Vector(1, 0.5, 0))
end

local function canEditVariable(_, ent, ply, key, val, editor)
    return ent:CPPICanPhysgun(ply)
end

local function placeBillboard(ply, args)
    local canEdit, message = hook.Call("canAdvert", hookcanAdvert, ply, args)

    if not canEdit then
        DarkRP.notify(ply, 1, 4, message ~= nil and message or DarkRP.getPhrase("unable", GAMEMODE.Config.chatCommandPrefix .. "advertise", ""))
        return ""
    end

    ply.DarkRP_advertboards = ply.DarkRP_advertboards or 0

    if ply.DarkRP_advertboards >= GAMEMODE.Config.maxadvertbillboards then
        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("limit", GAMEMODE.Config.chatCommandPrefix .. "advert"))
        return ""
    end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 85
    trace.filter = ply

    local tr = util.TraceLine(trace)

    local ent = ents.Create("darkrp_billboard")
    ent:SetPos(tr.HitPos + Vector(0, 0, (ply:GetPos().z - tr.HitPos.z) + 69))

    local ang = ply:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 180)
    ent:SetAngles(ang)

    ent:CPPISetOwner(ply)
    ent.SID = ply.SID

    ent:SetDefaults(args)
    hook.Add("CanEditVariable", ent, canEditVariable)

    ent:Spawn()
    ent:Activate()

    if IsValid(ent) then
        ply.DarkRP_advertboards = ply.DarkRP_advertboards + 1
    end

    ply:DeleteOnRemove(ent)

    return ""
end
DarkRP.defineChatCommand("advert", placeBillboard)

function ENT:OnRemove()
    local ply = Player(self.SID)

    if not IsValid(ply) then return end

    ply.DarkRP_advertboards = (ply.DarkRP_advertboards or 1) - 1
end


