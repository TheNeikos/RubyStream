angular.module("RubyStream.Directives",[])
.directive("navbarUserStatus", ["CurrentUser",(CurrentUser)->
  {
    templateUrl: "/view/navbarUserStatus"
    link: (scope, element, attr)->
  } 
])
.directive("overlay", ["$state", ($state)->
  {
    restrict: 'C'
    link: (scope, element)->
      console.log arguments
      element.bind 'click', (e)->
        if e.toElement == element[0]
          $state.transitionTo('viewing')
      return
  }
])
