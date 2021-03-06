
test : elm-test cucumber

cucumber : aeldardin-elm.js features/*.feature features/support/*.rb
	cucumber

clean :
	rm -rf node_modules/* elm-stuff/*

# Depend on all Elm source files -- see http://stackoverflow.com/questions/14289513/makefile-rule-that-depends-on-all-files-under-a-directory-including-within-subd
ELM_SOURCES=$(shell find elm-src -type f -name '*.elm')
ELM_TEST_SOURCES=$(shell find tests -type f -name '*.elm')

aeldardin-elm.js : ${ELM_SOURCES} elm-stuff/packages elm-server-side-renderer/modify-natives node_modules/.bin/elm-make
	node node_modules/.bin/elm-make --yes --warn elm-src/Aeldardin.elm --output aeldardin-elm.js

elm-stuff/packages : node_modules/.bin/elm-package
	node node_modules/.bin/elm-package install -y

node_modules/.bin/elm-make : node-install
node_modules/.bin/elm-package : node-install
node_modules/.bin/elm-test : node-install

node-install :
	npm install

# Per the Elm FAQ (http://faq.elm-community.org/#how-do-i-install-an-elm-package-that-has-not-been-published-to-packageselm-langorg-for-use-in-my-project),
# non-published packages with native modules need variables renamed.
elm-server-side-renderer/modify-natives : elm-server-side-renderer/elm-package.json
	sed -i\\~ -e 's/_eeue56\$$elm_server_side_renderer\$$/_user\$$project\$$/' elm-server-side-renderer/src/Native/ServerSideHelpers.js

elm-server-side-renderer/elm-package.json : .gitmodules .git/config
	git submodule update --init

# Apparently elm-make path has to be relative to the _test_ directory, not project root
elm-test : ${ELM_SOURCES} ${ELM_TEST_SOURCES} tests/elm-package.json elm-server-side-renderer/modify-natives \
		node_modules/.bin/elm-test node_modules/.bin/elm-make
	node node_modules/.bin/elm-test --compiler node_modules/.bin/elm-make

tests/elm-package.json : elm-package.json tests/elm-package-template.json update-test-dependencies.js
	node update-test-dependencies.js
