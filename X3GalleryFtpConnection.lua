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
local LrLogger = import 'LrLogger'

local myLogger = LrLogger( 'X3' )
myLogger:enable( 'print' )

X3GalleryFtpConnection = {}

--------------------------------------------------------------------------------

function X3GalleryFtpConnection.uploadPhotos( functionContext, exportContext )

	-- Make a local reference to the export parameters.

	local exportSession = exportContext.exportSession
	local exportParams = exportContext.propertyTable
	local ftpPreset = exportParams.ftpPreset

	-- Set progress title.

	local nPhotos = exportSession:countRenditions()

	local progressScope = exportContext:configureProgress {
						title = nPhotos > 1
							   and LOC( "$$$/X3GalleryFtpConnection/Upload/Progress=Uploading ^1 photos via Ftp", nPhotos )
							   or LOC "$$$/X3GalleryFtpConnection/Upload/Progress/One=Uploading one photo via Ftp",
					}

	-- Create an FTP connection.

	if not LrFtp.queryForPasswordIfNeeded( ftpPreset ) then
		return
	end

	local ftpInstance = LrFtp.create( ftpPreset, true )

	if not ftpInstance then

		-- This really shouldn't ever happen.

		LrErrors.throwUserError( LOC "$$$/X3GalleryFtpConnection/Upload/Errors/InvalidFtpParameters=The specified FTP preset is incomplete and cannot be used." )
	end

	-- Ensure target directory exists.

	local index = 0
	while true do

		local subPath = string.sub( exportParams.fullPath, 0, index )
		ftpInstance.path = subPath

		local exists = ftpInstance:exists( '' )

		if exists == false then
			local success = ftpInstance:makeDirectory( '' )

			if not success then

				-- This is a possible situation if permissions don't allow us to create directories.

				LrErrors.throwUserError( "$$$/X3GalleryFtpConnection/Upload/Errors/CannotMakeDirectoryForUpload=Cannot upload because Lightroom could not create the destination directory." )
			end

		elseif exists == 'file' then

			-- Unlikely, due to the ambiguous way paths for directories get tossed around.

			LrErrors.throwUserError( LOC "$$$/X3GalleryFtpConnection/Upload/Errors/UploadDestinationIsAFile=Cannot upload to a destination that already exists as a file." )
		elseif exists == 'directory' then

			-- Excellent, it exists, do nothing here.

		else

			-- Not sure if this would every really happen.

			LrErrors.throwUserError( LOC "$$$/X3GalleryFtpConnection/Upload/Errors/CannotCheckForDestination=Unable to upload because Lightroom cannot ascertain if the target destination exists." )
		end

		if index == nil then
			break
		end

		index = string.find( exportParams.fullPath, "/", index + 1 )

	end

	ftpInstance.path = exportParams.fullPath

	-- Iterate through photo renditions.

	local failures = {}

	for _, rendition in exportContext:renditions{ stopIfCanceled = true } do

		-- Wait for next photo to render.

		local success, pathOrMessage = rendition:waitForRender()

		-- Check for cancellation again after photo has been rendered.

		if progressScope:isCanceled() then break end

		if success then

			local filename = LrPathUtils.leafName( pathOrMessage )

			local success = ftpInstance:putFile( pathOrMessage, filename )

			if not success then

				-- If we can't upload that file, log it.  For example, maybe user has exceeded disk
				-- quota, or the file already exists and we don't have permission to overwrite, or
				-- we don't have permission to write to that directory, etc....

				table.insert( failures, filename )
			end

			-- When done with photo, delete temp file. There is a cleanup step that happens later,
			-- but this will help manage space in the event of a large upload.

			LrFileUtils.delete( pathOrMessage )

		end

	end

	ftpInstance:disconnect()

	if #failures > 0 then
		local message
		if #failures == 1 then
			message = LOC "$$$/X3GalleryFtpConnection/Upload/Errors/OneFileFailed=1 file failed to upload correctly."
		else
			message = LOC ( "$$$/X3GalleryFtpConnection/Upload/Errors/SomeFileFailed=^1 files failed to upload correctly.", #failures )
		end
		LrDialogs.message( message, table.concat( failures, "\n" ) )
	end

end
