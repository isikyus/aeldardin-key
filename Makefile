
test : aeldardin-elm.js
	cucumber

aeldardin-elm.js : elm-src/*.elm
	elm-make elm-src/Aeldardin.elm --output aeldardin-elm.js