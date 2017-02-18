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

    worker.ports.toDot.send(data.title);
  };
});