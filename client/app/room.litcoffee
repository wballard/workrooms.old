Control a single Room, including video and chat, running peer to peer.

    room = require './rooms/room.litcoffee'

    angular
      .module('workrooms')
      .controller('Room', ['$scope', '$routeParams', ($scope, $routeParams) ->
        $scope.room = room($scope.sky, $routeParams.roomid)
        $scope.room.on 'localState', ->
            $scope.$apply()
        $scope.room.on 'client', (client)->
            $scope.$apply ->
              $scope.client = client
        $scope.room.on 'synch', (allVideos) ->
            console.log 'synch!'
            $scope.$apply ->
              $scope.localVideo = allVideos[$scope.client]
              delete allVideos[$scope.client]
              $scope.removeVideos = allVideos
        $scope.sky
          .linkToAngular($scope.room.clientLinkPath, $scope, 'me')
          .autoRemove()
      ])
