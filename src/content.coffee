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

injector = ->
  window.ttcyborg =
    roomId: null
    songId: null
    ttfm: (c, a) ->
      return  if c.api is "room.now"
      c.msgid = turntable.messageId
      turntable.messageId += 1
      c.clientid = turntable.clientId
      if turntable.user.id and not c.userid
        c.userid = turntable.user.id
        c.userauth = turntable.user.auth
      d = JSON.stringify(c)
      LOG util.nowStr() + " Preparing message " + d  if turntable.socketVerbose
      b = $.Deferred()
      turntable.whenSocketConnected ->
        LOG util.nowStr() + " Sending message " + c.msgid + " to " + turntable.socket.host  if turntable.socketVerbose
        turntable.socketLog turntable.socket.transport.sockets[0].id + ":<" + c.msgid  if turntable.socket.transport.type is "websocket"
        turntable.socket.send d
        turntable.socketKeepAlive true
        turntable.pendingCalls.push
          msgid: c.msgid
          handler: a
          deferred: b
          time: util.now()

      b.promise()

    vote: (val, callback) ->
      console.log("voting #{val}")
      vh = $.sha1(ttcyborg.roomId + val + ttcyborg.songId)
      th = $.sha1(Math.random().toString())
      ph = $.sha1(Math.random().toString())
      rq =
        api: "room.vote"
        roomid: ttcyborg.roomId
        val: val
        vh: vh
        th: th
        ph: ph

      ttcyborg.ttfm rq, callback

    # Called by a listener attached to the window's turntable object.
    trackStart: (msg) ->
      event = document.createEvent("Event")
      ttcyborg.songId = msg.fileId
      event.initEvent "trackStart", true, true
      document.getElementById("ttcyborg").dispatchEvent event
      console.log("content (inner) autonod value is #{localStorage["autonod"]}")
      if "true" is localStorage["autonod"]
        ttcyborg.vote("up")


    messageReceived: (msg) ->
      console.log "content (inner) received event #{msg.command}", msg if msg.command
      switch msg.command
        when "registered"
          ttcyborg._registered(msg)
        when "newsong"
          ttcyborg._newSong(msg)

      true

    _registered: (msg) ->
      ttcyborg.roomId = msg.roomid
      # The laptop is included in this message, which we will communicate to
      # content.js via a data-* attribute so that it can in turn be passed on
      # to popup.js as a default in the event that the user has not yet
      # selected a laptop.
      $("#ttcyborg").attr("data-laptop", msg.user[0].laptop)
      ttcyborg._triggerEvent("registered")

    _newSong: (msg) ->
      ttcyborg.roomId = msg.roomid
      ttcyborg.songId = msg.room.metadata.current_song._id
      ttcyborg._triggerEvent("newSong")

    _triggerEvent: (name) ->
      console.log "content (inner) triggering #{name} event"
      event = document.createEvent("Event")
      event.initEvent name, true, true
      # These events are received by content (outer) via the #ttcyborg div.
      document.getElementById("ttcyborg").dispatchEvent event


  turntable.addEventListener "message", window.ttcyborg.messageReceived
  turntable.addEventListener "trackstart", window.ttcyborg.trackStart

  q = $("<div/>")
    .hide()
    .attr("id", "ttcyborg")
  $("body").append q


assignLaptop = (laptop) ->
  localStorage["laptop"] = laptop
  setLaptop()

assignAutonod = (autonod) ->
  localStorage["autonod"] = autonod

setLaptop = ->
  laptop = localStorage["laptop"]
  console.log("content (outer) setLaptop #{laptop}")
  js = """
ttcyborg.ttfm({api: "user.modify", laptop: "#{laptop}"}, function (data) {
  if (data.success) {
    console.log("ttfm reports success setting laptop to #{laptop}");
  } else {
    console.log("ttfm reports error setting laptop to #{laptop}", data);
  }
});
"""
  script = $("<script/>").text(js)
  $("head").append(script)


setupListener = () ->
  div = $("#ttcyborg")

  div.bind "registered", ->
    console.log("content (outer) received registered message")
    twoPointOneSeconds = 2100

    # This message is sent to background.js
    chrome.extension.sendRequest
      message: "registered"
      data:
        # This value is received by content (inner) upon registration, and is
        # used as a default in the event that the user has not yet selected a
        # laptop.
        laptop: $("#ttcyborg").attr("data-laptop")

    # It is necessary to set the laptop here, because tt.fm client-side code
    # waits two seconds before firing off a setLaptop of their own.
    setTimeout () ->
      setLaptop()
    , twoPointOneSeconds

  # This receives messages from popup.js
  chrome.extension.onRequest.addListener (request, sender, sendResponse) ->
    try
      switch request.message
        when "laptop"
          assignLaptop request.data
          sendResponse
            success: true
        when "autonod"
          assignAutonod request.data
          sendResponse
            success: true
    catch e
      sendResponse
        success: false
        data: e


$ ->
  script = $("<script/>").text("(#{injector})();")
  $("head").append(script)
  setupListener()
