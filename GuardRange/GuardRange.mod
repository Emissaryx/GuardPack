<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="GuardRange" version="1.5" date="10/01/2024" >

		<Author name="Sullemunk"/>
		<Description text="MultiGuard List/Range" />
		
        <Dependencies>
			<Dependency name="LibGuard" />
			<Dependency name="LibSlash" />			
        </Dependencies>
        
		<SavedVariables>
        	<SavedVariable name="GuardRange.Settings" />
        </SavedVariables> 
        
		<Files>
			<File name="GuardRange.xml" />
		</Files>
		
		<OnInitialize>
            <CallFunction name="GuardRange.Initialize" />
		</OnInitialize>
		<OnUpdate>
        </OnUpdate>
		<OnShutdown/>
		
	</UiMod>
</ModuleFile>
