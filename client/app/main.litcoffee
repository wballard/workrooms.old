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
        ])

    require './loading.litcoffee'
    require './conference.litcoffee'
    require './application.litcoffee'

    console.log 'starting'

