local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrColor = import 'LrColor'

MyHWLibraryItem = {}
function MyHWLibraryItem.showCustomDialog()
-- body of show-dialog function
    LrFunctionContext.callWithContext( "showCustomDialog", function( context )
        -- body of called function
        local props = LrBinding.makePropertyTable( context ) -- create bound table
        props.isChecked = false -- add a property key and initial value
        -- create view hierarchy
        local f = LrView.osFactory()
        local c = f:row { -- the root node
            bind_to_object = props, -- bound to our data table
            -- add controls
            f:checkbox {
                title = "Enable", -- label text
                value = LrView.bind( "isChecked" ) -- bind button state to data key
            },
            f:edit_field {
                value = "Some Text",
                enabled = LrView.bind( "isChecked" ) -- bind state to same key
            },
        }
        local result = LrDialogs.presentModalDialog({
            title = "Custom Dialog",
            contents = c, -- the view hierarchy we defined
        })

    end)
end

MyHWLibraryItem.showCustomDialog()