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

laptopFromId = (id) ->
  id.replace("laptop_", "")

re = /https?:\/\/[^\/]*turntable\.fm\/.*/i

ttfmTabId = (cb) ->
  chrome.windows.getAll
    populate: true,
    (windows) ->
      $.each windows, (_, window) ->
        $.each window.tabs, (_, tab) ->
          if re.test(tab.url)
            console.log("tabId", tab.id)
            cb(tab.id)
            return

initLaptopRadio = (tabId) ->
  chrome.tabs.sendRequest tabId,
    message: "getLaptop"
    (r) ->
      unless r.success
        throw {message: "Error getting laptop", data: r}
      $("#laptop_#{r.data}").attr("checked", true)

  $("input[name=laptop]").click ->
    chrome.tabs.sendRequest tabId,
      message: "laptop"
      data: laptopFromId(@.id),
      (r) ->
        unless r.success
          throw {message: "Error setting laptop", data: r}

initAutonod = (tabId) ->
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
  ttfmTabId (tabId) ->
    initLaptopRadio(tabId)
    initAutonod(tabId)
