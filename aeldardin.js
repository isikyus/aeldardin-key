// File: aeldardin.js
//
// Script to process an Aeldardin-Key YAML file as directed by its options.

// Using require.js so I can share modules with Aeldardin Rooms in future.
// This code is from the require.js docs (http://requirejs.org/docs/node.html)
var requirejs = require('requirejs');

requirejs.config({
    //Pass the top-level main.js/index.js require
    //function to requirejs so that node modules
    //are loaded relative to the top-level JS file.
    nodeRequire: require
});

requirejs([
    'js-yaml',
    'fs', // TODO: do I actually need this?
    'elm-wrapper',
  ],
function (yaml, fs, elmWrapper) {

  var showUsage = function() {
    var command = process.argv0 + ' ' + process.argv[1];
    console.warn('Usage:')
    console.warn('  ' + command + ' <subcommand> [file]')

    // TODO: generate list of allowed subcommands.
  }

  // Load a key from the given file, and pass it to the callback.
  var loadKeyFromFile = function(filename, callback) {
    fs.readFile(filename, 'utf8', function(err, data) {

      var data;

      if (err) {
        throw err
      } else {

        try {
          callback(yaml.safeLoad(data));

        } catch(e) {
          if (e instanceof yaml.YAMLException) {
            // TODO: should I pass the exception to the callback instead?
            console.error('Error loading YAML from "' + filename + '"');
            console.error(e.message);
          } else {

            // Don't try to handle any other kind of exception.
            throw e;
          }
        }
      }
    });
  };

  // Parse command line arguments.
  // Ignore the first two arguments ('node' and filename -- see http://stackoverflow.com/questions/4351521/how-do-i-pass-command-line-arguments)
  var args = process.argv.slice(2),
      subcommand = args[0],
      filename = args[1];

  // Call an appropriate operation for the command given.
  switch(subcommand) {

    case 'gv':
      loadKeyFromFile(filename, function(data) {
        elmWrapper('toGraphviz', data, console.log);
      });
      break;

    case 'html':
      loadKeyFromFile(filename, function(data) {
        elmWrapper('toHtml', data, console.log);
      });
      break;

    default:
      console.error('Unrecognised subcommand ' + subcommand);
      showUsage();
  }

});
