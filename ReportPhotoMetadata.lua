local LrDialogs = import 'LrDialogs'
local LrDate = import 'LrDate'
local LrLogger = import 'LrLogger'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrErrors = import 'LrErrors'
local LrApplication = import "LrApplication"
local LrProgressScope = import "LrProgressScope"
local myLogger = LrLogger( 'libraryLogger' )
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
myLogger:enable( "print" ) -- or "logfile"

MyHWExportItem = {}

-- function groupMessages(array)
--     local result = {};
--     for k, v in ipairs(array) do
--         if not result[v.sender] then
--             result[v.sender] = {};
--         end

--         table.insert(result[v.sender], v);
--     end

--    return result;
-- end

function concat ( a, b )
    local result = {}
    for k,v in pairs ( a ) do
        table.insert( result, v )
    end
    for k,v in pairs ( b ) do
         table.insert( result, v )
    end
    return result
end

function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function table_print (tt, indent, done)
    done = done or {}
    indent = indent or 0
    if type(tt) == "table" then
      local sb = {}
      for key, value in pairs (tt) do
        table.insert(sb, string.rep (" ", indent)) -- indent it
        if type (value) == "table" and not done [value] then
          done [value] = true
          table.insert(sb, "{\n");
          table.insert(sb, table_print (value, indent + 2, done))
          table.insert(sb, string.rep (" ", indent)) -- indent it
          table.insert(sb, "}\n");
        elseif "number" == type(key) then
          table.insert(sb, string.format("\"%s\"\n", tostring(value)))
        else
          table.insert(sb, string.format(
              "%s = \"%s\"\n", tostring (key), tostring(value)))
         end
      end
      return table.concat(sb)
    else
      return tt .. "\n"
    end
end


function MyHWExportItem.report_photo_metadata()
    
    local catalog = LrApplication.activeCatalog()
    local photo = catalog:getTargetPhoto()

    local common_fields = {'dateTimeOriginal', 'dateTimeDigitized', 'dateTime'}
    local raw_meta = catalog:batchGetRawMetadata({photo}, concat(common_fields, {'dateTimeOriginalISO8601', 'dateTimeDigitizedISO8601', 'dateTimeISO8601', 'gps', 'path'}))[photo]
    local formatted_meta = catalog:batchGetFormattedMetadata({photo}, concat(common_fields, {'dateCreated', 'preservedFileName', 'folderName'}))[photo]

    -- process raw common just to make readable
    for i, v in ipairs(common_fields) do
        raw = raw_meta[v]
        if raw ~= nil then
            raw_meta[v] = '(parsed) ' .. LrDate.timeToW3CDate(raw)
        else
            raw_meta[v] = 'missing'
        end
    end

    raw_meta['parent_folder_name'] = LrPathUtils.leafName(LrPathUtils.parent(raw_meta['path']))

    local filenamePresets = LrApplication.filenamePresets()
    formatted_meta['preset_scotty'] = photo:getNameViaPreset( filenamePresets['ScottyG'], '', 0 ) 
    formatted_meta['preset_iso'] = photo:getNameViaPreset( filenamePresets['ISO8601'], '', 0 ) 

    LrDialogs.message('Photo Metadata', table_print(raw_meta) .. '\n\n' .. table_print(formatted_meta), 'info')

end

LrTasks.startAsyncTask(MyHWExportItem.report_photo_metadata)