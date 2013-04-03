---------------------------------------------------------------------------
-- @author Alexander Yakushev <yakushev.alex@gmail.com>
-- @copyright 2011 Alexander Yakushev
-- @release v1.1.5
---------------------------------------------------------------------------

-- Grab environment
local os = os
local awful = awful
local string = string
local table = table
local io = io
local pairs = pairs
local type = type
local assert = assert
local print = print
local tonumber = tonumber
local math = math
local tostring = tostring
local asyncshell = asyncshell

module('spotify')

-- UTILITY STUFF
-- Checks whether file specified by filename exists.
local function file_exists(filename, mode)
   mode = mode or 'r'
   f = io.open(filename, mode)
   if f then
      f:close()
      return true
   else
      return false
   end
end


-- Local variables
local album_covers_folder = awful.util.getdir("cache") .. "/spotify_covers/"


-- Returns a filename of the album cover and formed wget request that
-- downloads the album cover for the given track name. If the album
-- cover already exists returns nil as the second argument.
function fetch_album_cover_request(track_id)

   local file_path = album_covers_folder .. track_id .. ".jpg"

   if not file_exists(file_path) then -- We need to download it  
      -- First check if cache directory exists
      f = io.popen('test -d ' .. album_covers_folder .. ' && echo t')
      if f:read("*line") ~= 't' then
         awful.util.spawn("mkdir " .. album_covers_folder)
      end
      f:close()
      
      f = io.popen(string.format("curl http://open.spotify.com/track/%s", track_id))
      if not f then return nil,nil end
      result = f:read("*all")
      if not result then return nil,nil end
      i, j, cover = result:find("<meta property=\"og:image\" content=\"(.-)\"")
      f:close()

      if cover then
        return file_path, string.format("wget %s -O %s 2> /dev/null",
                                      cover, file_path)
      else
        return nil,nil
      end
   else -- Cover already downloaded, return its filename and nil
      return file_path, nil
   end
end

-- Returns a file containing an album cover for given track id.  First
-- searches in the cache folder. If file is not there, fetches it from
-- the Internet and saves into the cache folder.
function get_album_cover(track_id)
   local file_path, fetch_req = fetch_album_cover_request(track_id)
   if fetch_req then
      local f = io.popen(fetch_req)
      f:close()

      -- Let's check if file is finally there, just in case
      if not file_exists(file_path) then
         return nil
      end
   end
   return file_path
end

-- Same as get_album_cover, but downloads (if necessary) the cover
-- asynchronously.
function get_album_cover_async(track_id)
   local file_path, fetch_req = fetch_album_cover_request(track_id)
   if fetch_req then
      asyncshell.request(fetch_req)
   end
end

-- Checks if track_name is actually a link to Jamendo stream. If true
-- returns the file with album cover for the track.
function try_get_cover(track_name)
   if track_name:match('spotify:track:') then
      return get_album_cover(track_name:sub(15,-1))
   end
end

-- Same as try_get_cover, but calls get_album_cover_async inside.
function try_get_cover_async(track_name)
   if track_name:match('spotify:track:') then
      return get_album_cover_async(track_name:sub(15,-1))
   end
end




