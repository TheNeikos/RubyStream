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
.directive("youtube", ["$window", "$rootScope", "$interval", ($window, $rootScope, $interval)->
  {
    restrict: 'E'
    scope: {
      id: '@'
      time: '='
    }
    link: (scope, element)->
      startPlayer = ->
        player = new YT.Player('youtube-player', {
          events: {
            onReady: ->
              oldId = ""
              player.loadVideoById(scope.id, scope.time) if scope.id and scope.time
              scope.$watchCollection('[time, id]', (newProperties, oldProperties)->
                return unless scope.id? and scope.time?
                curTime = player.getCurrentTime()
                if Math.abs( curTime - scope.time) > 10 or newProperties[1] != oldId
                  player.loadVideoById(scope.id, scope.time)
                  oldId = newProperties[1]
              )
              interval = $interval( -> 
                scope.time = player.getCurrentTime()
              , 1000)
              element.on('$destroy',->
                $interval.cancel(interval)
              )

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
        scope.$apply ->
          if(e.keyCode == 13 and e.shiftKey == false)
            e.preventDefault()
            scope.onEnter()
      )
  }
])
.directive("chatWindow", ["$timeout", ($timeout)->
  {
    restrict: 'A'
    scope: {
      msgs: '=messages'
    }
    link: (scope, element, attr)->
      scope.$watch('msgs', ->
        $timeout(->
          element.scrollTop(element[0].scrollHeight)
        , 1)
      , true)
      return
  }
])
