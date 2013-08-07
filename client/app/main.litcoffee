Start the single page application client code here. Count on bower pacakges
already being loaded.


Set up routing for the application here.

    angular
        .module('workrooms', ['gadgets'])
        .run(['$rootScope', '$location', ($rootScope, $location) ->
          console.log 'application running'
        ])
        .config(['$routeProvider', ($routeProvider) ->
            $routeProvider
                .when(
                    '/'
                    templateUrl: '/views/welcome.html'
                )
                .when(
                    '/rooms/:roomid'
                    templateUrl: '/views/room.html'
                )
                .when(
                    '/test'
                    templateUrl: '/views/test/index.html'
                )
        ])

    require './loading.litcoffee'
    require './video.litcoffee'
    require './room.litcoffee'
    require './application.litcoffee'
    require './welcome.litcoffee'
    require './test.litcoffee'

