--[[----------------------------------------------------------------------------

Info.lua
Summary information for X3 photo gallery plug-in

--------------------------------------------------------------------------------

Thomas Hackl
 Copyright 2019 Thomas Hackl
 All Rights Reserved.

This plug-in provides photo upload via FTP to a remote server and generating
the correct page.json with metadata needed for X3 photo gallery.

------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 9.0,
	LrSdkMinimumVersion = 3.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'name.thomas-hackl.lightroom.export.x3',

	LrPluginName = 'X3 Photo Gallery',

	LrExportServiceProvider = {
		title = 'X3 Photo Gallery',
		file = 'X3GalleryServiceProvider.lua',
	},

	VERSION = { major=1, minor=0, revision=0, build='0', },

}
