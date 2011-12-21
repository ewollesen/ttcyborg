# This file is part of ttcyborg.

# ttcyborg is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ttcyborg is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ttcyborg.  If not, see <http://www.gnu.org/licenses/>.

all: ttcyborg \
     ttcyborg/content.js \
     ttcyborg/popup.js \
     ttcyborg/background.js \
     ttcyborg/jquery.js \
     ttcyborg/background.html \
     ttcyborg/popup.html \
     ttcyborg/manifest.json \
     ttcyborg/icon.ico

package: package-prep all

ttcyborg:
	-mkdir ttcyborg

package-prep: ttcyborg ttcyborg/README ttcyborg/COPYING

ttcyborg/icon.ico: assets/icon.ico
	cp $< $@

ttcyborg/manifest.json: src/manifest.json
	cp $< $@

ttcyborg/%.html: src/%.haml
	haml --stdin < $< > $@ 

ttcyborg/jquery.js: vendor/jquery.js
	cp $< $@

ttcyborg/%.js: src/%.coffee
	coffee --stdio --bare --compile --print < $< > $@

ttcyborg/README: README
	cp $< $@

ttcyborg/COPYING: COPYING
	cp $< $@

