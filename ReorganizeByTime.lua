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

function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
 end

function MyHWExportItem.reorganize_by_time()
    
    local catalog = LrApplication.activeCatalog()
    local all_folders = catalog:getFolders()

    local names = {}

    for k, v in pairs(all_folders) do
        names[v:getName()] = v
    end

    local target_folder = names['iCloudImports']
    base_path = target_folder:getPath()
    local filenamePresets = LrApplication.filenamePresets()
    local filename_preset = filenamePresets['ScottyG']

    photos = target_folder:getPhotos(true)
    total_photos = #photos
    catalog:withWriteAccessDo('reorganize_by_timestamp', function( context )
        moved = 0
        local progress = LrProgressScope({title = "Reorganizing by timestamp"})
        progress:attachToFunctionContext(context)
        progress:setCancelable( true )
        for pi, photo in ipairs(photos) do
            if progress:isCanceled() then
                break
            end
            progress:setPortionComplete(pi, total_photos)
            current_path = photo:getRawMetadata('path')
            leaf_name = LrPathUtils.leafName(current_path)
            date_folder = LrPathUtils.leafName(LrPathUtils.parent(current_path))
            target_name = photo:getNameViaPreset( filename_preset, '', 0 )

            target_parts = Split(target_name, '-')

            current_relative = LrPathUtils.makeRelative(current_path, base_path)

            target_relative = LrPathUtils.child(
                target_parts[1],
                LrPathUtils.child(
                    target_parts[1] .. '-' .. target_parts[2],
                    LrPathUtils.child(
                        target_parts[1] .. '-' .. target_parts[2] .. '-' .. target_parts[3],
                        target_name
                    )
                )
            )

            if string.starts(current_relative, target_relative) then
            else
                dest = LrFileUtils.chooseUniqueFileName(LrPathUtils.addExtension(target_relative, LrPathUtils.extension(current_relative)))
                dest_path = LrPathUtils.makeAbsolute(dest, base_path)
                -- LrDialogs.message(current_relative, dest, "info")
                moved = moved + 1
                -- break
                photo:setRawMetadata('colorNameForLabel', 'red')
                -- LrDialogs.message(current_path, dest_path, "info")
                -- break
                -- LrFileUtils.createAllDirectories( dest_path )
                -- LrFileUtils.move( current_path, dest_path )
                -- break
            end
        end 
        LrDialogs.message("Done", "moved " .. tostring(moved), "info")
    end )
end

LrTasks.startAsyncTask(MyHWExportItem.reorganize_by_time)