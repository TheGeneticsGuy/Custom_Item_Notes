-- For all settings
CIN_Settings = CIN_Settings or {};

-- Create a frame for your options panel
local addonName = "Custom Item Notes";
local defaultFont = "Blizz FrizQT";

-- Create a frame for your options panel
local MyAddonPanel = CreateFrame("Frame", addonName .. "OptionsPanel", InterfaceOptionsFramePanelContainer)
MyAddonPanel.name = "Custom Item Notes" -- The name shown in the AddOns list
MyAddonPanel.settingsConfigured = false;

-----------------------------
---- UI API -----------------
-----------------------------

local UI = {};          -- Table to store all functions locally.

-- Method:          CIN.Settings()
-- What it Does:    Returns the Settings db
-- Purpose:         Single place to call the DB
CIN.S = function()
    return CIN_Settings;
end

-- Method:          UI.NormalizeHitRects ( button , fontstring , int , bool )
-- What it Does:    It ensures that no matter what the localization/translation, the hitRects mnatch up to the text length perfectly
-- Purpose:         Quality of life
UI.NormalizeHitRects = function ( checkButton , checkButtonFontstring , modifier , reverse )
    local n = modifier or 0;

    if not reverse then
        checkButton:SetHitRectInsets ( 0 , n - checkButtonFontstring:GetWidth() - 2 , 0 , 0 );
    else
        checkButton:SetHitRectInsets ( n - checkButtonFontstring:GetWidth() + 2 , 0 , 0 , 0 );
    end
end

-- Method:          UI.CreateCheckBox ( string , frame , string , array , array , function , string , string , int , function , function , bool , dbVar )
-- What it Does:    Builds out a new checkbox
-- Purpose:         Cleanup code with reusable tool.
UI.CreateCheckBox = function ( name , parentFrame , template , size , points, buttonScript , text , textTemplate , fontSize , toolTipScript , toolTipClearScript , initialValue , settingsName )

    local fontStringText = name.."Text";

    if not parentFrame[name] then
        local checkBoxTemplate = template or "InterfaceOptionsCheckButtonTemplate";
        fontSize = fontSize or 12;

        parentFrame[name] = CreateFrame ( "CheckButton" , name , parentFrame , checkBoxTemplate );
        parentFrame[name].value = initialValue or false;
        parentFrame[name]:SetChecked ( parentFrame[name].value );

        if size then
            parentFrame[name]:SetSize ( size[1] , size[2] );
        end
        parentFrame[name]:SetPoint ( points[1] , points[2] , points[3] , points[4] , points[5] );

        parentFrame[name][fontStringText] = parentFrame[name]:CreateFontString ( nil , "OVERLAY" , textTemplate );
        parentFrame[name][fontStringText]:SetPoint ( "LEFT" , parentFrame[name] , "RIGHT" , 2 , 0 );
        parentFrame[name][fontStringText]:SetWordWrap ( false );
        parentFrame[name][fontStringText]:SetJustifyH ( "LEFT" );

        parentFrame[name]:SetScript ( "OnClick" , function( self , button )
            if button == "LeftButton" then
                self.value = self:GetChecked();
                if settingsName and CIN_Settings[settingsName] ~= nil then  -- Must be explicit, not truthy here on the ~= nil, in case the setting val is a boolean.
                    CIN_Settings[settingsName] = self.value;
                end
                if buttonScript then
                    buttonScript( self );
                end
            end
        end);

        -- SCRIPTS
        if toolTipScript then
            parentFrame[name]:SetScript ( "OnEnter" , function( self )
                toolTipScript( self );
            end);

            parentFrame[name]:SetScript ( "OnLeave" , function()
                if toolTipClearScript then
                    toolTipClearScript();
                else
                    GameTooltip:Hide();
                end
            end);
        end

    end

    parentFrame[name][fontStringText]:SetText ( text );
    parentFrame[name][fontStringText]:SetFont ( defaultFont , fontSize );
    UI.NormalizeHitRects ( parentFrame[name] , parentFrame[name][fontStringText] );
end

----------------------------------
-- BUILD THE SETTINGS INTERFACE --
----------------------------------

MyAddonPanel:HookScript ( "OnShow" , function( self )
    if not self.settingsConfigured then
        local title = MyAddonPanel:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(addonName);
        -- Checkbox
        UI.CreateCheckBox ( "CIN_HiddenHotKey" , MyAddonPanel , nil , nil , { "TOPLEFT" , title , "BOTTOMLEFT" , 0 , -15 } , nil , "Hold TAB to see notes" , "GameFontNormal" , 11 , nil , nil , CIN_Settings.keyToSee , "keyToSee" );
        self.settingsConfigured = true;
    end
end);







-------------------------
-- FINAL CONFIGURATION --
-------------------------

local MySettings = {};
CIN.MySettings = MySettings;

MySettings.SettingsDefaults = function ( fullReset )

    if fullReset then
        CIN_Settings = {};
    end

    CIN_Settings.keyToSee = CIN_Settings.keyToSee or false;
    CIN_Settings.keyToSeeName = CIN_Settings.keyToSeeName or "TAB";
end

MySettings.InitializeSettings = function()

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(MyAddonPanel)
    else
        local category, layout = Settings.RegisterCanvasLayoutCategory(MyAddonPanel, MyAddonPanel.name);
        Settings.RegisterAddOnCategory(category);
        -- CIN_Settings.settingsCategory = category
    end

    -- Load settings
    MySettings.SettingsDefaults();

    CIN.ToolTipPostCallInitialization();

end

