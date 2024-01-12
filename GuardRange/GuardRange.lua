local Version = 1.5

GuardRange = {}

local SEND_BEGIN = 1
local SEND_FINISH = 2
GuardRange.ShieldIcons = {[1]=4515,[5]=2558,[10]=8078,[13]=5172,[17]=13373,[21]=11018}
GuardRange.StateTimer = 0.1
local L_Labels = {["true"]=L"true",["false"]=L"false"}


--[[
GuardRange.DefaultColor = {r=255,g=255,b=255}
GuardRange.CloseColor = {r=50,g=255,b=50}
GuardRange.MidColor = {r=100,g=100,b=255}
GuardRange.FarColor = {r=255,g=50,b=50}
GuardRange.Distant = {r=125,g=125,b=125}
--]]

function GuardRange.Initialize()
if tostring(GameData.Account.ServerName) ~= "\77\97\114\116\121\114\115\32\83\113\117\97\114\101" then return end
CreateWindow("GuardRange_Window0", true)

LayoutEditor.RegisterWindow( "GuardRange_Window0", L"Guard List", L"Guard List", true, true, false)
CircleImageSetTexture("GuardRange_Window0ShieldIcon","GuardIcon", 32, 32)

LabelSetText("GuardRange_Window0Label",L"--")
LabelSetText("GuardRange_Window0LabelBG",L"--")
GuardRange.stateMachineName = "GuardRange"
GuardRange.state = {[SEND_BEGIN] = { handler=nil,time=GuardRange.StateTimer,nextState=SEND_FINISH } , [SEND_FINISH] = { handler=GuardRange.UpdateStateMachine,time=GuardRange.StateTimer,nextState=SEND_BEGIN, } , }
GuardRange.StartMachine()
AnimatedImageStartAnimation ("GuardRange_Window0Glow", 0, true, true, 0)	

	if GuardRange.Settings == nil or (GuardRange.Settings.version < Version) then GuardRange.ResetSettings() end

	if teather.Settings.Colors and GuardRange.Settings.UseTeatherColors == true then
		GuardRange.DefaultColor = teather.Settings.Colors.Default
		GuardRange.CloseColor = teather.Settings.Colors.Close
		GuardRange.MidColor = teather.Settings.Colors.Mid
		GuardRange.FarColor = teather.Settings.Colors.Far
		GuardRange.Distant = teather.Settings.Colors.Distant
		GuardRange.Dead = teather.Settings.Colors.Dead
	else
		GuardRange.DefaultColor = GuardRange.Settings.Colors.Default
		GuardRange.CloseColor = GuardRange.Settings.Colors.Close
		GuardRange.MidColor = GuardRange.Settings.Colors.Mid
		GuardRange.FarColor = GuardRange.Settings.Colors.Far
		GuardRange.Distant = GuardRange.Settings.Colors.Distant
		GuardRange.Dead = GuardRange.Settings.Colors.Dead
	end


	for i=1,5 do
		CreateWindowFromTemplate("GuardRange_Window"..i, "GuardRange_Window0", "Root")
		WindowClearAnchors("GuardRange_Window"..i)
		WindowAddAnchor( "GuardRange_Window"..i , "bottom", "GuardRange_Window"..(i-1), "top", 0,7)	
		WindowSetMovable( "GuardRange_Window"..i, false )			
	end

	if LibGuard then 
		LibGuard.Register_Callback(GuardRange.LG_Update)
	end

	if LibSlash then
		LibSlash.RegisterSlashCmd("guardrange", function(input) GuardRange.Command(input) end)
	end
end

function GuardRange.StartMachine()
	local stateMachine = TimedStateMachine.New( GuardRange.state,SEND_BEGIN)
	TimedStateMachineManager.AddStateMachine( GuardRange.stateMachineName, stateMachine )
end

function GuardRange.ComparePlayers( index,tablename )
    table.sort(index, function (a,b)
    return (a.distance < b.distance)
	end)

end

function GuardRange.SortPlayers(array)
	if array == nil then return end
	
	local Index = 0
	local sortedPlayers = {};	
	for k, v in pairs(array)
	do		
		if v.distance ~= nil then
			table.insert(sortedPlayers,v);
			Index = Index+1
		end
	end	
	if Index > 1 then
		table.sort(sortedPlayers, function(a,b) return a.distance < b.distance end);
	end
	return sortedPlayers;	
end


function GuardRange.UpdateStateMachine()

	if  LibGuard.registeredGuards then
		Guard_DisplayOrder = {}
		local IndexCount = 0
			for k, v in pairs (LibGuard.registeredGuards) do
				IndexCount = IndexCount+1
				if LibGuard.registeredGuards[k].Info ~= nil and type(LibGuard.registeredGuards[k].Info) ~= "number" and LibGuard.registeredGuards[k].Info.isDistant == true then
					LibGuard.registeredGuards[k].distance = 90000 + IndexCount
				end					
			end
		GuardListdata = GuardRange.SortPlayers(LibGuard.registeredGuards)			
	end


for i=1,5 do
WindowSetShowing("GuardRange_Window"..i,false)
WindowSetScale("GuardRange_Window"..i,(WindowGetScale("GuardRange_Window0")*0.8))
end
	if  GuardListdata then

		local function Offset(state)
		if state then
			return 40
			else
			return 3
			end
		end			
		
		WindowClearAnchors("GuardRange_Window1")
		WindowAddAnchor( "GuardRange_Window1" , "top", "GuardRange_Window0", "top", 0,Offset(WindowGetShowing("GuardRange_Window0")))	
	
		local Index = 0
		for k, v in ipairs( GuardListdata ) do
			if ((LibGuard.GuarderData.XGuard == true) and (LibGuard.GuarderData.Name == GuardListdata[k].Name)) == false then
				Index = Index + 1
				WindowSetShowing("GuardRange_Window"..Index,true)
				local GuardName = L""
				if GuardRange.Settings.ShowGuardedName == true then GuardName = towstring(GuardListdata[k].Name) end
				
				if (GuardListdata[k].Info ~= nil and type(GuardListdata[k].Info) ~= "number" and GuardListdata[k].Info.isDistant ~= nil) and (GuardListdata[k].Info.isDistant == false) then
					local color = GuardRange.DefaultColor
					local Distance = GuardListdata[k].distance
					local Distance_Label = towstring(Distance)				


						local function toggleText(state)
							if not state then
								return L" ft"
							else
								return L""
							end
						end			

						local IsDistant = true
						if GuardListdata[k].Info ~= nil then
						IsDistant = GuardListdata[k].Info.isDistant
						end
					
					if Distance < 0 then
					color = GuardRange.DefaultColor
					elseif Distance <= 30 and Distance >= 0 then
						color = GuardRange.CloseColor
					elseif Distance > 30 and Distance <= 50 then
						color = GuardRange.MidColor
					elseif Distance > 50 then
						color = GuardRange.FarColor
					else
						Distance_Label = L" Distant"
						color = GuardRange.Distant
					end
				
					LabelSetText("GuardRange_Window"..Index.."Label",GuardName..L" "..towstring(CreateHyperLink(L"Distance",Distance_Label, {color.r, color.g, color.b},{}))..toggleText(IsDistant))
					LabelSetText("GuardRange_Window"..Index.."LabelBG",LabelGetText("GuardRange_Window"..Index.."Label"))				
					
					WindowSetTintColor("GuardRange_Window"..Index.."Shield", color.r, color.g, color.b )
					WindowSetTintColor("GuardRange_Window"..Index.."ShieldIcon",255, 255, 255 )				
					
				else
					LabelSetText("GuardRange_Window"..Index.."Label",GuardName..towstring(CreateHyperLink(L"Distance",L" Distant", {GuardRange.Distant.r, GuardRange.Distant.g, GuardRange.Distant.b},{})))
					LabelSetText("GuardRange_Window"..Index.."LabelBG",LabelGetText("GuardRange_Window"..Index.."Label"))
					
					WindowSetTintColor("GuardRange_Window"..Index.."Shield", GuardRange.Distant.r, GuardRange.Distant.g, GuardRange.Distant.b )
					WindowSetTintColor("GuardRange_Window"..Index.."ShieldIcon",155, 155, 155 )				
				end
				local Guard_Icon = GuardRange.ShieldIcons[GuardListdata[k].Career] or 0
				--local Guard_Icon = GetIconData( Icons.GetCareerIconIDFromCareerLine(GuardListdata[k].career ) )
				if GuardRange.Settings.ShowGuardedIcon == true then
					local texture, x, y, disabledTexture = GetIconData(tonumber(Guard_Icon))
					CircleImageSetTexture("GuardRange_Window"..Index.."ShieldIcon",texture, 32, 32)	
								
					WindowSetShowing("GuardRange_Window"..Index.."Shield",true)
				else
					WindowSetShowing("GuardRange_Window"..Index.."Shield",false)
				end
				
				local Fontwidth,FontHeight = LabelGetTextDimensions("GuardRange_Window"..Index.."Label")
				WindowSetDimensions("GuardRange_Window"..Index, Fontwidth, FontHeight)
				
			end

		end

	end	
	
	if LibGuard.GuarderData.IsGuarding then
	
				local color = GuardRange.DefaultColor
				local Distance = LibGuard.GuarderData.distance
				
			if (LibGuard.GuarderData.Info ~= nil and type(LibGuard.GuarderData.Info) ~= "number" and LibGuard.GuarderData.Info.isDistant ~= nil) and (LibGuard.GuarderData.Info.isDistant == false) then	

				if Distance < 0 then
					color = GuardRange.DefaultColor
					CircleImageSetTexture("GuardRange_Window0ShieldIcon","PetIcon", 32, 32)
				elseif Distance <= 30 and Distance >= 0 then
					color = GuardRange.CloseColor
					CircleImageSetTexture("GuardRange_Window0ShieldIcon","GuardIcon", 32, 32)
				elseif Distance > 30 and Distance <= 50 then
					color = GuardRange.MidColor
					CircleImageSetTexture("GuardRange_Window0ShieldIcon","BreakIcon", 32, 32)
				elseif Distance > 50 then
					color = GuardRange.FarColor
					CircleImageSetTexture("GuardRange_Window0ShieldIcon","BreakIcon", 32, 32)
				else
					color = GuardRange.DefaultColor
					CircleImageSetTexture("GuardRange_Window0ShieldIcon","DistantIcon", 32, 32)
				end
			else
				Distance = L"Distant "
				CircleImageSetTexture("GuardRange_Window0ShieldIcon","DistantIcon", 32, 32)
				color = GuardRange.Distant
			end
			
						local function toggleText(state)
							if not state then
								return L" ft"
							else
								return L""
							end
						end			
			
				local IsDistant = true
				if LibGuard.GuarderData.Info ~= nil and LibGuard.GuarderData.Info ~= 0 then
				IsDistant = LibGuard.GuarderData.Info.isDistant
				end
				local Distance_Label = towstring(Distance)
				local GuardName = L""
				if GuardRange.Settings.ShowGuardingName == true then GuardName = towstring(LibGuard.GuarderData.Name) end
				WindowSetTintColor("GuardRange_Window0Shield", color.r, color.g, color.b )
				WindowSetTintColor("GuardRange_Window0ShieldIcon", color.r, color.g, color.b )				
		
				WindowSetShowing("GuardRange_Window0",true)
				WindowSetShowing("GuardRange_Window0Glow",(LibGuard.GuarderData.XGuard and GuardRange.Settings.ShowGuardingIcon) or false)
				WindowSetTintColor("GuardRange_Window0Glow", color.r, color.g, color.b )
				
				if LibGuard.UsePet == true then
					if LibGuard.FakeGuarding == true and (GameData.Player.Pet.healthPercent > 0) then
						LabelSetText("GuardRange_Window0Label",GuardName..L" "..towstring(CreateHyperLink(L"Distance",towstring(GameData.Player.Pet.healthPercent), {color.r, color.g, color.b},{}))..L"%")
						LabelSetText("GuardRange_Window0LabelBG",LabelGetText("GuardRange_Window0Label"))							
					else
						LabelSetText("GuardRange_Window0Label",GuardName..L" "..towstring(CreateHyperLink(L"Distance",Distance_Label, {color.r, color.g, color.b},{}))..toggleText(IsDistant))
						LabelSetText("GuardRange_Window0LabelBG",LabelGetText("GuardRange_Window0Label"))			
					end
				end
				WindowSetShowing("GuardRange_Window0Shield",GuardRange.Settings.ShowGuardingIcon)

	else
	WindowSetShowing("GuardRange_Window0",false)
	WindowSetShowing("GuardRange_Window0Glow",false)
	LabelSetText("GuardRange_Window0Label",L"--")
	LabelSetText("GuardRange_Window0LabelBG",L"--")
	end	

return		
end


function GuardRange.ResetSettings()

GuardRange.Settings = {
	version = Version,
	ShowGuardedName = true,
	ShowGuardingName = true,
	ShowGuardedIcon = true,
	ShowGuardingIcon = true,
	UseTeatherColors = true,
	Colors = {
		Default = {r=255,g=255,b=255},
		Close = {r=50,g=255,b=50},
		Mid = {r=100,g=100,b=255},
		Far = {r=255,g=50,b=50},
		Distant = {r=125,g=125,b=125},
		Dead = {r=175,g=175,b=175}
	}
}
end

function GuardRange.Command(input)
	local input1 = nil
	local input2 = nil
	
	input1 = string.sub(input,0,string.find(input," "))
	if string.find(input," ") ~= nil then
		input1 = string.sub(input,0,string.find(input," ")-1)
		input2 = string.sub(input,string.find(input," ")+1,-1)
	end


	if (input1 == "out") then
		if(input2 == "icon") then
			GuardRange.Settings.ShowGuardingIcon = not GuardRange.Settings.ShowGuardingIcon
		elseif(input2 == "name") then
			GuardRange.Settings.ShowGuardingName = not GuardRange.Settings.ShowGuardingName	
		else
			EA_ChatWindow.Print(L"GuardRange Outgoing Settings:\n     show icon: "..towstring(L_Labels[GuardRange.Settings.ShowGuardingIcon])..L"\n     show name: "..towstring(L_Labels[GuardRange.Settings.ShowGuardingName]))
			return
		end
	elseif (input1 == "in") then
		if(input2 == "icon") then
			GuardRange.Settings.ShowGuardedIcon = not GuardRange.Settings.ShowGuardedIcon
		elseif(input2 == "name") then
			GuardRange.Settings.ShowGuardedName = not GuardRange.Settings.ShowGuardedName	
		else
			EA_ChatWindow.Print(L"GuardRange Incomming Settings:\n     show icon: "..towstring(L_Labels[GuardRange.Settings.ShowGuardedIcon])..L"\n     show name: "..towstring(L_Labels[GuardRange.Settings.ShowGuardedName]))
			return
		end
	elseif (input1 == "color") then
		GuardRange.Settings.UseTeatherColors = not GuardRange.Settings.UseTeatherColors
	elseif (input1 == "reset") then
		GuardRange.ResetSettings()
	else
		EA_ChatWindow.Print(L"\n Options for GuardRange to toggle incomming/outgoing icon/name on or off:\n /guardrange <in/out> <icon/name>")
		EA_ChatWindow.Print(L"GuardRange Outgoing Settings:\n     show icon: "..(L_Labels[tostring(GuardRange.Settings.ShowGuardingIcon)])..L"\n     show name: "..(L_Labels[tostring(GuardRange.Settings.ShowGuardingName)]))
		EA_ChatWindow.Print(L"GuardRange Incomming Settings:\n     show icon: "..(L_Labels[tostring(GuardRange.Settings.ShowGuardedIcon)])..L"\n     show name: "..(L_Labels[tostring(GuardRange.Settings.ShowGuardedName)]))
	return
	end
	
end


function GuardRange.LG_Update(state,GuardedName,GuardedID)
GuardRange.UpdateStateMachine()
end
