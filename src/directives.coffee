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
      element.bind 'click', (e)->
        if e.toElement == element[0]
          $state.transitionTo('viewing')
      return
  }
])
.directive("youtube", ["$window", "$rootScope", ($window, $rootScope)->
  {
    restrict: 'E'
    scope: {
      id: '@'
      time: '@'
    }
    link: (scope, element)->
      startPlayer = ->
        player = new YT.Player('youtube-player', {
          events: {
            onReady: ->
              player.loadVideoById(scope.id, scope.time) if scope.id and scope.time
              scope.$watch('id', (newId)->
                player.loadVideoById(newId) if newId
              )
              scope.$watch('time', (newTime)->
                curTime =  player.getCurrentTime()
                if  Math.abs( curTime - newTime) > 10
                  console.log "Updated from #{player.getCurrentTime()} to #{newTime}"
                  player.loadVideoById(scope.id, newTime)
              )
            onStateChange: ->
          }
        })
      if $window.YT and $window.YT.Player
        startPlayer()
      else
        $window.onYouTubeIframeAPIReady =  ->
          scope.$apply ->
            startPlayer()
      return


          
  }
])
.directive("chatInput", [->
  {
    restrict: 'A'
    scope: {
      onEnter: '&'
    }
    link: (scope, element, attr)->
      element.on("keypress", (e)->
        if(e.keyCode == 13 and e.shiftKey == false)
          e.preventDefault()
          scope.onEnter()
      )
  }
])
