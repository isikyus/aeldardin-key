/* File: update-test-dependencies.js
 *
 * Reads main project dependencies,
 * and copies them into the test elm-package.json
 *
 */

var fs = require('fs');

// Generic function to load a JSON file (does this already exist?)
var loadUTF8Json = function(filename) {
  var jsonString = fs.readFileSync(filename, 'utf8');
  return JSON.parse(jsonString);
};

// Load the main-project package details from elm-package.json
var mainPackage = loadUTF8Json('elm-package.json');
var mainDeps = mainPackage.dependencies;

// Load the template elm-package file for tests,
// containing only test dependencies
// (so we can tell which dependencies are for the tests themselves).
var testPackage = loadUTF8Json('tests/elm-package-template.json');

// Update the test dependencies to be those of the main project.
for (dependency in mainPackage.dependencies) {
  testPackage.dependencies[dependency] = mainDeps[dependency];
};

// Stringify with four-space indentation, to preserve the existing format
// as much as possible.
var newTestPackageJson = JSON.stringify(testPackage, null, '    ');

// The existing file ends with a newline; respect that.
newTestPackageJson = newTestPackageJson + '\n';

// Make combined package file available so tests can be run.
fs.writeFileSync('tests/elm-package.json',
                 newTestPackageJson,
                 { encoding: 'utf8' });
