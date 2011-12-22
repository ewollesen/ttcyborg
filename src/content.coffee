###
This file is part of ttcyborg.

ttcyborg is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
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

    trackStart: (msg) ->
      event = document.createEvent("Event")
      ttcyborg.songId = msg.fileId
      event.initEvent "ttcyborg_trackStart", true, true
      document.getElementById("ttcyborg").dispatchEvent event

    messageReceived: (msg) ->
      console.log "content (inner) received event", msg if msg.command

      switch msg.command
        when "registered"
          ttcyborg._registered(msg)
        when "newsong"
          ttcyborg._newSong(msg)

      true

    _registered: (msg) ->
      roomId = msg.roomid
      laptop = msg.user[0].laptop

      ttcyborg.roomId = roomId
      ttcyborg.laptop = laptop
      $("#ttcyborg").attr("data-laptop", laptop)
      $("#ttcyborg").attr("data-roomId", roomId)
      ttcyborg._triggerEvent("registered")

    _newSong: (msg) ->
      roomId = msg.roomid
      songId = msg.room.metadata.current_song._id

      ttcyborg.songId = songId
      ttcyborg.roomId = roomId
      $("#ttcyborg").attr("data-songId", songId)
      $("#ttcyborg").attr("data-roomId", roomId)
      ttcyborg._triggerEvent("newSong")

    _triggerEvent: (name) ->
      console.log "content (inner) triggering #{name} event"
      event = document.createEvent("Event")
      event.initEvent name, true, true
      document.getElementById("ttcyborg").dispatchEvent event


  turntable.addEventListener "message", window.ttcyborg.messageReceived
  turntable.addEventListener "trackstart", window.ttcyborg.trackStart
  q = $("<div/>").hide().attr("id", "ttcyborg").attr("data-autonod", true).attr("data-laptop", "chrome").on("ttcyborg_trackStart", (event) ->
    autonod = (if $(this).attr("data-autonod") is "true" then true else false)
    if autonod
      ttcyborg.vote "up", (data) ->
        console.log "voted up", data
  )
  $("body").append q

setupListener = () ->
  div = $("#ttcyborg")
  chrome.extension.onRequest.addListener (request, sender, sendResponse) ->
    try
      switch request.message
        when "laptop"
          js = """ttcyborg.ttfm({api: "user.modify", laptop: "#{request.data}"}, function (data) {console.log("ttfm responds", data); sendResponse({})});"""
          script = $("<script/>").text(js)
          $("head").append(script)
          sendResponse
            success: true
            message: "laptop: #{request.data}"
        when "autonod"
          console.log("content autonod ", request.data)
          div.attr("data-autonod", request.data)
          sendResponse
            success: true
            message: "autonod: #{request.data}"
        when "getAutonod"
          console.log "getAutonod", div.attr("data-autonod")
          sendResponse
            success: true
            data: div.attr("data-autonod")
            message: "getAutonod"
        when "getLaptop"
          console.log "content getLaptop", div.attr("data-laptop")
          sendResponse
            success: true
            data: div.attr("data-laptop")
            message: "getLaptop"
    catch e
      sendResponse
        success: false
        data: e
  div.bind "registered", ->
    console.log("content (outer) received registered message")
    laptop = $("#ttcyborg").attr("data-laptop")
    roomId = $("#ttcyborg").attr("data-roomId")

    chrome.extension.sendRequest
      message: "registered"
      data:
        roomId: roomId
        laptop: laptop

  div.bind "newSong", ->
    console.log("content (outer) received newSong message")
    songId = $("#ttcyborg").attr("data-songId")
    roomId = $("#ttcyborg").attr("data-roomId")

    chrome.extension.sendRequest
      message: "newSong"
      data:
        roomId: roomId
        songId: songId


$ ->
  script = $("<script/>").text("(#{injector})();")
  $("head").append(script)
  setupListener()
