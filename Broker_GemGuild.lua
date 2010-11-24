local tablet = AceLibrary("Tablet-2.0")
local frame = CreateFrame("frame")

local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject("GemGuild", {
	type = "data source",
	icon = "Interface\\AddOns\\Broker_GemGuild\\icon"
})


-----------------------
--  Helper Routines  --
-----------------------

local function inGroup(name)
	if GetNumRaidMembers() > 0 and UnitInRaid(name) or GetNumPartyMembers() > 0 and UnitInParty(name) or nil then return true end
end

local function player_name_to_index(name)
	local lookupname
	for i = 1,GetNumFriends() do
		lookupname,_ = GetFriendInfo(i)
		if lookupname == name then return i end
	end
end

local function guild_name_to_index(name)
	local lookupname
	for i=1,GetNumGuildMembers() do
		lookupname,_ = GetGuildRosterInfo(i)
		if lookupname == name then return i end
	end
end

local function levelcolor(level)
	local color = GetQuestDifficultyColor(level)
	return string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255)
end

local colors = {}
for class,color in pairs(RAID_CLASS_COLORS) do colors[class] = string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) end


---------------------
--  Update button  --
---------------------

local function update_Broker()
	ShowFriends()

	local online = 0
	local guildies

	if IsInGuild() then
		online = 0
		GuildRoster()
		for i=1,GetNumGuildMembers() do if select(9, GetGuildRosterInfo(i)) then online = online +1 end end
		guildies=string.format("%d/%d", online, GetNumGuildMembers(true))
	else guildies = "" end

	dataobj.text = guildies
end



----------------------------
--  If names are clicked  --
----------------------------

local function click(name, type)
	if IsAltKeyDown() then
		InviteUnit(name)
	else
		SetItemRef("player:"..name, "|Hplayer:"..name.."|h["..name.."|h", "LeftButton")
	end
end


------------------------
--      Tooltip!      --
------------------------

function dataobj:updateTooltip()

	--------------
	--  Header  --
	--------------

	tablet:SetHint("|cffeda55fClick|r to open the guild panel. |cffeda55fClick|r a line to whisper a player. |cffeda55fAlt-Click|r a line to invite to a group.")

	tablet:SetTitle("GemGuild")

	------------------------
	--  Begin guild list  --
	------------------------

	if IsInGuild() then
		cat=tablet:AddCategory('id', 'guild', 'columns', 5, 'text', "")
		cat:AddLine(
			'text', "NAME",
			'text2', "LEVEL",
			'text3', "ZONE"
		)

		for i=1,GetNumGuildMembers() do
			local name, rank, rankIndex, level, _, area, note, onote, connected, status, class = GetGuildRosterInfo(i)

			if connected then
				cat:AddLine(
					'func', click,
					'arg1', name,
					'arg2', "guild",
					'hasCheck',
					true,
					'checked',
					inGroup(name),
					'checkIcon',"Interface\Buttons\UI-CheckBox-Check",
					'text', status..string.format("|cff%s%s", colors[class] or "ffffff", name),
					'text2',"|cff"..levelcolor(level)..level.."|r",
					'text3', area or "???"
				)
			end
		end
	else
		cat:AddLine('text', "You are not in a guild")
	end
end


----------------------
--  Attach tooltip  --
----------------------

local function registertip(tip)
	if not tablet:IsRegistered(tip) then
		tablet:Register(tip,
			'children', function() dataobj:updateTooltip() end,
			'clickable', true,
			'point', function(frame)
					if frame:GetTop() > GetScreenHeight() / 2 then
						local x = frame:GetCenter()
						if x < GetScreenWidth() / 3 then
	                                                return "TOPLEFT", "BOTTOMLEFT"
                                        	elseif x < GetScreenWidth() * 2 / 3 then
	                                                return "TOP", "BOTTOM"
                                        	else
	                                                return "TOPRIGHT", "BOTTOMRIGHT"
                                        	end
                                	else
	                                        local x = frame:GetCenter()
                                        	if x < GetScreenWidth() / 3 then
	                                                return "BOTTOMLEFT", "TOPLEFT"
                                        	elseif x < GetScreenWidth() * 2 / 3 then
	                                                return "BOTTOM", "TOP"
                                        	else
	                                                return "BOTTOMRIGHT", "TOPRIGHT"
                                        	end
                                	end
				end,
			'dontHook', true
		)
	end
end


------------------------------------------
--  Click to open guild panel  --
------------------------------------------

function dataobj.OnClick()
		ToggleFriendsFrame(3) -- guild
end



---------------------
--  Event Section  --
---------------------

function dataobj.OnLeave() end
function dataobj.OnEnter(self)
	registertip(self)
	tablet:Open(self)
end

frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local DELAY = 15  --  Update every 15 seconds
local elapsed = DELAY-5

frame:SetScript("OnUpdate",
	function (self, el)
		elapsed = elapsed + el
		if elapsed >= DELAY then
			elapsed = 0
			update_Broker()
		end
	end
)
