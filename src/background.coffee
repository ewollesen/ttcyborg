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

  _handleRequest: (request, sender, sendResponse) ->
    console.log("background received #{request.message} message")
    switch request.message
      when "registered"
        chrome.pageAction.show(sender.tab.id)
        # Content.js sends the user's "real" laptop value, which we use here
        # as a default. This localStorage is shared with popup.js, and so can
        # be used to initialize the laptop selection input there.
        localStorage["laptop"] ||= request.data.laptop
        console.log("background ls laptop is #{localStorage["laptop"]}")
        sendResponse
          success: true
      # when "newSong"
      #   sendResponse
      #     success: true
      else
        console.log("request", request)
        console.log("sender", sender)
        sendResponse
          success: false
          message: "Unknown message #{request.message}"


$ ->
  new Background()