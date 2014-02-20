unless window.angular?
  alert("There has been an error loading AngularJS.")
  return

angular.module("RubyStream", ['ui.router', 'ui.bootstrap','ui.sortable','RubyStream.Services', 'RubyStream.Directives', 'RubyStream.Controllers'])
.config(["$stateProvider","$locationProvider", "$sceDelegateProvider",($stateProvider,$locationProvider,$sceDelegateProvider)->
  $stateProvider
  .state('viewing', {
    url: '/'
    templateUrl: '/view/viewing'
    controller: 'Viewing'
  })
  .state('viewing.user', {
    url: 'user/'
    abstract: true
  })
  .state('viewing.user.login', {
    url: 'login'
    onEnter: ["$stateParams","$state","$modal","CurrentUser", ($stateParams,$state,$modal, CurrentUser)->
      $modal.open({
        templateUrl: '/view/user_login'
        controller: ['$scope', ($scope)->
          $scope.user = {
            name: ""
            password: ""
          }
          $scope.dismiss = ->
            $scope.$dismiss()
          $scope.login = ->
            CurrentUser.login($scope.user)
            .then(->
              $scope.dismiss()
            , (error)->
              $scope.error = error
            )
        ]
        keyboard: true
      }).result.finally((result)->
        $state.transitionTo('viewing') 
      )
    ]
  })
  .state('viewing.playlist', {
    url: 'playlist/'
    templateUrl: '/view/playlist_layout'
    abstract: true
  })  
  .state('viewing.playlist.index', {
    url: ''
    templateUrl: '/view/playlist_index'
    controller: 'PlaylistIndex'
  })
  .state('viewing.playlist.new', {
    url: 'new/'
    templateUrl: '/view/playlist_new'
    controller: 'PlaylistNew'
  })
  .state('viewing.playlist.edit', {
    url: ':id/edit'
    templateUrl: '/view/playlist_edit'
    controller: 'PlaylistEdit'
  }) 
  .state('viewing.playlist.view', {
    url: ':id'
    templateUrl: '/view/playlist_view'
    controller: 'PlaylistView'
  }) 

  $locationProvider.html5Mode(true)

  $sceDelegateProvider.resourceUrlWhitelist(['self', 'https://youtube.com/*'])

])
.run(["CurrentUser", "$rootScope","WebSocket", "ChatMessages", (cu,$rootScope,WebSocket,ChatMessages)->
  $rootScope.currentUser = cu
  $rootScope.chatMessages = ChatMessages
  cu.autoLogin()

  # Youtube stuff

  tag = document.createElement('script')
  tag.src = "https://www.youtube.com/iframe_api"

  document.getElementsByTagName('body')[0].appendChild tag


])
.filter('time', ->
  return (input, output)->
    input = parseInt(input, 10)
    if output == 'short'
      return "#{Math.floor(input/60)}:#{input % 60}"
    else
      return "#{Math.floor(input/60)} Minutes #{input % 60} Seconds"
)
