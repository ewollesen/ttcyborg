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

`function injector() {
  window.ttcyborg = {
    roomId: null,
    songId: null,

    ttfm: function(c,a){if(c.api=="room.now"){return;}c.msgid=turntable.messageId;turntable.messageId+=1;c.clientid=turntable.clientId;if(turntable.user.id&&!c.userid){c.userid=turntable.user.id;c.userauth=turntable.user.auth;}var d=JSON.stringify(c);if(turntable.socketVerbose){LOG(util.nowStr()+" Preparing message "+d);}var b=$.Deferred();turntable.whenSocketConnected(function(){if(turntable.socketVerbose){LOG(util.nowStr()+" Sending message "+c.msgid+" to "+turntable.socket.host);}if(turntable.socket.transport.type=="websocket"){turntable.socketLog(turntable.socket.transport.sockets[0].id+":<"+c.msgid);}turntable.socket.send(d);turntable.socketKeepAlive(true);turntable.pendingCalls.push({msgid:c.msgid,handler:a,deferred:b,time:util.now()});});return b.promise();},

    vote: function (val, callback) {
      var vh = $.sha1(ttcyborg.roomId + val + ttcyborg.songId);
      var th = $.sha1(Math.random().toString());
      var ph = $.sha1(Math.random().toString());
      var rq = {api: 'room.vote', roomid: ttcyborg.roomId, val: val, vh: vh, th: th, ph: ph};

      ttcyborg.ttfm(rq, callback);
    },

    trackStart: function (msg) {
      var event = document.createEvent("Event");

      ttcyborg.songId = msg.fileId;
      event.initEvent("ttcyborg_trackStart", true, true);
      document.getElementById("ttcyborg").dispatchEvent(event);
    },

    messageReceived: function (msg) {
      switch(msg.command) {
      case "registered":
        ttcyborg.roomId = msg.roomid;
        ttcyborg.laptop = msg.user[0].laptop;
        $("#ttcyborg").attr("data-laptop", ttcyborg.laptop);
        ttcyborg.registered();
        break;
      case "newsong":
        ttcyborg.songId = msg.room.metadata.current_song._id;
        ttcyborg.roomId = msg.roomid;
      /*default:
        if (msg.command) {
          console.log("Unexpected message received: " + msg.command, msg);
        }*/
      }
    },

    registered: function () {
      var event = document.createEvent("Event");

      event.initEvent("ttcyborg_registered", true, true);
      document.getElementById("ttcyborg").dispatchEvent(event);
    }
  };

  turntable.addEventListener("message", window.ttcyborg.messageReceived);
  turntable.addEventListener("trackstart", window.ttcyborg.trackStart);

  var q = $("<div/>")
    .hide()
    .attr("id", "ttcyborg")
    .attr("data-autonod", true)
    .attr("data-laptop", "chrome")
    .on("ttcyborg_trackStart", function (event) {
      var autonod = $(this).attr("data-autonod") == "true" ? true : false;

      if (autonod) {
        ttcyborg.vote("up", function (data) {
          console.log("voted up", data);
        });
      }
    });
  $("body").append(q);
}`


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
  div.bind "ttcyborg_registered", (data) ->
    chrome.extension.sendRequest({message: "pageAction", data: "enable"})

$ ->
  script = $("<script/>").text("(#{injector})();")
  $("head").append(script)
  setupListener()
