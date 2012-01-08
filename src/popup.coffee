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
      @_tabId = tabId
      @_initLaptopRadio()
      @_initAutonodCheckbox()

  _findTabId: (cb) ->
    re = @_ttRe
    chrome.windows.getAll
      populate: true,
      (windows) ->
        $.each windows, (_, window) ->
          $.each window.tabs, (_, tab) ->
            if re.test(tab.url)
              cb(tab.id)
              return

  _ttRe: /https?:\/\/[^\/]*turntable\.fm\/.*/i

  _initLaptopRadio: ->
    $("input[name=laptop]").click(@_laptopClicked)
    laptop = localStorage["laptop"] # Shared with background.js
    console.log("initializing laptop radio in tab #{@_tabId} #{laptop}")
    $("#laptop_#{laptop}").attr("checked", true)

  _laptopClicked: (e) =>
    laptop = $(e.target).val()
    console.log("_laptopClicked: #{laptop}")
    localStorage["laptop"] = laptop # Shared with background.js
    # This is sent to content.js
    chrome.tabs.sendRequest @_tabId,
      message: "laptop"
      data: laptop

  _initAutonodCheckbox: ->
    autonod = localStorage["autonod"] || "false" # Shared with background.js
    console.log("initializing autonod checkbox in tab #{@_tabId} #{autonod}")
    v = if autonod is "true" then "checked" else ""
    $("input#autonod").attr("checked", v)
    $("input#autonod").click(@_autonodClicked)

  _autonodClicked: (e) =>
    autonod = $(e.target).is(":checked")
    localStorage["autonod"] = autonod # Shared with background.js
    console.log("_autonodClicked: #{autonod}")
    # This is sent to content.js
    chrome.tabs.sendRequest @_tabId,
      message: "autonod"
      data: autonod


$ ->
  new Popup()
