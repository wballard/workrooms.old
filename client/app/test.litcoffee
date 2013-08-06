Controller to run unit tests. If you hit this, tests will ensue. It's
a bit of a new technique for me at the time of this writing to have a
self test controller, we'll see how it goes.

    require('chai').should()
    rooms = require('./rooms/index.litcoffee')

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
            clientARoom = new rooms.Room(clientA, roomName)
            clientBRoom = new rooms.Room(clientB, roomName)
            done()

          after (done) ->
            client.close done

          it "let you quickly join", (done) ->
            clientARoom.join()
            clientBRoom.join()
            setTimeout ->
              clientARoom.state.clients[clientA.client].should.exist
              clientARoom.state.clients[clientB.client].should.exist
              clientBRoom.state.clients[clientA.client].should.exist
              clientBRoom.state.clients[clientB.client].should.exist
              done()
            , 75

          it "let you set up peer-peer data channels", (done) ->
            pa = $q.defer()
            pb = $q.defer()
            $q.all(pa.promise, pb.promise).then done
            #here are messages back and forth to one another
            #each room instance sending its own identity
            clientARoom.send 'topic', 'A'
            clientBRoom.send 'topic', 'B'
            #and each room instance hearing the other's message over
            #peer to peer connectivity
            clientARoom.on 'topic', (message) ->
              if message is 'B'
                pa.resolve()
            clientBRoom.on 'topic', (message) ->
              if message is 'A'
                pb.resolve()

        mocha.run()
      ])
