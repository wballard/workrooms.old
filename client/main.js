console.log('hi');
path = require('path');

require('../bower_components/angular/angular');
$ = jQuery = require('../bower_components/jquery/jquery');
//shim to appease slickgrid that uses old style browser detection
//this essentially says 'false' to it
$.browser = {}

//good to go with required libraries and jquery bits, now fire it up
require('./app/main.litcoffee');
