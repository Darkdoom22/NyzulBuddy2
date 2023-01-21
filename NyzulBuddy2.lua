_addon.name = "NyzulBuddy2"
_addon.author = "Uwu/Darkdoom"
_addon.version = "0.01a"

local packets = require('packets')
local texts = require('texts')
local dialogue = require('dialog')
local file = require('files')
local table = require('tables')

local DefaultSettings = {}
DefaultSettings.flags = {}
DefaultSettings.flags.draggable = true
DefaultSettings.pos = {}
DefaultSettings.pos.x = 300
DefaultSettings.pos.y = 600
DefaultSettings.text = {}
DefaultSettings.text.font = 'Consolas'
DefaultSettings.text.size = 10
DefaultSettings.text.alpha = 255
DefaultSettings.text.red = 249
DefaultSettings.text.green = 236
DefaultSettings.text.blue = 236
DefaultSettings.text.stroke = {}
DefaultSettings.text.stroke.alpha = 175
DefaultSettings.text.stroke.red = 11
DefaultSettings.text.stroke.green = 16
DefaultSettings.text.stroke.blue = 15
DefaultSettings.text.stroke.width = 2.0
DefaultSettings.text.flags = {}
DefaultSettings.text.flags.bold = true
DefaultSettings.bg = {}
DefaultSettings.bg.alpha = 160
DefaultSettings.bg.red = 55
DefaultSettings.bg.green = 50
DefaultSettings.bg.blue = 50

local Constants = {
    ["NyzulZoneId"] = 77,
    ["TimeLimit"] = 1800,
    --these haven't changed in years so I don't mind hardcoding
    ["RunesOfTransferIndexes"] = T{
        0x2D2, --Rune Of Transer even
        0x2D3, --Rune Of Transfer odd
    },
    ["LampsIndexes"] = T{
        0x2D4, --Lamps 1-5
        0x2D5,
        0x2D6,
        0x2D7,
        0x2D8,
    },
}

local NyzulBuddy = {
    ["FloorStr"] = "",
    ["ObjectiveStr"] = "",
    ["TimeStr"] = "",
    ["TimeRemaining"] = 0,
    ["RunStartTime"] = os.clock(),
    ["UI"] = {
        ["UpdateTimer"] = os.clock(),
        ["UpdateInterval"] = 1,
        ["TextBox"] = texts.new("", DefaultSettings),
    },
    ["Runes"] = {
        [Constants["RunesOfTransferIndexes"][1]] = {},
        [Constants["RunesOfTransferIndexes"][2]] = {},
    },
    ["Lamps"] = {
        [Constants["LampsIndexes"][1]] = {},
        [Constants["LampsIndexes"][2]] = {},
        [Constants["LampsIndexes"][3]] = {},
        [Constants["LampsIndexes"][4]] = {},
        [Constants["LampsIndexes"][5]] = {},
    }
}

windower.register_event('load', function()
    --uncomment to log messages
    --[[if(not file.exists("36msg.txt"))then
        local dialogueFile = file.new("36msg.txt", true)
        dialogueFile:create()
    end

    if(not file.exists("2amsg.txt"))then
        local dialogueFile = file.new("2amsg.txt", true)
        dialogueFile:create()
    end

    if(not file.exists("27msg.txt"))then
        local dialogueFile = file.new("27msg.txt", true)
        dialogueFile:create()
    end]]--
end)

windower.register_event('zone change', function()
    for k,_ in pairs(NyzulBuddy["Runes"]) do
        NyzulBuddy["Runes"][k] = {}
    end

    for k,_ in pairs(NyzulBuddy["Lamps"]) do
        NyzulBuddy["Lamps"][k] = {}
    end

    NyzulBuddy["FloorStr"] = ""
    NyzulBuddy["ObjectiveStr"] = ""
    NyzulBuddy["TimeStr"] = ""
end)

local function Distance(pos1, pos2)
    return math.sqrt((pos1.x - pos2.x)^2 + (pos1.y - pos2.y)^2 + (pos1.z - pos2.z)^2)
end

local function NpcRequest(index)
    if(index and index > 0 and index < 2304) then
        local npcRequest = packets.new('outgoing', 0x016)
        npcRequest["Target Index"] = index
        packets.inject(npcRequest)
    end
end

local function AngleBetween(x,y)
    local player = windower.ffxi.get_mob_by_target("me")
    if(x and y and player)then
        local dx = x - player.x
        local dy = y - player.y
        local theta = math.atan2(dy, dx)
        theta = theta * 180 / math.pi
        if(theta < 0) then
            theta = theta + 360
        end
        return theta    
    end
    return 0
end

local function GetCardinalForAngle(angle)
    if(angle)then
        if(angle >= 337.5 or angle < 22.5)then
            return "E"
        elseif(angle >= 22.5 and angle < 67.5)then
            return "NE"
        elseif(angle >= 67.5 and angle < 112.5)then
            return "N"
        elseif(angle >= 112.5 and angle < 157.5)then
            return "NW"
        elseif(angle >= 157.5 and angle < 202.5)then
            return "W"
        elseif(angle >= 202.5 and angle < 247.5)then
            return "SW"
        elseif(angle >= 247.5 and angle < 292.5)then
            return "S"
        elseif(angle >= 292.5 and angle < 337.5)then
            return "SE"
        end
    end
end

function NyzulBuddy:RequestRunes()
    for _,v in pairs(Constants["RunesOfTransferIndexes"]) do
        NpcRequest(v)
    end
end

function NyzulBuddy:RequestLamps()
    for _,v in pairs(Constants["LampsIndexes"]) do
        NpcRequest(v)
    end
end

function NyzulBuddy:Update2AMessage(packet)
    local messageId = bit.band(packet["Message ID"], 0x3FFF)
    if(messageId)then
        if(messageId == 7301)then
            self["ObjectiveStr"] = "Objective: Get going!"
        elseif(messageId == 7311)then
            self["TimeStr"] = string.format("%s", packet["Param 1"])
            self["RunStartTime"] = os.clock()
        elseif(messageId == 7492)then
            NyzulBuddy:RequestRunes()
            self["FloorStr"] = string.format("%s", packet["Param 1"])
        elseif(messageId == 7312)then
            self["ObjectiveStr"] = "Objective: git gud:("
        end
    end
end

function NyzulBuddy:Update27Message(packet)
    local messageId = bit.band(packet["Message ID"], 0x3FFF)
    if(messageId)then
        if(messageId == 7356)then
            self["ObjectiveStr"] = "Floor complete, up up!"
            self:RequestRunes()
        elseif(messageId == 7316)then
            self["TimeStr"] = string.format("%s", packet["Param 1"])
        end
    end
end

function NyzulBuddy:Update36Message(packet)
    local messageId = bit.band(packet["Message ID"], 0x3FFF)
    if(messageId)then
        local f = dialogue.open_dat_by_zone_id(Constants["NyzulZoneId"], "english")
        local zoneDat = f:read("*a")
        f:close()
        local message = dialogue.decode_string(dialogue.get_entry(zoneDat, messageId))
        if(not message:contains("restricted") and not message:contains("reduced")
         and not message:contains("destroy") and not message:contains("removed")
          and not message:contains("Afflicted") and not message:contains("discovery")
            and not message:contains("malfunction") and not message:contains("Boost")
             and not message:contains("effect"))then
            self["ObjectiveStr"] = string.format("%s", message)
        end

        if(message:contains("lamp") or message:contains("lamps") or message:contains("certification"))then
            self:RequestLamps()
        end

        --[[if(messageId == 7371)then
            self:RequestLamps()
        end]]--
    end
end

function NyzulBuddy:HandleNpcUpdate(packet)
    if(Constants["RunesOfTransferIndexes"]:contains(packet["Index"]))then
        local mobStruct = windower.ffxi.get_mob_by_index(packet["Index"])
        if(mobStruct)then
            self["Runes"][mobStruct["index"]]["Mob"] = mobStruct
            if(packet["_unknown4"] > 0)then
                self["Runes"][mobStruct["index"]]["Activated"] = bit.band(bit.rshift(packet["_unknown4"], 16), 0x01) > 0
            end
        end
    elseif(Constants["LampsIndexes"]:contains(packet["Index"]))then
        local mobStruct = windower.ffxi.get_mob_by_index(packet["Index"])
        if(mobStruct)then
            self["Lamps"][mobStruct["index"]]["Mob"] = mobStruct
            if(packet["_unknown4"] > 0)then
                self["Lamps"][mobStruct["index"]]["Activated"] = bit.band(bit.rshift(packet["_unknown4"], 16), 0x01) > 0
            end
        end
    end
end

windower.register_event('incoming chunk', function(id, data)
    if(id == 0x02A and windower.ffxi.get_info().zone == Constants["NyzulZoneId"])then
        local packet = packets.parse('incoming', data)
        NyzulBuddy:Update2AMessage(packet)
        --uncomment to log messages
        --[[print("2a msg")
        local f = dialogue.open_dat_by_zone_id(Constants["NyzulZoneId"], "english")
        local zoneDat = f:read("*a")
        f:close()
        local packet = packets.parse('incoming', data)
        local msgId = bit.band(packet["Message ID"], 0x3FFF)
        --print(msgId)
        local message = dialogue.get_entry(zoneDat, msgId)
        local floorNumber = packets["param1"]
        --param 2 is dupe floor for up message?
        --param 3 looks like a constant
        if(message)then
            --print(dialogue.decode_string(message))
            local formattedStr = string.format("id:%s, msg:%s, param1:%s, param2:%s, param3:%s",
                msgId, dialogue.decode_string(message), packet["Param 1"], packet["Param 2"], packet["Param 3"])
            file.append("2amsg.txt", formattedStr .. "\r\n")
        end]]--
    elseif(id == 0x036 and windower.ffxi.get_info().zone == Constants["NyzulZoneId"])then
        --print("36 msg")
        local packet = packets.parse('incoming', data)
        NyzulBuddy:Update36Message(packet)
        --uncomment to log messages
        --[[local f = dialogue.open_dat_by_zone_id(Constants["NyzulZoneId"], "english")
        local zoneDat = f:read("*a")
        f:close()
        local msgId = bit.band(packet["Message ID"], 0x3FFF)
        --print(msgId)
        local message = dialogue.get_entry(zoneDat, msgId)
        if(message)then
           -- print(dialogue.decode_string(message))
            local formattedStr = string.format("id:%s, msg:%s, param1:%s, param2:%s",
            msgId, dialogue.decode_string(message), packet["_unknown1"], packet["_unknown2"])
            file.append("36msg.txt", formattedStr .. "\r\n")
        end]]--
    elseif(id == 0x027 and windower.ffxi.get_info().zone == Constants["NyzulZoneId"])then
        --print("27 msg")
        local packet = packets.parse('incoming', data)
        NyzulBuddy:Update27Message(packet)
        --uncomment to log messages
        --[[local f = dialogue.open_dat_by_zone_id(Constants["NyzulZoneId"], "english")
        local zoneDat = f:read("*a")
        f:close()
        local msgId = bit.band(packet["Message ID"], 0x3FFF)
        --print(msgId)
        local message = dialogue.get_entry(zoneDat, msgId)
        if(message)then
           -- print(dialogue.decode_string(message))
            local unk6StringStrippedNulls = packet["_unknown6"]:gsub("%z+", "")
            local formattedStr = string.format("id:%s, msg:%s, param1:%s, param2:%s, param3:%s, unk6:%s",
            msgId, dialogue.decode_string(message), packet["Param 1"], packet["Param 2"], packet["Param 3"], unk6StringStrippedNulls)
            file.append("27msg.txt", formattedStr .. "\r\n")
        end]]--
    elseif(id == 0x00E and windower.ffxi.get_info().zone == Constants["NyzulZoneId"])then
        local packet = packets.parse('incoming', data)
        NyzulBuddy:HandleNpcUpdate(packet)
    end
end)

windower.register_event('prerender', function()
    if(os.clock() - NyzulBuddy["UI"]["UpdateTimer"] > NyzulBuddy["UI"]["UpdateInterval"])then
        local displayStr = "♥  Nyzul Buddy  ♥"
        displayStr = string.format("%s\nObjective: \\cs(75,253,116)[ %s ]", displayStr, NyzulBuddy["ObjectiveStr"])
        displayStr = string.format("%s\n\\cs(249,236,236)Floor: \\cs(75,253,116)[ %s ]" , displayStr, NyzulBuddy["FloorStr"])
        displayStr = string.format("%s\n\\cs(249,236,236)Last Time Message:  \\cs(75,253,116)[ %s ]", displayStr, NyzulBuddy["TimeStr"])
        if(windower.ffxi.get_info().zone == Constants["NyzulZoneId"])then
            local remainingTimeInRun = os.clock() - NyzulBuddy["RunStartTime"]
            remainingTimeInRun = Constants["TimeLimit"] - remainingTimeInRun
            if(remainingTimeInRun > 0 and remainingTimeInRun < 1800)then
                displayStr = string.format("%s\n\\cs(249,236,236)Time Remaining: \\cs(75,253,116)[ %s ]", displayStr, os.date("!%M:%S", remainingTimeInRun))
            end

            displayStr = string.format("%s\n\\cs(249,236,236)Runes: \\cs(75,253,116)[\n", displayStr)
            local player = windower.ffxi.get_mob_by_target("me")   
            for _,v in pairs(NyzulBuddy["Runes"]) do
                if(v and type(v) == 'table' and v["Mob"] and v["Mob"].name and player)then
                    local angle = AngleBetween(v["Mob"].x, v["Mob"].y)
                    local cardinal = GetCardinalForAngle(angle)
                    local distance = Distance({x = player.x, y = player.y, z = player.z}, {x=v["Mob"].x, y=v["Mob"].y, z=v["Mob"].z})
                    displayStr = string.format("%s\n    \\cs(249,236,236)Rune: \\cs(75,253,116)[ %s [Idx: %s Distance: %.3f Activated: %s Dir: %s] ]", displayStr, v["Mob"]["name"], v["Mob"]["index"], distance, tostring(v["Activated"]), cardinal)
                end
            end
            displayStr = string.format("%s\n]", displayStr)

            displayStr = string.format("%s\n\\cs(249,236,236)Lamps: \\cs(75,253,116)[\n", displayStr)
            for _,v in pairs(NyzulBuddy["Lamps"]) do
                if(v and type(v) == 'table' and v["Mob"] and v["Mob"].name and player)then
                    local angle = AngleBetween(v["Mob"].x, v["Mob"].y)
                    local cardinal = GetCardinalForAngle(angle)
                    local distance = Distance({x = player.x, y = player.y, z = player.z}, {x=v["Mob"].x, y=v["Mob"].y, z=v["Mob"].z})
                    displayStr = string.format("%s\n    \\cs(249,236,236)Lamp: \\cs(75,253,116)[ %s [Idx: %s Distance: %02.01f Activated: %s Dir: %s] ]", displayStr, v["Mob"]["name"], v["Mob"]["index"], distance, tostring(v["Activated"]), cardinal)
                end
            end
            displayStr = string.format("%s\n]", displayStr)
        end
        NyzulBuddy["UI"]["TextBox"]:visible(true)
        NyzulBuddy["UI"]["TextBox"]:text(displayStr)
        NyzulBuddy["UI"]["UpdateTimer"] = os.clock()
    end
end)