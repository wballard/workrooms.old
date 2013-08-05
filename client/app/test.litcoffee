Controller to run unit tests. If you hit this, tests will ensue. It's
a bit of a new technique for me at the time of this writing to have a
self test controller, we'll see how it goes.

    require('chai').should()

    angular.module('workrooms')
      .controller('Test', [ '$scope', ($scope) ->
        mocha.setup('bdd')

        describe "Client", ->
          it "should be running tests", (done) ->
            done()

        describe "Peers", ->
          it "should let you identify yourself as a Peer", (done) ->

          it "should let you join a PeerGroup", (done) ->

          it "should let multiple members in a PeerGroup", (done) ->

        describe "Peer Groups", ->
          it "should let you send messages to one Peer", (done) ->

          it "should let you send messages to all Peers", (done) ->

        mocha.run()
      ])
