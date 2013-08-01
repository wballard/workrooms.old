This is the root most controller.

    angular.module('workrooms')
        .controller('Application', [ '$scope', 'conference', ($scope, conference) ->
            conference.connectLocalMedia()
        ])
