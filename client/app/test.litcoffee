Controller to run unit tests. If you hit this, tests will ensue. It's
a bit of a new technique for me at the time of this writing to have a
self test controller, we'll see how it goes.

    require('chai').should()
    rooms = require('./rooms/index.litcoffee')

    angular.module('workrooms')
      .controller('Test', [ '$scope', ($scope) ->
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
              clientARoom.state[clientA.client].should.exist
              clientARoom.state[clientB.client].should.exist
              clientBRoom.state[clientA.client].should.exist
              clientBRoom.state[clientB.client].should.exist
              done()
            , 75

          it "should let you join a PeerGroup", (done) ->

          it "should let multiple members in a PeerGroup", (done) ->

        describe "Peer Groups", ->
          it "should let you send messages to one Peer", (done) ->

          it "should let you send messages to all Peers", (done) ->

        mocha.run()
      ])
