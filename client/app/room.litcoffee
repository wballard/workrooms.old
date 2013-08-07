Control a single Room, including video and chat, running peer to peer.

    Room = require './rooms/room.litcoffee'

    angular
      .module('workrooms')
      .controller('Room', ['$scope', '$routeParams', ($scope, $routeParams) ->
        $scope.room = new Room($scope.sky, $routeParams.roomid)
          .join()
          .on('localvideo', -> $scope.$apply())
          .on('remotevideo', -> $scope.$apply())

      ])
