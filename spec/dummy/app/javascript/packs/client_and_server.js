//app/javascript/packs/client_and_server.js
// these packages will be loaded both during prerendering and on the client
React = require('react');                         // react-js library
createReactClass = require('create-react-class'); // backwards compatibility with ECMA5
History = require('history');                     // react-router history library
ReactRouter = require('react-router');            // react-router js library
ReactRouterDOM = require('react-router-dom');     // react-router DOM interface
ReactRailsUJS = require('react_ujs');             // interface to react-rails
// to add additional NPM packages run `yarn add package-name@version`
// then add the require here.
Trix = require( 'trix');
TrixEditor = require('react-trix');

SunEditor = require("suneditor-react");
buttonList = require("suneditor-react").buttonList;

