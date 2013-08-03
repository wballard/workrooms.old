Start the single page application client code here. Count on bower pacakges
already being loaded.


Set up routing for the application here.

    angular
        .module('workrooms', ['gadgets'])
        .run(['$rootScope', '$location', ($rootScope, $location) ->
        ])
        .config(['$routeProvider', ($routeProvider) ->
            $routeProvider
                .when(
                    '/'
                    templateUrl: '/views/welcome.html'
                )
                .when(
                    '/test'
                    templateUrl: '/views/test/index.html'
                )
        ])

    require './loading.litcoffee'
    require './conference.litcoffee'
    require './application.litcoffee'
    require './welcome.litcoffee'
    require './test.litcoffee'

    console.log 'starting'

