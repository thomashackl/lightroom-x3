--[[----------------------------------------------------------------------------

X3GalleryFtpConnection.lua
FTP related stuff for X3 Photo Gallery publish service

--------------------------------------------------------------------------------

Thomas Hackl
 Copyright 2019 Thomas Hackl
 All Rights Reserved.

------------------------------------------------------------------------------]]

-- Lightroom SDK
local LrFtp = import 'LrFtp'
local LrErrors = import 'LrErrors'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrDialogs = import 'LrDialogs'

X3GalleryFtpConnection = {}

--------------------------------------------------------------------------------

-- Try to establish an (S)FTP connection according to the given preset

function X3GalleryFtpConnection.connectToFtp( ftpPreset )
  local ftpInstance = nil

  if not LrFtp.queryForPasswordIfNeeded( ftpPreset ) then
    return
  end

  ftpInstance = LrFtp.create( ftpPreset, true )

  if not ftpInstance then

    -- This really shouldn't ever happen.
    LrErrors.throwUserError( LOC '$$$/X3GalleryPlugin/Errors/InvalidFtpParameters=The specified FTP preset is incomplete and cannot be used.' )

  end

  return ftpInstance

end

-- Create a directory with the given name on the FTP server

function X3GalleryFtpConnection.mkdir( ftpInstance, name )

  local success = false

  local exists = ftpInstance:exists( name )

  if exists == false then
    success = ftpInstance:makeDirectory( name )

    if not success then

      -- This is a possible situation if permissions don't allow us to create directories.

      LrErrors.throwUserError( LOC '$$$/X3GalleryPlugin/Errors/CannotMakeDirectoryForUpload=Cannot upload because Lightroom could not create the destination directory.' )
    end

  elseif exists == 'file' then

    -- Unlikely, due to the ambiguous way paths for directories get tossed around.

    LrErrors.throwUserError( LOC '$$$/X3GalleryPlugin/Errors/UploadDestinationIsAFile=Cannot upload to a destination that already exists as a file.' )
  elseif exists == 'directory' then

    -- Excellent, it exists, do nothing here.

  else

    -- Not sure if this would every really happen.

    LrErrors.throwUserError( LOC '$$$/X3GalleryPlugin/Errors/CannotCheckForDestination=Unable to upload because Lightroom cannot ascertain if the target destination exists.' )
  end

  return success

end

function X3GalleryFtpConnection.uploadPhotos( ftpInstance, exportContext )

	-- Make a local reference to the export parameters.

	local exportSession = exportContext.exportSession
	local exportParams = exportContext.propertyTable
  local publishedCollectionInfo = exportContext.publishedCollectionInfo

	-- Set progress title.

	local nPhotos = exportSession:countRenditions()

	local progressScope = exportContext:configureProgress {
		title = nPhotos > 1
			   and LOC( '$$$/X3GalleryPlugin/UploadProgress=Uploading ^1 photos via Ftp', nPhotos )
			   or LOC '$$$/X3GalleryPlugin/UploadProgressOne=Uploading one photo via Ftp',
	}

	-- Ensure target directory exists.
  X3GalleryFtpConnection.mkdir( ftpInstance, publishedCollectionInfo.name )

	-- Iterate through photo renditions.

	local failures = {}

	for _, rendition in exportContext:renditions{ stopIfCanceled = true } do

		-- Wait for next photo to render.

		local success, pathOrMessage = rendition:waitForRender()

		-- Check for cancellation again after photo has been rendered.

		if progressScope:isCanceled() then break end

		if success then

			local filename = LrPathUtils.leafName( pathOrMessage )
      local fullPath = publishedCollectionInfo.name .. '/' .. filename

			local success = ftpInstance:putFile( pathOrMessage, fullPath )

			if not success then

				-- If we can't upload that file, log it.  For example, maybe user has exceeded disk
				-- quota, or the file already exists and we don't have permission to overwrite, or
				-- we don't have permission to write to that directory, etc....

				table.insert( failures, filename )

      else

        rendition:recordPublishedPhotoId( fullPath )

			end

			-- When done with photo, delete temp file. There is a cleanup step that happens later,
			-- but this will help manage space in the event of a large upload.

			LrFileUtils.delete( pathOrMessage )

		end

	end

	if #failures > 0 then
		local message
		if #failures == 1 then
			message = LOC '$$$/X3GalleryPlugin/Errors/OneFileFailed=1 file failed to upload correctly.'
		else
			message = LOC ( '$$$/X3GalleryPlugin/Errors/SomeFileFailed=^1 files failed to upload correctly.', #failures )
		end
		LrDialogs.message( message, table.concat( failures, '\n' ) )
	end

end

function X3GalleryFtpConnection.uploadJSONFile( ftpInstance, folderName, config )

  local filename = os.tmpname()
  local file = io.open( filename, 'w' )

  if file then
    file:write( X3GalleryJSON.encode( config ) )
    file:close()
  else
    LrErrors.throwUserError( LOC '$$$/X3GalleryPlugin/Errors/OpenFileError=Unable to open file for album config:' .. filename )
  end

  local fullPath = folderName .. '/page.json'
  local uploadSuccess = ftpInstance:putFile( filename, fullPath )

  if uploadSuccess then

    LrFileUtils.delete( filename )

  else

    LrErrors.throwUserError( LOC '$$$/X3GalleryPlugin/Errors/UploadFileError=Unable to upload file for album config: ' .. filename )

  end

end
