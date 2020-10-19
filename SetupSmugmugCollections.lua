local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrErrors = import 'LrErrors'
local LrApplication = import "LrApplication"
local myLogger = LrLogger( 'libraryLogger' )
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
myLogger:enable( "print" ) -- or "logfile"

MyHWExportItem = {}

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

function to_string( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return table_print(tbl)
    elseif  "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
end

function MyHWExportItem.setup_smugmug_collections()
    
    local catalog = LrApplication.activeCatalog()
    local all_services = catalog:getPublishServices(nil)

    local names = {}

    for k, v in pairs(all_services) do
        names[v:getName()] = v
    end

    local target_service = names['scottgorlin']
    local collection_sets = target_service:getChildCollectionSets()

    local set_names = {}
    for k, v in pairs(collection_sets) do
        set_names[v:getName()] = v
    end
    local archive = set_names['Archive']

    --LrDialogs.message("ExportMenuItem Selected", to_string(archive:getCollectionSetInfoSummary()['collectionSettings']), "helloworld info")
    
    local months = {"01", "02", "03", '04', '05', '06', '07', '08', '09', '10', '11', '12'}
    local years = {"2019", "2020"}
    
    for yi, year in pairs(years) do
      
       catalog:withWriteAccessDo('create_smugmug', function( )
           year_set = target_service:createPublishedCollectionSet(tostring(year), archive, true)
           
           for ki, month in pairs(months) do
             local my = year .. '-' .. month
             
             local searchDesc = {
                 {
                     criteria = "keywords",
                     operation = "noneOf",
                     value = "PRIVATE",
                 },
                 {
                     criteria = "keywords",
                     operation = "noneOf",
                     value = "PROFESSIONALS",
                 },
                 {
                   criteria = "pick",
                   operation = '!=',
                   value = -1,
                 },
                 {
                     criteria = "captureTime",
                     operation = "in",
                     value = my .. '-01',
                     value2 = my .. '-32',
                 },
                 combine = "intersect",
             }
             month_collection = target_service:createPublishedSmartCollection(my, searchDesc, year_set, true )
             month_collection:setSearchDescription(searchDesc)
             
             --summary = month_collection:getCollectionInfoSummary()
             --settings = summary.collectionSettings
             --LrDialogs.message("ExportMenuItem Selected", to_string(settings), "helloworld info")
           end
           
         end ) 
      
    end
end

LrTasks.startAsyncTask(MyHWExportItem.setup_smugmug_collections)