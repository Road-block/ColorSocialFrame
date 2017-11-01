local _G = getfenv(0)
local addon=CreateFrame("Frame")
addon.OnEvent = function()
  return this[event]~=nil and this[event](this,event,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11)
end
addon:SetScript("OnEvent",addon.OnEvent)
addon:RegisterEvent("VARIABLES_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("ADDON_LOADED")
local playerName = UnitName("player")
local realmName, playerRank
local strfind,strformat,gsub,gfind,tonumber,GetDifficultyColor,GetRealZoneText,UnitLevel,GetGuildInfo = 
string.find,string.format,string.gsub,string.gfind,tonumber,GetDifficultyColor,GetRealZoneText,UnitLevel,GetGuildInfo

local classToCLASS = {
  enUS = {
    Warlock = "WARLOCK",
    Warrior = "WARRIOR",
    Hunter = "HUNTER",
    Mage = "MAGE",
    Priest = "PRIEST",
    Druid = "DRUID",
    Paladin = "PALADIN",
    Shaman = "SHAMAN",
    Rogue = "ROGUE"
  },
  deDE = {
    ["Hexenmeister"] = "WARLOCK",
    ["Krieger"] = "WARRIOR",
    ["Jäger"] = "HUNTER",
    ["Magier"] = "MAGE",
    ["Priester"] = "PRIEST",
    ["Druide"] = "DRUID",
    ["Paladin"] = "PALADIN",
    ["Schamane"] = "SHAMAN",
    ["Schurke"] = "ROGUE"
  },
  zhCN = {
    ["术士"] = "WARLOCK",
    ["战士"] = "WARRIOR",
    ["猎人"] = "HUNTER",
    ["法师"] = "MAGE",
    ["牧师"] = "PRIEST",
    ["德鲁伊"] = "DRUID",
    ["圣骑士"] = "PALADIN",
    ["萨满祭司"] = "SHAMAN",
    ["盗贼"] = "ROGUE"
  },
  zhTW = {
    ["術士"] = "WARLOCK",
    ["戰士"] = "WARRIOR",
    ["獵人"] = "HUNTER",
    ["法師"] = "MAGE",
    ["牧師"] = "PRIEST",
    ["德魯伊"] = "DRUID",
    ["聖騎士"] = "PALADIN",
    ["薩滿"] = "SHAMAN",
    ["盜賊"] = "ROGUE"
  },
  koKR = {
    ["흑마법사"] = "WARLOCK",
    ["전사"] = "WARRIOR",
    ["사냥꾼"] = "HUNTER",
    ["마법사"] = "MAGE",
    ["사제"] = "PRIEST",
    ["드루이드"] = "DRUID",
    ["성기사"] = "PALADIN",
    ["주술사"] = "SHAMAN",
    ["도적"] = "ROGUE"
  },
  ruRU = {
    ["Чернокнижник"] = "WARLOCK",
    ["Воин"] = "WARRIOR",
    ["Охотник"] = "HUNTER",
    ["Маг"] = "MAGE",
    ["Жрец"] = "PRIEST",
    ["Друид"] = "DRUID",
    ["Паладин"] = "PALADIN",
    ["Шаман"] = "SHAMAN",
    ["Разбойник"] = "ROGUE"
  },
}

function addon:strtrim(txt)
  return (string.gsub(txt,"^%s*(.-)%s*$", "%1"))
end

addon.hexColorCache = {}
function addon:RGBtoHEX(colortab,r,g,b)
  if (colortab) then
    local r,g,b
    if colortab.r then
      r,g,b = colortab.r, colortab.g, colortab.b
    elseif table.getn(colortab) == 3 then
      r,g,b = colortab[1],colortab[2],colortab[3]
    end
    if r and g and b then
      local colorKey = string.format("%s%s%s",r,g,b)
      if self.hexColorCache[colorKey] == nil then
        self.hexColorCache[colorKey] = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
      end
      return self.hexColorCache[colorKey]
    end
  elseif r and g and b then
    local colorKey = string.format("%s%s%s",r,g,b)
    if self.hexColorCache[colorKey] == nil then
      self.hexColorCache[colorKey] = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
    end
    return self.hexColorCache[colorKey]
  end
  return ""
end

local CUSTOM_CLASS_COLORS = {}
do
  for class,colorTab in pairs(RAID_CLASS_COLORS) do
    CUSTOM_CLASS_COLORS[class] = colorTab
    CUSTOM_CLASS_COLORS[class].hex = addon:RGBtoHEX(colorTab)
  end
  CUSTOM_CLASS_COLORS["UNKNOWN"] = {r = 0.6, g = 0.6, b = 0.6, hex = "|cff999999"}
end

addon.classColorCache = {}
function addon:localeClassColor()
  for class,g_class in pairs(classToCLASS[self.locale]) do
    self.classColorCache[class] = string.format("%s%s|r",CUSTOM_CLASS_COLORS[g_class].hex,class)
  end
  self.classColorCache[UNKNOWN] = string.format("%s%s|r",CUSTOM_CLASS_COLORS["UNKNOWN"].hex,UNKNOWN)
end

function addon:VARIABLES_LOADED()
  if UnitIsConnected("player") then
    self:UnregisterEvent("PLAYER_LOGIN")
    self:PLAYER_LOGIN("PLAYER_LOGIN")
  end
end

function addon:PLAYER_LOGIN()
  realmName = self:strtrim(GetCVar("realmName"))
  local profileKey = string.format("%s - %s",playerName,realmName)
  ColorSocialFrameDB = ColorSocialFrameDB or {[profileKey]={Friends={}}}
  if not ColorSocialFrameDB[profileKey] then
    ColorSocialFrameDB[profileKey]={Friends={}}
  end
  self.db_profile = ColorSocialFrameDB[profileKey]
  self.db = ColorSocialFrameDB
  self.locale = GetLocale()
  self:localeClassColor()
  self.Hooks = {}
  self.Hooks.GuildStatus_Update = GuildStatus_Update
  GuildStatus_Update = self.GuildStatus_Update
  self.Hooks.WhoList_Update = WhoList_Update
  WhoList_Update = self.WhoList_Update
  self.Hooks.FriendsList_Update = FriendsList_Update
  FriendsList_Update = self.FriendsList_Update
  -- self.Hooks.IgnoreList_Update = IgnoreList_Update
  -- IgnoreList_Update = self.IgnoreList_Update
end

function addon:ADDON_LOADED()
  -- if we need to catch some Load on Demand addons
end

addon.classCache = {}
addon.rankCache = {}
function addon:GuildStatus_Update()
  addon.Hooks.GuildStatus_Update()
  
  for i=1,GetNumGuildMembers(1) do
    local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i)
    if name == playerName then
      playerRank = rankIndex
    end
    if (rank) and not addon.rankCache[rank] then
      addon.rankCache[rank]=rankIndex
    end
    local g_class = classToCLASS[addon.locale][class]
    if addon.classCache[name]==nil then
      addon.classCache[name] = string.format("%s%s|r",CUSTOM_CLASS_COLORS[g_class].hex,name)
    end
  end
  for i=1, GUILDMEMBERS_TO_DISPLAY, 1 do
    if (FriendsFrame.playerStatusFrame) then
      local button = _G["GuildFrameButton"..i]
      local buttonName = _G["GuildFrameButton"..i.."Name"]
      local buttonZone = _G["GuildFrameButton"..i.."Zone"]
      local buttonLevel = _G["GuildFrameButton"..i.."Level"]
      local buttonClass = _G["GuildFrameButton"..i.."Class"]
      local name = buttonName:GetText()
      if not (name) then break end
      local _,_,zone_b = buttonZone:GetTextColor()
      local offline = tonumber(zone_b)<0.6
      local colorized = strfind(name,"|cff")
      local class = buttonClass:GetText()
      local level = tonumber(buttonLevel:GetText())
      local levelColor = level and addon:RGBtoHEX(GetDifficultyColor(level)) or "|cffffffff"
      local zone = addon:strtrim(buttonZone:GetText() or "")
      local my_zone = GetRealZoneText() or ""
      local zoneColor = zone ~= "" and (zone == my_zone) and "|cff9aff9a" or "|cffffffff"
      if not (colorized) then
        buttonName:SetText(addon.classCache[name])
        buttonClass:SetText(addon.classColorCache[class])
        buttonLevel:SetText(strformat("%s%s|r",levelColor,level or 0))
        buttonZone:SetText(strformat("%s%s|r",zoneColor,zone))
        if (offline) then
          buttonName:SetVertexColor(1,1,1,0.5)
          buttonClass:SetVertexColor(1,1,1,0.5)
          buttonLevel:SetVertexColor(1,1,1,0.5)
          buttonZone:SetVertexColor(1,1,1,0.5)
        else
          buttonName:SetVertexColor(1,1,1,1)
          buttonClass:SetVertexColor(1,1,1,1)
          buttonLevel:SetVertexColor(1,1,1,1)
          buttonZone:SetVertexColor(1,1,1,1) 
        end
      end
    else
      local button = _G["GuildFrameGuildStatusButton"..i]
      local buttonName = _G["GuildFrameGuildStatusButton"..i.."Name"]
      local buttonRank = _G["GuildFrameGuildStatusButton"..i.."Rank"]
      local buttonNote = _G["GuildFrameGuildStatusButton"..i.."Note"]
      local buttonOnline = _G["GuildFrameGuildStatusButton"..i.."Online"]
      local name = buttonName:GetText()
      if not (name) then break end
      local colorized = strfind(name,"|cff")
      local online = buttonOnline:GetText()
      local rank = addon:strtrim(buttonRank:GetText() or "")
      local rank_index = addon.rankCache[rank]
      local rank_color = "|cffffffff"
      if (rank_index) and playerRank then
        local rank_diff = playerRank - rank_index
        local rank_level = UnitLevel("player") + rank_diff
        rank_color = addon:RGBtoHEX(GetDifficultyColor(rank_level))
      end
      if not (colorized) then
        buttonName:SetText(addon.classCache[name])
        buttonRank:SetText(strformat("%s%s|r",rank_color,rank))
        if (online == GUILD_ONLINE_LABEL or online == CHAT_FLAG_AFK or online == CHAT_FLAG_DND) then
          buttonName:SetVertexColor(1,1,1,1)
          buttonRank:SetVertexColor(1,1,1,1)
        else
          buttonName:SetVertexColor(1,1,1,0.5)
          buttonRank:SetVertexColor(1,1,1,0.5)
        end
      end      
    end
  end
end

addon.columnTable = {"zone","guild","race" }
function addon:WhoList_Update()
  addon.Hooks.WhoList_Update()
  for i=1,GetNumWhoResults() do
    local name, guild, level, race, class, zone = GetWhoInfo(i)
    local g_class = classToCLASS[addon.locale][class]
    if addon.classCache[name]==nil then
      addon.classCache[name] = string.format("%s%s|r",CUSTOM_CLASS_COLORS[g_class].hex,name)
    end    
  end
  for i=1, WHOS_TO_DISPLAY, 1 do
    local button = _G["WhoFrameButton"..i]
    local buttonName = _G["WhoFrameButton"..i.."Name"]
    if not button._nameColor then
      button._nameColor = button:CreateFontString("WhoFrameButton"..i.."NameColor","BORDER","GameFontNormalSmall")
      button._nameColor:SetAllPoints(buttonName)
      buttonName:Hide()
    end
    button._nameColor:SetText(buttonName:GetText())
    local buttonLevel = _G["WhoFrameButton"..i.."Level"]
    local buttonClass = _G["WhoFrameButton"..i.."Class"]
    local buttonVariable = _G["WhoFrameButton"..i.."Variable"]
    local selectedVar = addon.columnTable[UIDropDownMenu_GetSelectedID(WhoFrameDropDown)]
    local name = button._nameColor:GetText()
    if not (name) then break end
    local colorized = strfind(name,"|cff")
    local class = buttonClass:GetText()
    local level = tonumber(buttonLevel:GetText())
    local levelColor = level and addon:RGBtoHEX(GetDifficultyColor(level)) or "|cffffffff"
    local variable = buttonVariable:GetText()
    local zone, zoneColor, guild, guildColor
    if not (colorized) then
      button._nameColor:SetText(addon.classCache[name])
      buttonLevel:SetText(strformat("%s%s|r",levelColor,level or 0)) 
      buttonClass:SetText(addon.classColorCache[class])
      if selectedVar == "zone" then
        local my_zone = GetRealZoneText() or ""
        zone = addon:strtrim(variable or "")
        zoneColor = zone ~= "" and (zone == my_zone) and "|cff9aff9a" or "|cffffffff"
        buttonVariable:SetText(strformat("%s%s|r",zoneColor,zone))
      elseif selectedVar == "guild" then
        local my_guild = IsInGuild() and (GetGuildInfo("player")) or ""
        guild = addon:strtrim(variable or "")
        guildColor = guild ~= '' and (guild == my_guild) and "|cff9aff9a" or "|cffffffff"
        buttonVariable:SetText(strformat("%s%s|r",guildColor,guild))
      else
        buttonVariable:SetText(variable)
      end      
    end
  end  
end

addon.friendPatterns = {
  -- captures
  NAMELOC = gsub(gsub(gsub(FRIENDS_LIST_TEMPLATE,"([%(%)%.%+%-%*%?%[%]%^%$])","%%%1"),"%%s","(.-)"),"%%d","(%d+)"),
  NAMELOC_OFFLINE = gsub(gsub(gsub(FRIENDS_LIST_OFFLINE_TEMPLATE,"([%(%)%.%+%-%*%?%[%]%^%$])","%%%1"),"%%s","(.-)"),"%%d","(%d+)"),
  INFO = gsub(gsub(gsub(FRIENDS_LEVEL_TEMPLATE,"([%(%)%.%+%-%*%?%[%]%^%$])","%%%1"),"%%s","(.-)"),"%%d","(%d+)"),
  -- formats
  NAMELOC_PLAIN = gsub(gsub(FRIENDS_LIST_TEMPLATE,"|cffffffff",""),"|r",""),
  NAMELOC_OFFLINE_PLAIN = gsub(gsub(FRIENDS_LIST_OFFLINE_TEMPLATE,"|cff999999",""),"|r",""),
  INFO_PLAIN = gsub(gsub(FRIENDS_LEVEL_TEMPLATE,"%%s","%%s %%s"),"%%d","%%s")
}
function addon:FriendsList_Update()
  addon.Hooks.FriendsList_Update()
  for i=1,GetNumFriends() do
    local name, level, class, area, connected, status = GetFriendInfo(i)
    if (connected) then
      if name ~= UNKNOWN and class ~= UNKNOWN then
        local timestamp = date("%a %d-%b-%Y")
        addon.db_profile.Friends[name] = {level=level,class=class,area=area,time=timestamp}        
        if addon.classCache[name] == nil then
          local g_class = classToCLASS[addon.locale][class]
          addon.classCache[name] = string.format("%s%s|r",CUSTOM_CLASS_COLORS[g_class].hex,name)
        end
      end
    end    
  end
  for i=1, FRIENDS_TO_DISPLAY, 1 do
    local button = _G["FriendsFrameFriendButton"..i]
    local buttonNameLoc = _G["FriendsFrameFriendButton"..i.."ButtonTextNameLocation"]
    local buttonInfo = _G["FriendsFrameFriendButton"..i.."ButtonTextInfo"]
    local nameloc = buttonNameLoc:GetText()
    local info = buttonInfo:GetText()
    local offline = info == UNKNOWN
    local name,area,status,colorized
    for name in gfind(nameloc,addon.friendPatterns.NAMELOC_OFFLINE) do
      if (name) then
        colorized = strfind(name,"|cff")
        if not (colorized) then
          local cached = addon.db_profile.Friends[name]
          if (cached) then
            local level,class,timestamp = cached.level, cached.class, cached.time
            local g_class = classToCLASS[addon.locale][class]
            if addon.classCache[name]==nil then
              addon.classCache[name] = string.format("%s%s|r",CUSTOM_CLASS_COLORS[g_class].hex,name)
            end
            local levelColor = level and addon:RGBtoHEX(GetDifficultyColor(level)) or "|cffffffff"         
            buttonNameLoc:SetText(strformat(addon.friendPatterns.NAMELOC_OFFLINE_PLAIN,addon.classCache[name]))
            local level_c = strformat("%s%s|r",levelColor,level)
            local class_c = addon.classColorCache[class]
            buttonInfo:SetText(strformat(addon.friendPatterns.INFO_PLAIN,level_c,class_c,timestamp))
          end
        end
      end
    end 
    for name,area,status in gfind(nameloc,addon.friendPatterns.NAMELOC) do
      if (name) then
        colorized = strfind(name,"|cff")
        if not (colorized) then
          local cached = addon.db_profile.Friends[name]
          if (cached) then
            local level,class,timestamp = cached.level, cached.class, cached.time
            local g_class = classToCLASS[addon.locale][class]
            if addon.classCache[name]==nil then
              addon.classCache[name] = string.format("%s%s|r",CUSTOM_CLASS_COLORS[g_class].hex,name)
            end
            local levelColor = level and addon:RGBtoHEX(GetDifficultyColor(level)) or "|cffffffff"
            local areaColor
            if (area) and area ~= "" then
              local my_zone = GetRealZoneText() or ""
              areaColor = area ~= "" and (area == my_zone) and "|cff9aff9a" or "|cffffffff"         
            end
            buttonNameLoc:SetText(strformat(addon.friendPatterns.NAMELOC_PLAIN,addon.classCache[name],strformat("%s%s|r",areaColor,area),status))
            local level_c = strformat("%s%s|r",levelColor,level)
            local class_c = addon.classColorCache[class]
            buttonInfo:SetText(strformat(addon.friendPatterns.INFO_PLAIN,level_c,class_c,""))
          end          
        end
      end
    end
    if (offline) then
      buttonNameLoc:SetVertexColor(1,1,1,0.5)
      buttonInfo:SetVertexColor(1,1,1,0.5)      
    else
      buttonNameLoc:SetVertexColor(1,1,1,1)
      buttonInfo:SetVertexColor(1,1,1,1)      
    end
  end  
end

function addon:IgnoreList_Update()
  addon.Hooks.IgnoreList_Update()
end