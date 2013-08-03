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

        mocha.run()
      ])
