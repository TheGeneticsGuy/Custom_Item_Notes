
-- FOR MODIFICATIONS TO EXISTING DB
local version = 1.16;
local CIN_Patch = {};

-- Control the flow of future updates.
CIN.PatchCheck = function()
    local updateCount = 0

    if not CIN_Save.VERSION or CIN_Save.VERSION < 1.15 then
        updateCount = updateCount + 1;
        CIN_Patch.ConvertDBEntriesToStrings();
        CIN_Save.VERSION = 1.15;
    end

    -- -- FUTURE UPDATE TEMPLATE EXAMPLE
    -- if CIN_Save.VERSION < 1.16 then
    --     updateCount = updateCount + 1;

    --     -- Run logic here

    --     -- Set to this version so it doesn't need to ever update this again
    --     -- Do not set as current version til the end.
    --     CIN_Save.VERSION = 1.16;
    -- end

    -- FINAL UPDATE
    if CIN_Save.VERSION < version then
        CIN_Save.VERSION = version;
    end

    if updateCount > 0 then
        print("CIN: Custom Item Notes patch completed");
    end
end

-- Patch 1.15
-- Method:          CIN_Patch.ConvertDBEntriesToStrings()
-- What it Does:    Converts the existing database of itemIDs into their string names
-- Purpose:         Updating the database to include differentiation of items based on the anme rather than the item ID as the item can vary based on upgrades but the base itemID doesn't change, which isn't helpful.
CIN_Patch.ConvertDBEntriesToStrings = function( repeatedCount )
    repeatedCount = repeatedCount or 1;

    local notConverted = 0;
    
    for id in pairs ( CIN_Save ) do
        local itemID = tonumber (id)
        if itemID then

            if #CIN_Save[id] > 0 then

                local name = GetItemInfo ( itemID );
                -- Call it a 2nd time. For some reason, in some cases, the client does not provide a response until the 2nd call.
                if not name then
                    name = GetItemInfo ( itemID );
                end

                if name then
                    CIN_Save[name] = CIN.DeepCopyArray ( CIN_Save[id] );   -- Do a full copy to wipe all memory references
                    CIN_Save[name].itemID = tonumber(id);
                    CIN_Save[id] = nil;                                 -- Clear the old copy.
                else
                    -- Couldn't pull the ID for some reason
                    notConverted = notConverted + 1;
                end
            else
                -- Fixing an existing bug where the reference was never removed if it has no notes
                CIN_Save[id] = nil;

            end
        end
    end

    -- Adding some redundancy as sometimes the server won't update the item Info right away.
    -- Gonna give it 5 tries to call to the server with 2 second interval. The reason why is because
    -- I have found that most of the time server will refresh data within 1-2 seconds, but in some cases
    -- the server takes as much as 10 seconds for items not yet cached. 
    if notConverted > 0 and repeatedCount < 6 then
        repeatedCount = repeatedCount + 1;
        C_Timer.After ( 2 , function()
            CIN_Patch.ConvertDBEntriesToStrings ( repeatedCount );
        end);
        return;
    end

    if not CIN_Save.VERSION then
        CIN_Save.VERSION = 1.15;
    end
end