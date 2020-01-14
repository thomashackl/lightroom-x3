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
function X3GalleryJSON.encode( data, indent )
  if not indent then
    indent = ''
  end

  local encoded = ''

  if type( data ) == 'table' then

    encoded = encoded..indent..'{\n'

    -- There seems to be no other way to count table entries than to
    -- iterate over the whole table and use a counter variable :/
    local counter = 0
    for index, value in pairs( data ) do
      counter = counter + 1
    end

    local secondCounter = 1
    for index, value in pairs( data ) do
      encoded = encoded..indent..'  "'..index..'": '..X3GalleryJSON.encode(value, indent..'  ')

      if secondCounter < counter then
        encoded = encoded..','
      end
      encoded = encoded..'\n'

      secondCounter = secondCounter + 1
    end

    encoded = encoded..indent..'}'

  else

    encoded = '"'..data..'"'

  end

  return encoded
end
