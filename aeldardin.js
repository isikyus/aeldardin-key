// File: aeldardin.js
//
// Script to process an Aeldardin-Key YAML file as directed by its options.

var showUsage = function() {
  var command = process.argv0 + ' ' + process.argv[1];
  console.warn('Usage:')
  console.warn('  ' + command + ' <subcommand> [file]')

  // TODO: generate list of allowed subcommands.
}

var convertToDot = function(input) {
  console.warn('TODO: not yet implemented');
};

// Wrap everything in a function for scoping
var run = function() {

  // Parse command line arguments.
  // Ignore the first two arguments ('node' and filename -- see http://stackoverflow.com/questions/4351521/how-do-i-pass-command-line-arguments)
  var args = process.argv.slice(2),
      subcommand = args[0],
      filename = args[1];

  // Call an appropriate operation for the command given.
  switch(subcommand) {

    case 'dot':
      convertToDot(input);
      break;

    default:
      console.warn('Unrecognised subcommand ' + subcommand);
      showUsage();
  }
};

run();