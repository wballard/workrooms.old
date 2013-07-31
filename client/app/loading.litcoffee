A simple loading directive, hides as soon as loaded

    angular.module('gadgets', [])
        .directive('loading', [ ->
            restrict: 'A'
            link: ($scope, element) ->
                $(element).hide()
        ])
