
test : aeldardin-elm.js
	cucumber

aeldardin-elm.js : aeldardin.elm
	elm-make aeldardin.elm --output aeldardin-elm.js