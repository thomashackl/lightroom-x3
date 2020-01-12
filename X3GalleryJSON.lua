--[[----------------------------------------------------------------------------

X3GalleryJSON.lua
Handling of JSON files for X3 photo gallery

--------------------------------------------------------------------------------

Thomas Hackl
 Copyright 2019
 All Rights Reserved.

------------------------------------------------------------------------------]]

-- Lightroom SDK
local LrFileUtils = import 'LrFileUtils'

X3GalleryJSON = {}

--------------------------------------------------------------------------------

-- Encode a value into a JSON string
function X3GalleryJSON.encode( value, indent )
  local encoded = ''

  if type( value ) == 'table' then

    for index, entry in ipairs(value) do

      encoded = encoded..indent..'{"'..index..'":\n'..indent..'  {\n'..X3GalleryJSON.encode( entry, indent..'  ' )..'\n'..indent..'}\n'..indent..'}'

    end

  else

    encoded = indent..value

  end

  return encoded
end
