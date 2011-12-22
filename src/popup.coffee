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

class Popup

  constructor: ->
    @_findTabId (tabId) =>
      @_initLaptopRadio(tabId)
      @_initAutonodCheckbox(tabId)

  _findTabId: (cb) ->
    re = @_ttRe
    chrome.windows.getAll
      populate: true,
      (windows) ->
        $.each windows, (_, window) ->
          $.each window.tabs, (_, tab) ->
            if re.test(tab.url)
              # console.log("tabId", tab.id)
              cb(tab.id)
              return

  _ttRe: /https?:\/\/[^\/]*turntable\.fm\/.*/i

  _initLaptopRadio: (tabId) ->
    $("input[name=laptop]").click (e) ->
      laptop = $(e.target).val()
      console.log("clicked: #{laptop}")

      chrome.tabs.sendRequest tabId,
        message: "laptop"
        data: laptop,
        (response) ->
          if response.success
            localStorage["laptop"] = response.data
          else
            throw {message: "Error setting laptop", data: r}

    laptop = localStorage["laptop"]
    console.log("initializing popup laptop value: #{laptop}")
    $("#laptop_#{laptop}").attr("checked", true)


  _laptopFromId: (id) ->
    id.replace("laptop_", "")

  _initAutonodCheckbox: (tabId) ->
    autonod = true
    chrome.tabs.sendRequest tabId,
      message: "getAutonod"
      (r) ->
        unless r.success
          throw {message: "Error setting autonod", data: r}
        autonod ||= r.data
        v = if autonod then "checked" else ""
        $("input[name=autonod]").attr("checked", v)

    $("input[name=autonod]").click ->
      value = $(@).is(":checked")
      chrome.tabs.sendRequest tabId,
        message: "autonod"
        data: value,
        (r) ->
          unless r.success
            throw {message: "Error setting autonod", data: r}


$ ->
  new Popup()
