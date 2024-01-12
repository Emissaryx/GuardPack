	if not teather then teather = {} end

local scroll_pixels_current = 0
local scroll_pixels_max = 62      -- width of the texture
local scroll_pixels_rate = 62     -- pixels per second


	local Version = 1.5
	local DriftTimer = 0
	local ProtectAngle = 0
	local UIScale = InterfaceCore.GetScale()
    local ResolutionScale = InterfaceCore.GetResolutionScale()	
	local GlobalScale = SystemData.Settings.Interface.globalUiScale	
	local ScreenWidthX,ScreenHeightY = GetScreenResolution()	
	local ObjecOffset = 1
	local G_Range_Out = "Close"
	local G_Range_In = "Close"
	local IsTeathered = 0.1
	local IsTeatheredOffGuard = 0.1	
	local NumberOfGuards = 0		
		
		
	local GUARDED_APPLY_ID = 1			--when another player add guard to you
	local GUARDED_REMOVE_ID = 2			--when another players guard removes from you
	local GUARDING_APPLY_ID = 3			--when you add guard to another player
	local GUARDING_REMOVE_ID = 4			--when your guard removes from another player
		

	local AlphaLine = {[true]=1.0,[false]=0.0}
	local GuardTexture = {[true]="XGuardLine",[false]="TeatherLine"}
	local GuardIcons = {["Close"]="GuardIcon",["Mid"]="BreakIcon",["Far"]="BreakIcon",["Distant"]="DistantIcon",["Dead"]="DeadIcon"}	
	local ProtectorIcons = {[1]="OF",[21]="DP"}
	
	local OutTexturePack = "Modern_"
	local InTexturePack = "Modern_"
	
-- Make utility functions local for performance
	local pairs = pairs
	local ipairs = ipairs
	local tonumber = tonumber
	local towstring = towstring
	local tostring = tostring
	local max = math.max
	local min = math.min
	local WindowGetScale = WindowGetScale
	local WindowGetShowing = WindowGetShowing
	local WindowSetAlpha = WindowSetAlpha
	local WindowSetShowing = WindowSetShowing
	local WindowSetTintColor = WindowSetTintColor
	local WindowSetScale = WindowSetScale

	local CreateWindowFromTemplate,WindowSetDimensions,WindowClearAnchors,WindowAddAnchor,
      WindowRegisterCoreEventHandler,WindowSetLayer,DestroyWindow,RegisterEventHandler,
      DynamicImageSetTextureDimensions,DynamicImageSetTexture,DynamicImageSetRotation,	  
      StatusBarSetMaximumValue,StatusBarSetCurrentValue,StatusBarSetForegroundTint,
      LabelSetText,LabelSetTextColor =
     _G["CreateWindowFromTemplate"],_G["WindowSetDimensions"],_G["WindowClearAnchors"],_G["WindowAddAnchor"],
     _G["WindowRegisterCoreEventHandler"],_G["WindowSetLayer"],_G["DestroyWindow"],_G["RegisterEventHandler"],
     _G["DynamicImageSetTextureDimensions"],_G["DynamicImageSetTexture"],_G["DynamicImageSetRotation"],	 
     _G["StatusBarSetMaximumValue"],_G["StatusBarSetCurrentValue"],_G["StatusBarSetForegroundTint"],
     _G["LabelSetText"],_G["LabelSetTextColor"] 
	
	
	
function teather.init()
	if tostring(GameData.Account.ServerName) ~= "\77\97\114\116\121\114\115\32\83\113\117\97\114\101" then return end
	if teather.Settings == nil or (teather.Settings.version < Version) then teather.ResetSettings() end

	OutTexturePack = teather.Settings.OutTexturePack
	InTexturePack = teather.Settings.InTexturePack
	
	CreateWindow("TeatherSelfWindow", true)
	WindowSetAlpha("TeatherSelfWindow",0)
	CreateWindow("TeatherTargetWindow", false)
	CreateWindow("TeatherOffGuardSelfWindow", false)
	CreateWindow("TeatherOffGuardTargetWindow", false)


	CreateWindow("TeatherScaleWindow", true)
	CreateWindow("TeatherLine", true)
	CreateWindow("TeatherOffGuardLine", true)


	LayoutEditor.RegisterWindow( "TeatherSelfWindow", L"Teather Window", L"Teather Window", false, false, false)
	LayoutEditor.RegisterEditCallback(teather.OnLayoutEditorFinished)

	local texture, x, y, disabledTexture = GetIconData(tonumber(80))
	CircleImageSetTexture( "TeatherOffGuardTargetWindowIcon", "GuardIcon", 32, 32 )
	CircleImageSetTexture( "TeatherOffGuardSelfWindowIcon", "GuardIcon", 32, 32 )	

	UIScale = (InterfaceCore.GetScale())*teather.Settings.Scale
    ResolutionScale = (InterfaceCore.GetResolutionScale())*teather.Settings.Scale
	GlobalScale = (SystemData.Settings.Interface.globalUiScale)*teather.Settings.Scale	
	ScreenWidthX,ScreenHeightY = GetScreenResolution()	
	ObjecOffset = 1
	teather.TargetID = 0
	teather.TargetName = L""
	teather.TargetInfo = {}
	teather.OffGuardID = 0
	teather.OffGuardName = L""
	teather.ClosestOffGuardID = 0
	teather.ClosestOffGuardName = L""
	
	WindowSetShowing("TeatherSelfWindow",true)
	WindowSetAlpha("TeatherSelfWindow",0)
	WindowSetShowing("TeatherTargetWindow",false)		
	WindowSetShowing("TeatherOffGuardTargetWindow",false) 
	WindowSetShowing("TeatherOffGuardSelfWindow",false) 
	
	if LibGuard then 
		LibGuard.Register_Callback(teather.Libguard_Toggle)		
	end
	if LibSlash then
		LibSlash.RegisterSlashCmd("teather", function(input) teather.Command(input) end)
		LibSlash.RegisterSlashCmd("fakeguard", function(input) teather.FakeGuard(input) end)		
	end
	
	AnimatedImageStartAnimation ("TeatherSelfWindowGlow", 0, true, true, 0)	
	AnimatedImageStartAnimation ("TeatherTargetWindowGlow", 0, true, true, 0)		
	
	WindowSetScale("TeatherSelfWindow",UIScale)
	WindowSetScale("TeatherTargetWindow",UIScale)	
	WindowSetScale("TeatherOffGuardSelfWindow",UIScale)
	WindowSetScale("TeatherOffGuardTargetWindow",UIScale)

  WindowClearAnchors ("TeatherScaleWindow")
  WindowAddAnchor ("TeatherScaleWindow", "topleft", "Root", "topleft", SystemData.screenResolution.x / 2, SystemData.screenResolution.y / 2)
end

function teather.OnLayoutEditorFinished( editorCode )
	if( editorCode == LayoutEditor.EDITING_END ) then
		--WindowSetShowing("TeatherSelfWindow",false)
		WindowSetAlpha("TeatherSelfWindow",0)
		WindowSetShowing("TeatherTargetWindow",false)		
		WindowSetShowing("TeatherOffGuardTargetWindow",false) 
		WindowSetShowing("TeatherOffGuardSelfWindow",false) 
	end
end

--Attach/deatach and Show/Hide the teather windows
function teather.GetIDs()
if LibGuard.FakeGuarding == true and LibGuard.UsePet == true then

	if (GameData.Player.Pet.healthPercent > 0) then

	teather.TargetID = GameData.Player.Pet.objNum
	--teather.TargetName = GameData.Player.Pet.name
	teather.TargetName = wstring.gsub(teather.FixString(GameData.Player.Pet.name),teather.FixString(GameData.Player.name)..L"'s","")
	IsTeathered = 0.1
	WindowSetShowing("TeatherTargetWindow",true) 
	--WindowSetShowing("TeatherSelfWindow",true) 
	WindowSetAlpha("TeatherSelfWindow",1)
	else
	teather.TargetID = TargetInfo:UnitEntityId("selffriendlytarget")
	teather.TargetName = L"FakeGuardOut"
	IsTeathered = 0.1
	WindowSetShowing("TeatherTargetWindow",true) 
	--WindowSetShowing("TeatherSelfWindow",true) 
	WindowSetAlpha("TeatherSelfWindow",1)
	end
return
end

	local PlayerName = teather.FixString(GameData.Player.name)
	teather.TargetID = TargetInfo:UnitEntityId("selffriendlytarget")
	teather.TargetName = teather.FixString(TargetInfo:UnitName("selffriendlytarget"))

	if teather.TargetName ~= L"" and not (teather.TargetName == PlayerName) then 
		IsTeathered = 0.1
		WindowSetShowing("TeatherTargetWindow",true) 
		--WindowSetShowing("TeatherSelfWindow",true) 
		WindowSetAlpha("TeatherSelfWindow",1)

	else
		IsTeathered = 0.1
		WindowSetShowing("TeatherTargetWindow",false) 
		--WindowSetShowing("TeatherSelfWindow",false)
		WindowSetAlpha("TeatherSelfWindow",1)
		teather.TargetID = 0	
	end	
end


function teather.update(timeElapsed)
	if teather.Settings.Scroll == true then
  -- Scroll the texture. Needs to be done before rotation/etc.
		scroll_pixels_current = scroll_pixels_current + scroll_pixels_rate * timeElapsed
		scroll_pixels_current = math.fmod (scroll_pixels_current, scroll_pixels_max)
	end	

	local IsTargetGuarded = LibGuard.GuarderData.Name == teather.TargetName
	local distance = -1
	local Range = -1

	OutTexturePack = teather.Settings.OutTexturePack
	
	if teather.TargetName ~= nil and teather.TargetName ~= L"" then
	local IsXguard = Check_XGuard()
		--Did i mentioned i hate math? because im just so terrible at it...
		--Only check for distance if in a party,warband or scenario
		if IsWarBandActive() or PartyUtils.IsPartyActive() or GameData.Player.isInScenario or GameData.Player.isInSiege then
			distance = LibGuard.GuarderData.distance
			Range  = LibGuard.GuarderData.Range
			teather.TargetID = LibGuard.GuarderData.ID
			teather.TargetInfo = LibGuard.GuarderData.Info
		end

			WindowClearAnchors( "TeatherTargetWindowCircle" )
			WindowAddAnchor( "TeatherTargetWindowCircle" , "center", "TeatherTargetWindow", "center", 0,teather.Settings.AnchorOffset)	
			WindowClearAnchors( "TeatherTargetWindowIcon" )
			WindowAddAnchor( "TeatherTargetWindowIcon" , "center", "TeatherTargetWindow", "center", 0,teather.Settings.AnchorOffset)	
					
			
			local IsDistant = true
			local IsDead = false
			if LibGuard.GuarderData.Info ~= nil then
				if LibGuard.GuarderData.Info ~= 0 then
					IsDistant = LibGuard.GuarderData.Info.isDistant
				end
				if LibGuard.GuarderData.Info.healthPercent <= 0 then
					IsDead = true
				end
				
			end
			local Color = teather.Settings.Colors.Default
			
			
			if IsDead == false then
				if IsDistant == true then 
					Color = teather.Settings.Colors.Distant
					G_Range_Out = "Distant"
				else
					if distance < 0 then
					Color = teather.Settings.Colors.Default
					G_Range_Out = "Close"
					elseif distance <= 30 and distance >= 0 then
						Color = teather.Settings.Colors.Close
						G_Range_Out = "Close"
					elseif distance > 30 and distance <= 50 then
						Color = teather.Settings.Colors.Mid
						G_Range_Out = "Mid"					
					elseif distance > 50 then
						Color = teather.Settings.Colors.Far
						G_Range_Out = "Far"
					else
						Color = teather.Settings.Colors.Distant
						G_Range_Out = "Distant"
					end
				end
			else
					Color = teather.Settings.Colors.Dead
					G_Range_Out = "Dead"
			end
		
		
			if distance > 0 and distance < 170 and not IsDistant then


--Range Circle
			local RangeSize = 1 + (Range/150)
			local RangeFade = 0.8 -(Range /250)
			WindowSetScale("TeatherSelfWindowRange",WindowGetScale("TeatherSelfWindowCircle")*RangeSize)
			WindowSetTintColor("TeatherSelfWindowRange",Color.r,Color.g,Color.b)
			WindowSetAlpha("TeatherSelfWindowRange",RangeFade)
			WindowSetShowing("TeatherSelfWindowRange",true)
			else
				WindowSetShowing("TeatherSelfWindowRange",false)
			end

--======================================================
-- Zomegas rotate/stretch Code
--======================================================

  WindowSetShowing ("TeatherTargetWindow", true)
  -- Calculate current UI scaling by trying to move the test window to the
  -- middle of the screen and seeing where it actually ends up. Scaling should
  -- be identical for the X and Y axis.

  local anchored_x = WindowGetScreenPosition ("TeatherScaleWindow")
  local scale_xy = ((SystemData.screenResolution.x / 2) / anchored_x)

	local angle = 0
	local length = 0
  -- Early-out if there is no friendly target.



				if  teather.TargetID ~= nil then
					MoveWindowToWorldObject("TeatherTargetWindow", teather.TargetID, ObjecOffset)--0.9962 for player 0.9975
					ForceUpdateWorldObjectWindow(teather.TargetID,"TeatherTargetWindow")
				end

if (WindowGetShowing ("TeatherTargetWindow") == true) then
  -- Early-out if the anchor point for the target object is off-screen.
  --MoveWindowToWorldObject ("TeatherTargetWindow", teather.TargetID, ObjecOffset)

  -- We need to scroll towards the end point which in this case means negating
  -- the scroll value. If we were scrolling towards the start point then the
  -- positive value would be used.
  DynamicImageSetTexture ("TeatherLineLine", OutTexturePack..tostring(GuardTexture[IsXguard]), -scroll_pixels_current, 0)

  -- The line will be drawn from the middle of the screen to the target point.
  -- The middle of the line is centered in the middle of the screen and the line
  -- will then be rotated around that point. To begin with, we need to calculate
  -- the middle of the screen, the line's anchor point, the rotation angle, and
  -- the distance between the start end end. Don't actually start moving the
  -- line window yet.
  local end_x, end_y = WindowGetScreenPosition ("TeatherTargetWindow")
  local start_x,start_y = WindowGetScreenPosition ("TeatherSelfWindow")

	start_x = start_x +(35/scale_xy)
	start_y = start_y +(35/scale_xy)

	end_x = end_x +(35/scale_xy)
	end_y = end_y +((35+teather.Settings.AnchorOffset)/scale_xy)
  local diff_x = end_x - start_x
  local diff_y = end_y - start_y 
  length = math.sqrt ((diff_x * diff_x) + (diff_y * diff_y))

  local mid_x = start_x + (diff_x / 2)
  local mid_y = start_y + (diff_y / 2)

  local dir_x = diff_x / length
  local dir_y = diff_y / length

  angle = math.atan2 (dir_y, dir_x) / (math.pi / 180)

  -- Rotate the image first around an un-anchored mid-point. Clearing the anchor
  -- of the parent seemed to fix a lot of weird rotation issues and allowed it
  -- to rotate in place. The length has to be scaled by scale_xy otherwise it
  -- will end up too show as WindowSetDimentions will modify the input based on
  -- the current UI scale. 14 is the height of the image/window.
  WindowClearAnchors ("TeatherLine")
  WindowSetDimensions ("TeatherLineLine", length * scale_xy, 14)
  DynamicImageSetRotation ("TeatherLineLine", angle)
  WindowSetAlpha ("TeatherLine", 1.0)

  -- Now the rotation is done, move the mid-point of the line window. Needs to
  -- be scaled as WindowAddAnchor also modifies the inputs based on UI scale
  -- which we do not want.
  -- Fix the mid point after this calculations to adjust for the rotation. This
  -- is needed as DynamicImageSetRotation doesn't correctly account for the
  -- height of the window. Height is 14, so we have to adjust by half (7).
  mid_x = mid_x - (dir_y * (7/scale_xy))
  mid_y = mid_y + (dir_x * (7/scale_xy))

  -- Now the rotation is done, move the mid-point of the line window. Needs to
  -- be scaled as WindowAddAnchor also modifies the inputs based on UI scale
  -- which we do not want.
  WindowAddAnchor ("TeatherLine", "topleft", "Root", "topleft", mid_x * scale_xy, mid_y * scale_xy)
else
WindowSetAlpha ("TeatherLine", 0.0)
end


  if (teather.TargetID == 0)
  then
    WindowSetAlpha ("TeatherLine", 0.0)
--    return
  end

--============================================
	
-- ==========================================================================
		
				WindowSetTintColor("TeatherSelfWindow",Color.r,Color.g,Color.b)
				WindowSetTintColor("TeatherTargetWindow",Color.r,Color.g,Color.b)		
				WindowSetTintColor("TeatherLine",Color.r,Color.g,Color.b)


				if IsTeathered > 0 then 
					IsTeathered = IsTeathered-timeElapsed
				else
					if length <= (scroll_pixels_max) then
		
						--WindowSetAlpha("TeatherLine1Line",0)
						DynamicImageSetTexture("TeatherSelfWindowCircle",OutTexturePack.."CircleBG", 0,0)
						DynamicImageSetTexture("TeatherTargetWindowCircle",OutTexturePack.."CircleBG", 0,0)
					else
						if WindowGetShowing("TeatherTargetWindow") == true and IsDistant == false then
						DynamicImageSetTexture("TeatherSelfWindowCircle",OutTexturePack.."TeatherArrow", 0,0)
						DynamicImageSetTexture("TeatherTargetWindowCircle",OutTexturePack.."TeatherArrow", 0,0)
						else
						DynamicImageSetTexture("TeatherSelfWindowCircle",OutTexturePack.."CircleBG", 0,0)
						DynamicImageSetTexture("TeatherTargetWindowCircle",OutTexturePack.."CircleBG", 0,0)
						end
	
						--WindowSetAlpha("TeatherLine1Line",ShowLines)
					end
				end	

				DynamicImageSetRotation("TeatherTargetWindowCircle",angle+90)
				DynamicImageSetRotation("TeatherSelfWindowCircle",angle-90)
		
		local S_x,S_y = WindowGetScreenPosition("TeatherTargetWindow")	
		if  (S_x+ S_y) == 0 or WindowGetAlpha("TeatherSelfWindow") == 0 or (WindowGetShowing("TeatherSelfWindow")) == false or (IsDistant == true) then
			WindowSetShowing("TeatherTargetWindow",false) 
			WindowSetAlpha ("TeatherLine", 0.0)
			end


		if LibGuard.FakeGuarding == true and (GameData.Player.Pet.healthPercent > 0) then
			CircleImageSetTexture( "TeatherTargetWindowIcon", "PetIcon", 32, 32 )
			CircleImageSetTexture( "TeatherSelfWindowIcon", "PetIcon", 32, 32 )
		else
			CircleImageSetTexture( "TeatherTargetWindowIcon", GuardIcons[G_Range_Out], 32, 32 )
			CircleImageSetTexture( "TeatherSelfWindowIcon", GuardIcons[G_Range_Out], 32, 32 )
		end
	

	local ShowGlow = ((tostring(LibGuard.GuarderData.Name) == tostring(teather.OffGuardName)) and (IsXguard) )
		WindowSetTintColor("TeatherSelfWindowGlow",Color.r,Color.g,Color.b)	
		WindowSetTintColor("TeatherTargetWindowGlow",Color.r,Color.g,Color.b)	
		WindowSetShowing("TeatherSelfWindowGlow",ShowGlow and IsTargetGuarded)	
		WindowSetShowing ("TeatherTargetWindowGlow", ShowGlow and IsTargetGuarded)	

	else
		WindowSetAlpha ("TeatherLine", 0.0)
	end

	teather.update2(timeElapsed)

end

--This is for OffGuard Tethering
function teather.update2(timeElapsed)

	local IsDistant = true
	teather.OffGuardInfo = LibGuard.GetIdFromName(tostring(teather.OffGuardName),3)

	if teather.OffGuardInfo ~= nil and teather.OffGuardInfo ~= 0 then
		IsDistant = teather.OffGuardInfo.isDistant
	end
	
	InTexturePack = teather.Settings.InTexturePack
	
	if teather.OffGuardName ~= nil and teather.OffGuardName ~= L"" then
	local IsTargetGuarded = LibGuard.GuarderData.Name == teather.TargetName
	local distance = 0 
	local Color = teather.Settings.Colors.Default

		if LibGuard.registeredGuards[tostring(teather.OffGuardName)] ~= nil then
			distance = LibGuard.registeredGuards[tostring(teather.OffGuardName)].distance
			
			if IsDistant == true then
				Color = teather.Settings.Colors.Distant
				G_Range_In = "Distant"
			else
				if distance < 0 then
					Color = teather.Settings.Colors.Default
					G_Range_In = "Close"
				elseif distance <= 30 and distance >= 0 then
					Color = teather.Settings.Colors.Close
					G_Range_In = "Close"
				elseif distance > 30 and distance <= 50 then
					Color = teather.Settings.Colors.Mid
					G_Range_In = "Mid"
				elseif distance > 50 then
					Color = teather.Settings.Colors.Far
					G_Range_In = "Far"
				else
					Color = teather.Settings.Colors.Distant
					G_Range_In = "Distant"
				end
			end	
		end

		
			WindowClearAnchors( "TeatherOffGuardTargetWindowCircle" )
			WindowAddAnchor( "TeatherOffGuardTargetWindowCircle" , "center", "TeatherOffGuardTargetWindow", "center", 0,(teather.Settings.AnchorOffset))	
			WindowClearAnchors( "TeatherOffGuardTargetWindowIcon" )
			WindowAddAnchor( "TeatherOffGuardTargetWindowIcon" , "center", "TeatherOffGuardTargetWindow", "center", 0,(teather.Settings.AnchorOffset))	

--======================================================
-- Zomegas rotate/stretch Code
--======================================================				




  WindowSetShowing ("TeatherOffGuardTargetWindow", true)


  local anchored_x = WindowGetScreenPosition ("TeatherScaleWindow")
  local scale_xy = ((SystemData.screenResolution.x / 2) / anchored_x)

	local angle = 0
	local length = 0


				local ShowLines = 1 --0
				if WindowGetShowing("TeatherOffGuardTargetWindow") == true and (Check_XGuard() == false) then ShowLines = 1 end
				if teather.OffGuardID ~= nil then
					MoveWindowToWorldObject("TeatherOffGuardTargetWindow", teather.OffGuardID, ObjecOffset)--0.9962 for player 0.9975
					ForceUpdateWorldObjectWindow(teather.OffGuardID,"TeatherOffGuardTargetWindow")
				end

if (WindowGetShowing ("TeatherOffGuardTargetWindow") == true) then

  DynamicImageSetTexture ("TeatherOffGuardLineLine", InTexturePack.."TeatherLine2", scroll_pixels_current, 0)


  local end_x, end_y = WindowGetScreenPosition ("TeatherOffGuardTargetWindow")
  local start_x,start_y = WindowGetScreenPosition ("TeatherOffGuardSelfWindow")

	start_x = start_x +(35/scale_xy)
	start_y = start_y +(35/scale_xy)

	end_x = end_x +(35/scale_xy)
	end_y = end_y +((35+teather.Settings.AnchorOffset)/scale_xy)
  local diff_x = end_x - start_x
  local diff_y = end_y - start_y 
  length = math.sqrt ((diff_x * diff_x) + (diff_y * diff_y))

  local mid_x = start_x + (diff_x / 2)
  local mid_y = start_y + (diff_y / 2)

  local dir_x = diff_x / length
  local dir_y = diff_y / length

  angle = math.atan2 (dir_y, dir_x) / (math.pi / 180)

  WindowClearAnchors ("TeatherOffGuardLine")
  WindowSetDimensions ("TeatherOffGuardLineLine", length * scale_xy, 10)
  DynamicImageSetRotation ("TeatherOffGuardLineLine", angle)
  WindowSetAlpha ("TeatherOffGuardLine", 1.0)

  mid_x = mid_x - (dir_y * (5/scale_xy))
  mid_y = mid_y + (dir_x * (5/scale_xy))

  WindowAddAnchor ("TeatherOffGuardLine", "topleft", "Root", "topleft", mid_x * scale_xy, mid_y * scale_xy)
else
	WindowSetAlpha ("TeatherOffGuardLine", 0.0)
end


  if (teather.TargetID == 0)
  then
    --WindowSetAlpha ("TeatherOffGuardLine", 0.0)
--    return
  end

--============================================
	
-- ==========================================================================

				
				WindowSetTintColor("TeatherOffGuardSelfWindow",Color.r,Color.g,Color.b)
				WindowSetTintColor("TeatherOffGuardTargetWindow",Color.r,Color.g,Color.b)		
				WindowSetTintColor("TeatherOffGuardLine",Color.r,Color.g,Color.b)

				if IsTeatheredOffGuard > 0 then 
					IsTeatheredOffGuard = IsTeatheredOffGuard-timeElapsed
				else
					if length <= (scroll_pixels_max) then	
						DynamicImageSetTexture("TeatherOffGuardSelfWindowCircle",InTexturePack.."CircleIn", 0,0)
						DynamicImageSetTexture("TeatherOffGuardTargetWindowCircle",InTexturePack.."CircleIn", 0,0)
						WindowSetAlpha("TeatherOffGuardLine",0)
					else
						if WindowGetShowing("TeatherOffGuardTargetWindow") == true and IsDistant == false then
								if Check_XGuard() == true then
									DynamicImageSetTexture("TeatherOffGuardSelfWindowCircle",InTexturePack.."CircleIn", 0,0)
									DynamicImageSetTexture("TeatherOffGuardTargetWindowCircle",InTexturePack.."CircleIn", 0,0)
								else
									DynamicImageSetTexture("TeatherOffGuardSelfWindowCircle",InTexturePack.."TeatherArrowIn", 0,0)						
									DynamicImageSetTexture("TeatherOffGuardTargetWindowCircle",InTexturePack.."TeatherArrowIn", 0,0)						
								end
						else
							DynamicImageSetTexture("TeatherOffGuardSelfWindowCircle",InTexturePack.."CircleIn", 0,0)
							DynamicImageSetTexture("TeatherOffGuardTargetWindowCircle",InTexturePack.."CircleIn", 0,0)
						end
						WindowSetAlpha("TeatherOffGuardLine",ShowLines)
					end
				end	
			
				DynamicImageSetRotation("TeatherOffGuardSelfWindowCircle",angle-90)
				DynamicImageSetRotation("TeatherOffGuardTargetWindowCircle",angle+90)

	end
	if (LibGuard.registeredGuards == nil or (NumberOfGuards == 0) or (tostring(LibGuard.GuarderData.Name) == tostring(teather.OffGuardName))) and (IsTargetGuarded) then
		WindowSetShowing("TeatherOffGuardSelfWindow",false)
	else
		WindowSetShowing("TeatherOffGuardSelfWindow",true)
		teather.OffTarget()
	end	

	local S_x,S_y = WindowGetScreenPosition("TeatherOffGuardTargetWindow")	
	if  ((S_x+ S_y) == 0 or (WindowGetShowing("TeatherOffGuardSelfWindow")) == false) or (IsDistant == true) then
	WindowSetShowing("TeatherOffGuardTargetWindow",false) 
	WindowSetAlpha("TeatherOffGuardLine",0) 
	end

	CircleImageSetTexture( "TeatherOffGuardTargetWindowIcon", GuardIcons[G_Range_In], 32, 32 )
	CircleImageSetTexture( "TeatherOffGuardSelfWindowIcon", GuardIcons[G_Range_In], 32, 32 )

end

function teather.OffTarget()
NumberOfGuards = 0
local Range = 999999
teather.OffGuardName = L""


	if LibGuard.FakeGuarded == true and LibGuard.registeredGuards["FakeGuardIn"] ~= nil then
			teather.OffGuardID = LibGuard.registeredGuards["FakeGuardIn"].ID
			teather.OffGuardName = LibGuard.registeredGuards["FakeGuardIn"].Name	
			NumberOfGuards = 1
			teather.ClosestOffGuardName = LibGuard.registeredGuards["FakeGuardIn"].Name
			teather.ClosestOffGuardID = LibGuard.registeredGuards["FakeGuardIn"].ID

	return
	end

			
	for key, value in pairs( LibGuard.registeredGuards ) do	
	NumberOfGuards = NumberOfGuards+1
	
		if LibGuard.registeredGuards[key].distance ~= nil and LibGuard.registeredGuards[key].distance < Range then
			Range = LibGuard.registeredGuards[key].distance		
			teather.OffGuardID = LibGuard.registeredGuards[key].ID
			teather.OffGuardName = towstring(key)	
			
			if Check_XGuard() == true and (towstring(LibGuard.GuarderData.Name) ~= towstring(key)) then
				teather.ClosestOffGuardName = towstring(key)
				teather.ClosestOffGuardID = LibGuard.registeredGuards[key].ID
			else
				teather.ClosestOffGuardName = towstring(key)
				teather.ClosestOffGuardID = LibGuard.registeredGuards[key].ID
			end

			
		end		
	end			
	
	if (NumberOfGuards == 0) then	
			IsTeatheredOffGuard = 0.1
			WindowSetShowing("TeatherOffGuardTargetWindow",false) 
			WindowSetShowing("TeatherOffGuardSelfWindow",false)
			teather.OffGuardID = 0	
			teather.OffGuardName = L""
			teather.ClosestOffGuardName = L""
			teather.ClosestOffGuardID = 0
	end	
return		
end

function teather.FixString (str)
	if (str == nil) then return nil end
	local str = str
	local pos = str:find (L"^", 1, true)
	if (pos) then str = str:sub (1, pos - 1) end	
	return str
end

function teather.Libguard_Toggle(state,GuardedName,GuardedID)
--d(L"State:"..towstring(state)..L" Name:"..towstring(GuardedName)..L" ID:"..towstring(GuardedID))
		if state == GUARDED_APPLY_ID then
		teather.OffGuardID = GuardedID
		teather.OffGuardName = towstring(GuardedName)		
		IsTeatheredOffGuard = 0.1
		WindowSetShowing("TeatherOffGuardTargetWindow",true) 
		WindowSetShowing("TeatherOffGuardSelfWindow",true) 
		teather.OffTarget()
		elseif state == GUARDED_REMOVE_ID then
		teather.OffTarget()		
		elseif state == GUARDING_REMOVE_ID then
			teather.TargetName = L""
			IsTeathered = 0.1
			WindowSetShowing("TeatherTargetWindow",false) 
			--WindowSetShowing("TeatherSelfWindow",false)
			WindowSetAlpha("TeatherSelfWindow",0)
			teather.TargetID = 0			
		elseif state == GUARDING_APPLY_ID then
			teather.TargetName = towstring(GuardedName)
			IsTeathered = 0.1
			WindowSetShowing("TeatherTargetWindow",true) 
			--WindowSetShowing("TeatherSelfWindow",true) 
			WindowSetAlpha("TeatherSelfWindow",1)
			teather.GetIDs()			
		end			
end

function teather.Command(input)
	local input1 = nil
	local input2 = nil
	
	input1 = string.sub(input,0,string.find(input," "))
	if string.find(input," ") ~= nil then
		input1 = string.sub(input,0,string.find(input," ")-1)
		input2 = string.sub(input,string.find(input," ")+1,-1)
	end

	if (input1 == "offset") then
		if (input2 == "") or (input2 == nil) then
			EA_ChatWindow.Print(L"Input offset for Target Guard icon, (Current offset: "..towstring(teather.Settings.AnchorOffset)..L")")
			return		
		else
			teather.Settings.AnchorOffset = tonumber(input2)
		end
	elseif (input1 == "scale") then
		if (input2 == "") or (input2 == nil) then
			EA_ChatWindow.Print(L"Input scale for teather frames, !! NEEDS A '/reloadui' AFTER CHANGE !! (Current scale: "..towstring(teather.Settings.Scale)..L")")
			return		
		else
			teather.Settings.Scale = tonumber(input2)
		end		
	elseif (input1 == "frame") then
		if(input2 == "modern") then
			teather.Settings.OutTexturePack = "Modern_"
			teather.Settings.InTexturePack = "Modern_"
		elseif(input2 == "classic") then
			teather.Settings.OutTexturePack = "Classic_"
			teather.Settings.InTexturePack = "Classic_"
		elseif(input2 == "small") then
			teather.Settings.OutTexturePack = "Small_"
			teather.Settings.InTexturePack = "Small_"
		elseif(input2 == "dots") then
			teather.Settings.OutTexturePack = "Dots_"			
			teather.Settings.InTexturePack = "Dots_"
		elseif(input2 == "chain") then
			teather.Settings.OutTexturePack = "Chain_"			
			teather.Settings.InTexturePack = "Chain_"				
		else
			EA_ChatWindow.Print(L"Input frame for teather| options: modern, classic, small, dots (Current frame: Out:"..towstring(OutTexturePack)..L", in:"..towstring(InTexturePack)..L")")
			return
		end
		
	elseif (input1 == "inframe") then
		if(input2 == "modern") then
			teather.Settings.InTexturePack = "Modern_"
		elseif(input2 == "classic") then
			teather.Settings.InTexturePack = "Classic_"
		elseif(input2 == "small") then
			teather.Settings.InTexturePack = "Small_"
		elseif(input2 == "dots") then		
			teather.Settings.InTexturePack = "Dots_"
		elseif(input2 == "chain") then		
			teather.Settings.InTexturePack = "Chain_"						
		else
			EA_ChatWindow.Print(L"Input In frame for teather| options: modern, classic, small, dots (Current frame: in:"..towstring(InTexturePack)..L")")
			return
		end
		
	elseif (input1 == "outframe") then
		if(input2 == "modern") then
			teather.Settings.OutTexturePack = "Modern_"			
		elseif(input2 == "classic") then
			teather.Settings.OutTexturePack = "Classic_"			
		elseif(input2 == "small") then
			teather.Settings.OutTexturePack = "Small_"
		elseif(input2 == "dots") then
			teather.Settings.OutTexturePack = "Dots_"					
		elseif(input2 == "chain") then
			teather.Settings.OutTexturePack = "Chain_"		
		else
			EA_ChatWindow.Print(L"Input Out frame for teather| options: modern, classic, small, dots (Current frame: Out:"..towstring(OutTexturePack)..L")")
			return
		end
		
	elseif (input1 == "reset") then
		teather.ResetSettings()
	elseif (input1 == "scroll") then
			if (input2 == "") or (input2 == nil) then
				teather.Settings.Scroll = not teather.Settings.Scroll
			return
			else
				teather.Settings.ScrollRate = tonumber(input2)*100
			end
	else
		EA_ChatWindow.Print(L"\n Options for Teather:\n /teather frame <framename>\n /teather inframe <framename>\n /teather outframe <framename>\n /teather offset <number>\n /teather scale <number>\n /teather scroll\n /teather reset")
	return
	end
	--teather.Settings.ScrollRate
end

function teather.FakeGuard(input)
	if (input == "out") then
		LibGuard.FakeGuarding = not LibGuard.FakeGuarding
		teather.Libguard_Toggle(3,"FakeGuardOut",nil)
	elseif (input == "in") then
		LibGuard.FakeGuarded = not LibGuard.FakeGuarded
	end
	return
end


function teather.ResetSettings()
local ScreenWidthX,ScreenHeightY = GetScreenResolution()

teather.Settings = {
	X=ScreenWidthX/2,
	Y=ScreenHeightY/2,
	version = Version,
	AnchorOffset = 80,
	Scroll = true,
	ScrollRate = 100,
	Scale=1,
	OutTexturePack = "Modern_",
	InTexturePack = "Modern_",
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