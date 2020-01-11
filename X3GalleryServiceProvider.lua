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
local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'

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

-- Progess bar for export/publish process
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

-- Retrieve all photo filenames for the given collection
-- This function is asnychronous.
local function getPhotoNames( collection )
  local photoNames = {}
  completed = false

  LrTasks.startAsyncTask(function()
    local photos = collection:getPhotos()

    -- Fetch metadata (filename) for each photo
    for i, photo in ipairs( photos ) do
      local fileName = photo:getFormattedMetadata( 'fileName' )
      table.insert(photoNames, fileName)
    end

    completed = true
  end)

  while not completed do
    LrTasks.sleep(0.25)
  end

  return photoNames

end

-- Show export/publish settings dialog.
function exportServiceProvider.startDialog( propertyTable )

  propertyTable:addObserver( 'items', updateExportStatus )
  propertyTable:addObserver( 'ftpPreset', updateExportStatus )

  updateExportStatus( propertyTable )

end

-- Add appropriate config sections to publisher config dialog
function exportServiceProvider.sectionsForTopOfDialog( f, propertyTable )

  local bind = LrView.bind
  local share = LrView.share
  local LrFtp = import 'LrFtp'

	return {
		{
			title = LOC '$$$/X3GalleryPlugin/Labels/X3Installation=X3 installation',

      synopsis = LOC '$$$/X3GalleryPlugin/Labels/Synopsis=Server where photos should be uploaded per FTP',

			f:row {
				f:static_text {
					title = LOC '$$$/X3GalleryPlugin/Labels/FtpDestination=FTP connection',
					alignment = 'right',
					width = share 'labelWidth'
				},

				LrFtp.makeFtpPresetPopup {
					factory = f,
					properties = propertyTable,
					valueBinding = 'ftpPreset',
					itemsBinding = 'items',
					fill_horizontal = 1,
  			}
  		}

  	}
	}

end

-- Add custom sections to collection configuration dialog.
function exportServiceProvider.viewForCollectionSettings( f, publishSettings, info )
  local bind = LrView.bind
  local share = LrView.share

  local publishedCollection = info.publishedCollection
  local collectionSettings = assert( info.collectionSettings )

  -- Get photo filenames.
  local photoNames = getPhotoNames( publishedCollection )

  -- Photo filename selection, but with an entry 'no photo' on top
  local noHeader = LOC '$$$/X3GalleryPlugin/Labels/NoPicture=-- no picture --'
  local photoNamesWithNoSelection = photoNames
  table.insert(photoNamesWithNoSelection, 1, noHeader)

  if not collectionSettings.album_header then
    collectionSettings.album_header = noHeader
  end

  return f:view {
    bind_to_object = info,
    spacing = f.dialog_spacing(),

    f:group_box {
      title = LOC '$$$/X3GalleryPlugin/Labels/X3AlbumSettings=X3 album settings',
      fill_horizontal = 1,

      f:row {
        f:static_text {
          title = LOC '$$$/X3GalleryPlugin/Labels/AlbumName=Name',
          width = share 'collectionset_labelwidth',
        },
        f:edit_field {
          bind_to_object = info.collectionSettings,
          value = bind 'album_name',
          width_in_chars = 60
        }
      },

      f:row {
        f:static_text {
          title = LOC '$$$/X3GalleryPlugin/Labels/AlbumDescription=Description',
          width = share 'collectionset_labelwidth',
        },
        f:edit_field {
          bind_to_object = info.collectionSettings,
          value = bind 'album_description',
          width_in_chars = 60,
          height_in_lines = 4
        }
      };

      f:row {
        f:static_text {
          title = LOC '$$$/X3GalleryPlugin/Labels/AlbumDate=Date (YYYY-MM-DD)',
          width = share 'collectionset_labelwidth',
        },
        f:edit_field {
          bind_to_object = info.collectionSettings,
          value = bind 'album_date',
          width_in_chars = 60
        }
      },

      f:row {
        f:static_text {
          title = LOC '$$$/X3GalleryPlugin/Labels/AlbumCover=Cover photo',
          width = share 'collectionset_labelwidth',
        },
        f:combo_box {
          bind_to_object = info.collectionSettings,
          immediate = true,
          value = bind 'album_cover',
          items = photoNames
        }
      },

      f:row {
        f:static_text {
          title = LOC '$$$/X3GalleryPlugin/Labels/AlbumHeader=Album header photo',
          width = share 'collectionset_labelwidth',
        },
        f:combo_box {
          bind_to_object = info.collectionSettings,
          immediate = true,
          value = bind 'album_header',
          items = photoNamesWithNoSelection
        }
      }
    }
  }

end

function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
  X3GalleryFtpConnection.uploadPhotos( functionContext, exportContext )
end

return exportServiceProvider
