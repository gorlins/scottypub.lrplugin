return {
    LrSdkVersion = 5.0,
    LrToolkitIdentifier = 'com.adobe.lightroom.sdk.helloworld',

    LrPluginName = LOC "$$$/PluginInfo/Name=ScottyGee",

    LrExportMenuItems = {
        title = "Hello World Dialog",
        file = "ExportMenuItem.lua",
    },

    LrLibraryMenuItems = {
        title = "Hello World Custom Dialog",
        file = "LibraryMenuItem.lua",
    },
}