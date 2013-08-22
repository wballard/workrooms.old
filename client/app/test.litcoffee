Controller to run unit tests. If you hit this, tests will ensue. It's
a bit of a new technique for me at the time of this writing to have a
self test controller, we'll see how it goes.

    require('chai').should()
    room = require('./rooms/room.litcoffee')
    attachMediaStream = require('attachmediastream')

    angular.module('workrooms')
      .controller('Test', [ '$scope', '$q', ($scope, $q) ->
        mocha.setup('bdd')

        describe "Client", ->
          it "should be running tests", (done) ->
            done()

        describe "Rooms", ->
          clientA = clientB = clientARoom = clientBRoom = null
          before (done) ->
            clientA = variablesky.connect()
            clientB = variablesky.connect()
            roomName = Date.now()
            window.clientARoom = clientARoom = room(clientA, roomName)
            window.clientBRoom = clientBRoom = room(clientB, roomName)
            #using angular q, note the $apply
            ajoin = $q.defer()
            bjoin = $q.defer()
            clientARoom.on 'join', (client) ->
              if client is clientB.client
                ajoin.resolve()
                $scope.$apply()
            clientBRoom.on 'join', (client) ->
              if client is clientA.client
                bjoin.resolve()
                $scope.$apply()
            avideo = $q.defer()
            bvideo = $q.defer()
            clientARoom.on 'synch', (streams) ->
              if streams[clientARoom.client]
                  attachMediaStream streams[clientARoom.client], document.getElementById('peerA'), {autoplay: true, muted: true}
              if streams[clientBRoom.client]
                  attachMediaStream streams[clientBRoom.client], document.getElementById('peerARemote'), {autoplay: true, muted: true}
              avideo.resolve()
              $scope.$apply()
            clientBRoom.on 'synch', (streams) ->
              if streams[clientARoom.client]
                  attachMediaStream streams[clientARoom.client], document.getElementById('peerBRemote'), {autoplay: true, muted: true}
              if streams[clientBRoom.client]
                  attachMediaStream streams[clientBRoom.client], document.getElementById('peerB'), {autoplay: true, muted: true}
              bvideo.resolve()
              $scope.$apply()
            $q.all([ajoin.promise, bjoin.promise, avideo.promise, bvideo.promise]).then -> done()

          after (done) ->
            #going to leave the client connections open on purpose
            #so I can manually poke and simulate connection failure
            done()

          it "lets you set up peer-peer data channels", (done) ->
            pa = $q.defer()
            pb = $q.defer()
            $q.all(pa.promise, pb.promise).then -> done()
            #and each room instance hearing the other's message over
            #peer to peer connectivity
            clientARoom.on 'topic', (message) ->
              if message is 'B'
                pa.resolve()
                $scope.$apply()
            clientBRoom.on 'topic', (message) ->
              if message is 'A'
                pb.resolve()
                $scope.$apply()
            #here are messages back and forth to one another
            #each room instance sending its own identity
            clientARoom.write
              topic: 'topic'
              message: 'A'
            clientBRoom.write
              topic: 'topic'
              message: 'B'

        mocha.run()
      ])
