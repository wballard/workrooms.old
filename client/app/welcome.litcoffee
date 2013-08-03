Controller for the Welcome page. Howdy!

    angular.module('workrooms')
      .controller('Welcome', [ '$scope', 'conference', ($scope, conference) ->
        conference.start()
      ])
