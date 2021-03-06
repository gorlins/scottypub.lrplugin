return {
    LrSdkVersion = 5.0,
    LrToolkitIdentifier = 'com.adobe.lightroom.sdk.scottygee',

    LrPluginName = LOC "$$$/PluginInfo/Name=ScottyGee",

    LrExportMenuItems = {
        {
            title = "Setup SmugMug Collections",
            file = "SetupSmugmugCollections.lua",
        },
        { 
            title = "Detect Duplicates", 
            file = "ReorganizeByTime.lua",
        },
        { 
            title = "Report Photo Meta", 
            file = "ReportPhotoMetadata.lua",
        },
    },

    --LrLibraryMenuItems = {
    --    title = "Hello World Custom Dialog",
    --    file = "LibraryMenuItem.lua",
    --},
}