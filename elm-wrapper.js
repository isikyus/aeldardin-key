// File: to_graphviz.js
//
// Code to convert an Aeldardin key into a .dot graph file.

define([
    'aeldardin-elm'
  ],
function (Elm) {

  var worker = Elm.Aeldardin.worker();

  // Invoke the elm port <port> on the given <data>,
  // and pass the resulting text into <callback>
  return function(port, data, callback) {

    var callCallbackOnce = function(text) {
      callback(text)
      worker.ports.done.unsubscribe(callCallbackOnce);
    };

    worker.ports.done.subscribe(callCallbackOnce);

    // Send Elm JSON rather than a full JS object, so we can re-parse in Elm
    // to extract only the things we know how to handle.
    // Would be better to send the YAML to Elm directly, but Elm can't parse YAML yet (https://groups.google.com/forum/#!topic/elm-discuss/s8dy6zlQaYM)
    // TODO: should send JS objects rather than re-encoding and decoding.
    worker.ports[port].send(JSON.stringify(data));
  };
});
