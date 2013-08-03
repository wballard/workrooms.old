console.log('hi');
path = require('path');

//angular and jquery, get these up here
$ = jQuery = require('../bower_components/jquery/jquery');
require('../bower_components/angular/angular');
//shim to appease slickgrid that uses old style browser detection
//this essentially says 'false' to it
$.browser = {}

//good to go with required libraries and jquery bits, now fire it up
require('./app/main.litcoffee');
