<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <UiMod name="teather" version="1.5" date="10/1/2024">
	<VersionSettings gameVersion="1.4.8" windowsVersion="1.0" savedVariablesVersion="1.0" /> 
     <Author name="Sullemunk" />
        <Description text="Tether you to a Guard, Use /teather for options" />
		<Dependencies>
			<Dependency name="EATemplate_Icons"/>
			<Dependency name="LibGuard"/>			
			<Dependency name="LibSlash"/>			
		</Dependencies>
        <Files>
            <File name="teather.lua" />
            <File name="teather.xml" />
        </Files>
		
		<SavedVariables>
        	<SavedVariable name="teather.Settings" />
        </SavedVariables> 
		
        <OnInitialize>
            <CallFunction name="teather.init" />
        </OnInitialize>
        <OnUpdate>
	            <CallFunction name="teather.update" />		
    	  </OnUpdate>
        <OnShutdown />
    </UiMod>
</ModuleFile>