
test : elm-test cucumber

cucumber : aeldardin-elm.js features/*.feature features/support/*.rb
	cucumber

# Depend on all Elm source files -- see http://stackoverflow.com/questions/14289513/makefile-rule-that-depends-on-all-files-under-a-directory-including-within-subd
ELM_SOURCES=$(shell find elm-src -type f -name '*.elm')
ELM_TEST_SOURCES=$(shell find tests -type f -name '*.elm')

aeldardin-elm.js : ${ELM_SOURCES}
	elm-make --warn elm-src/Aeldardin.elm --output aeldardin-elm.js

elm-test : ${ELM_SOURCES} ${ELM_TEST_SOURCES} tests/elm-package.json
	node node_modules/.bin/elm-test

tests/elm-package.json : elm-package.json tests/elm-package-template.json
	node update-test-dependencies.js
	cd tests && node ../node_modules/.bin/elm-package install -y