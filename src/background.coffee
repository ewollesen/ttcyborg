###
This file is part of ttcyborg.

ttcyborg is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

ttcyborg is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ttcyborg.  If not, see <http://www.gnu.org/licenses/>.
###

class Background

  constructor: () ->
    chrome.extension.onRequest.addListener(@_handleRequest)

  _handleRequest: (request, sender, sendResponse) =>
    console.log("request received in background.js", request, sender)
    switch request.message
      when "registered"
        console.log("background received registered message")
        localStorage["laptop"] = request.data.laptop
        localStorage["roomId"] = request.data.roomId
        chrome.pageAction.show(sender.tab.id)
        sendResponse
          success: true
      when "newSong"
        console.log("background received newSong message")
        localStorage["songId"] = request.data.songId
        localStorage["roomId"] = request.data.roomId
        sendResponse
          success: true
      else
        console.log("request received in background.js", request, sender)
        sendResponse
          success: false
          message: "Unknown message #{request.message}"


$ ->
  new Background()