
test : aeldardin-elm.js
	cucumber

# Depend on all Elm source files -- see http://stackoverflow.com/questions/14289513/makefile-rule-that-depends-on-all-files-under-a-directory-including-within-subd
aeldardin-elm.js : $(shell find elm-src -type f -name '*.elm')
	elm-make --warn elm-src/Aeldardin.elm --output aeldardin-elm.js