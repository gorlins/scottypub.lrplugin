LrDialogs = import 'LrDialogs'
LrDate = import 'LrDate'
LrLogger = import 'LrLogger'
LrPathUtils = import 'LrPathUtils'
LrFileUtils = import 'LrFileUtils'
LrErrors = import 'LrErrors'
LrApplication = import "LrApplication"
LrProgressScope = import "LrProgressScope"
myLogger = LrLogger( 'libraryLogger' )
LrTasks = import 'LrTasks'
LrFunctionContext = import 'LrFunctionContext'
myLogger:enable( "print" ) -- or "logfile"

MyHWExportItem = {}

-- function groupMessages(array)
--     result = {};
--     for k, v in ipairs(array) do
--         if not result[v.sender] then
--             result[v.sender] = {};
--         end

--         table.insert(result[v.sender], v);
--     end

--    return result;
-- end

function Split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start)) == Start
 end

function is_estimated_dt(dt)
    if dt == nil then 
        return true
    end

    local year, month, day, hour, minute, second = LrDate.timestampToComponents(dt)

    -- if minute and second are 0, assume it was manually inputted
    return (minute == 0) and (second == 0)
end

function filter(predicate, orig_table)
    local result = {}
    for i, v in ipairs(orig_table) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

function flag_and_filter_if_any(predicate, photos, flag)
    -- If predicate evaluates true for any of photos, flag the rest with a color
    -- return the filtered set if any, the original if none
    local filtered = filter(predicate, photos)
    if #filtered > 0 then
        for i, photo in ipairs(photos) do
            if not predicate(photo) then
                photo:setRawMetadata('colorNameForLabel', flag)
            end
        end
        return filtered
    end
    return photos
end

function MyHWExportItem.reorganize_by_time()
    
    catalog = LrApplication.activeCatalog()

    catalog:withWriteAccessDo('reorganize_by_timestamp', function( context )
        local all_folders = catalog:getFolders()
    
        local names = {}
    
        for k, v in pairs(all_folders) do
            names[v:getName()] = v
        end
    
        local target_folder = names['Originals']
        local base_path = target_folder:getPath()
        local filenamePresets = LrApplication.filenamePresets()
        local filename_preset = filenamePresets['ISO8601']
    
        local photos = target_folder:getPhotos(true)
        -- local photos = catalog:getTargetPhotos()
        local total_photos = #photos

        local badness = catalog:createCollectionSet( "Duplicates", nil, true )
        local dupe_collection = catalog:createCollection(LrDate.timeToW3CDate(LrDate.currentTime()), badness)
        local progress = LrProgressScope({title = "Detecting Duplicates"})
        local index_progress = LrProgressScope({caption = "Creating index", title="creating index", parent=progress, parentEndRange=0.5})
        local dupes = {}

        progress:attachToFunctionContext(context)
        progress:setCancelable( true )
        index_progress:setCancelable( true )

        local raw_metadata = catalog:batchGetRawMetadata( photos, {'gps', 'pickStatus', 'path', 'fileFormat', 'dimensions', 'isVirtualCopy', 'dateTimeOriginal'} )
        local formatted_metadata = catalog:batchGetFormattedMetadata(photos, {'dateCreated', 'preservedFileName', 'gps', 'folderName'})

        function has_gps(photo)
            local gps = raw_metadata[photo]['gps']
            if gps ~= nil then
                local lat = gps['latitude']
                return lat ~= nil
            else
                return false
            end
        end

        function get_photo_size(photo)
            local d = raw_metadata[photo]['dimensions']
            return d['width'] * d['height']
        end

        function sort_mpix(p1, p2)
            -- reverse order because of size priority - bigger should sort first
            return get_photo_size(p2) < get_photo_size(p1)
        end

        local pi = 0
        local uniques = 0
        for pi, photo in ipairs(photos) do
            if index_progress:isCanceled() then
                break
            end
            local meta = raw_metadata[photo]
            index_progress:setPortionComplete(pi-1, total_photos)
            progress:setCaption("Deduping " .. tostring(pi) .. " of " .. tostring(total_photos))

            -- current_path = photo:getRawMetadata('path')
            -- leaf_name = LrPathUtils.leafName(current_path)
            -- date_folder = LrPathUtils.leafName(LrPathUtils.parent(current_path))
            -- valid_formats = {JPG=true, VIDEO=true}
            if (meta['pickStatus'] >= 0)                  -- Skip rejected photos
                and (not meta['isVirtualCopy'])           -- and non-originals
                -- and valid_formats[meta['fileFormat']
                --     (meta['fileFormat'] == 'JPG')         -- ignore RAW because faster shutter, more likely FP dupes by timestamp
                --     or (meta['fileFormat'] == 'VIDEO'))
                then
                -- preset_filename = photo:getNameViaPreset( filename_preset, '', 0 ) 

                -- current_path = photo:getRawMetadata('path')
                -- current_path = meta['path']
                -- leaf_name = LrPathUtils.leafName(current_path)
                
                -- target_name = preset_filename .. photo:getRawMetadata('fileFormat')
                -- target_name = preset_filename .. meta['fileFormat']

                local fm = formatted_metadata[photo]
                --is_estimated_dt(meta['dateTimeOriginal'])
                -- use dateCreated because it has ms sometimes
                -- fallback to digitized for movies etc (and use ISO because raw values are unstable?)
                local dc = fm['dateCreated']
                local dd = meta['dateTimeDigitizedISO8601']
                local dto = meta['dateTimeOriginal']
                local time_key = nil
                if (
                    dc ~= nil and dc ~= ''
                ) then
                    time_key = dc:gsub(':', '-') -- to conform with preset which cannot use :
                elseif (dd ~= nil and dd ~= '') then
                    time_key = dd
                else
                    -- TS not available in metadata, but may still be in LR catalog?
                    -- Fall back to getting via filename preset
                    time_key = photo:getNameViaPreset( filename_preset, '', 0 )
                    -- photo:setRawMetadata('colorNameForLabel', 'purple')
                end

                if (dto ~= nil and not is_estimated_dt(meta['dateTimeOriginal'])) and time_key ~= nil then
                    local key = time_key .. meta['fileFormat'] --.. fm['preservedFileName']
                    
                    -- Insert into index by target filename
                    if not dupes[key] then
                        dupes[key] = {}
                        uniques = uniques + 1
                    end
                    table.insert(dupes[key], photo)

                    -- If the current filename doesn't match the target, it indicates likely sent or copied (?)
                    -- unclear why, the dates are initially wrong on import
                    -- Mark as red to make it easier deduplicating

                    -- if (leafName == nil or target_name == nil) then
                    --     -- bad metadata?
                    -- elseif string.starts(leafName, preset_filename) then
                    -- else
                    --     photo:setRawMetadata('colorNameForLabel', 'red')
                    -- end
                end
            end
            -- target_parts = Split(target_name, '-')

            -- current_relative = LrPathUtils.makeRelative(current_path, base_path)

            -- target_relative = LrPathUtils.child(
            --     target_parts[1],
            --     LrPathUtils.child(
            --         target_parts[1] .. '-' .. target_parts[2],
            --         LrPathUtils.child(
            --             target_parts[1] .. '-' .. target_parts[2] .. '-' .. target_parts[3],
            --             target_name
            --         )
            --     )
            -- )

            -- if string.starts(current_relative, target_relative) then
            -- else
            --     -- dest = LrFileUtils.chooseUniqueFileName(LrPathUtils.addExtension(target_relative, LrPathUtils.extension(current_relative)))
            --     -- dest_path = LrPathUtils.makeAbsolute(dest, base_path)
            --     -- LrDialogs.message(current_relative, dest, "info")
            --     moved = moved + 1
            --     -- break
            --     photo:setRawMetadata('colorNameForLabel', 'red')
            --     -- Note moving does not ensure photo is recognized by LR catalog!  Seems not possible in API
            --     -- LrDialogs.message(current_path, dest_path, "info")
            --     -- break
            --     -- LrFileUtils.createAllDirectories( dest_path )
            --     -- LrFileUtils.move( current_path, dest_path )
            --     -- break
            -- end
        end
        index_progress:done()
        -- LrDialogs.showBezel("Processed " .. tostring(pi) .. ' images')

        local collection_progress = LrProgressScope({caption = "Creating dupes collection", parent=progress})

        -- LrDialogs.message("Done creating index", "Found " .. tostring(total_uniques) .. " unique photos", "info")
        local i = 0
        for key, dupe_photos in pairs(dupes) do

            if progress:isCanceled() then
                break
            end

            progress:setCaption('Processing ' .. tostring(i) .. " of " .. tostring(uniques) .. ' uniques')
            collection_progress:setPortionComplete(i, uniques) 
            local ndupes = #dupe_photos
            if ndupes > 1 then
                if ndupes < 10 then

                    table.sort(dupe_photos, sort_mpix)
                    -- huge # of dupes likely due to incorrect DT

                    local max_size = get_photo_size(dupe_photos[1])
                    function not_cropped (photo)
                        return get_photo_size(photo) == max_size
                    end
                    local filtered = flag_and_filter_if_any(not_cropped, dupe_photos, 'yellow')
                    
                    -- Look for any w/ GPS coords
                    -- LrDialogs.message('adsfff', tostring(has_gps(fullsize[1])) .. tostring(has_gps(fullsize[1])) .. tostring(#fullsize), 'info')
                    filtered = flag_and_filter_if_any(has_gps, filtered, 'blue')

                    -- See which are in the wrong folder
                    function correct_date_folder(photo)
                        local folderName = formatted_metadata[photo]['folderName']

                        -- First 10 chars are date: YYYY-mm-dd
                        return string.starts(folderName, string.sub(key, 1, 10))
                    end
                    filtered = flag_and_filter_if_any(correct_date_folder, filtered, 'red')

                    -- Unset color for the rest
                    for i, p in ipairs(filtered) do
                        p:setRawMetadata('colorNameForLabel', 'none')
                    end

                    -- Add all dupes to collection
                    dupe_collection:addPhotos(dupe_photos)
                    -- LrDialogs.message("Adding dupes", "Key: " .. key .. " has " .. tostring(#photos), "info")
                    -- break
                end
            end
            i = i + 1
        end
        -- LrDialogs.message('asdf', tostring(i), 'info')
    end )
end

LrTasks.startAsyncTask(MyHWExportItem.reorganize_by_time)