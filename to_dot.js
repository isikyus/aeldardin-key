// File: to_dot.js
//
// Code to convert an Aeldardin key into a .dot graph file.

define([
    'aeldardin-elm'
  ],
function (Elm) {

  var worker = Elm.Aeldardin.worker();

  return function(data) {

    // Print the next block of text the Elm code gives us.
    var printOnce = function(text) {
      console.log(text);
      worker.ports.done.unsubscribe(printOnce);
    };
    worker.ports.done.subscribe(printOnce);

    // Send Elm JSON rather than a full JS object, so we can re-parse in Elm
    // to extract only the things we know how to handle.
    // TODO: would be better to send the YAML to Elm directly, but Elm can't parse YAML yet (https://groups.google.com/forum/#!topic/elm-discuss/s8dy6zlQaYM)
    worker.ports.toDot.send(JSON.stringify(data));
  };
});