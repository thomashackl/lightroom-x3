--[[----------------------------------------------------------------------------

X3GalleryServiceProvider.lua
Export service provider description for X3 Photo Gallery

--------------------------------------------------------------------------------

Thomas Hackl
 Copyright 2019
 All Rights Reserved.

------------------------------------------------------------------------------]]

-- Lightroom SDK
local LrView = import 'LrView'
local LrLogger = import 'LrLogger'

local myLogger = LrLogger( 'X3' )
myLogger:enable( 'print' )

-- X3 Photo Gallery plugin
require 'X3GalleryFtpConnection'

--============================================================================--

local exportServiceProvider = {}

exportServiceProvider.supportsIncrementalPublish = true

exportServiceProvider.hideSections = { 'exportLocation' }

exportServiceProvider.allowFileFormats = { 'JPEG' }

exportServiceProvider.allowColorSpaces = { 'sRGB' }

exportServiceProvider.hidePrintResolution = true

exportServiceProvider.canExportVideo = true

exportServiceProvider.exportPresetFields = {
  { key = 'ftpPreset', default = nil }
}

local function updateExportStatus( propertyTable )

	local message = nil

	repeat
		-- Use a repeat loop to allow easy way to 'break' out.
		-- (It only goes through once.)

		if propertyTable.ftpPreset == nil then
			message = LOC '$$$/X3GalleryPlugin/Status/NoFtpPreset=Select or Create an FTP preset'
			break
		end

		local fullPath = propertyTable.ftpPreset.path or ''

		propertyTable.fullPath = fullPath

	until true

	if message then
		propertyTable.message = message
		propertyTable.hasError = true
		propertyTable.hasNoError = false
		propertyTable.LR_cantExportBecause = message
	else
		propertyTable.message = nil
		propertyTable.hasError = false
		propertyTable.hasNoError = true
		propertyTable.LR_cantExportBecause = nil
	end

end

function exportServiceProvider.startDialog( propertyTable )

  propertyTable:addObserver( 'items', updateExportStatus )
  propertyTable:addObserver( 'ftpPreset', updateExportStatus )

  updateExportStatus( propertyTable )

end

function exportServiceProvider.viewForCollectionSettings( f, publishSettings, info )
  local bind = LrView.bind

	local collectionSettings = assert( info.collectionSettings )

end

function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
  X3GalleryFtpConnection.uploadPhotos( functionContext, exportContext )
end

return exportServiceProvider
