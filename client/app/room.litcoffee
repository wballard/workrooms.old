Control a single Room, including video and chat, running peer to peer.

    room = require './rooms/room.litcoffee'

    angular
      .module('workrooms')
      .controller('Room', ['$scope', '$routeParams', ($scope, $routeParams) ->
        $scope.room = room($scope.sky, $routeParams.roomid)
          .join()
          .on('localvideo', ->
            console.log 'loco'
            $scope.$apply())
          .on('remotevideo', ->
            console.log 'remmy'
            $scope.$apply())

      ])
