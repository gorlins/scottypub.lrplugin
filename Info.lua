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
            title = "Reorganize by timestamp", 
            file = "ReorganizeByTime.lua",
        },
    },

    --LrLibraryMenuItems = {
    --    title = "Hello World Custom Dialog",
    --    file = "LibraryMenuItem.lua",
    --},
}