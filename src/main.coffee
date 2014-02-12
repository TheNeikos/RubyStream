unless window.angular?
  alert("There has been an error loading AngularJS.")
  return

angular.module("RubyStream", ['ui.router', 'ui.bootstrap','RubyStream.Services', 'RubyStream.Directives', 'RubyStream.Controllers'])
.config(["$stateProvider","$locationProvider",($stateProvider,$locationProvider)->
  $stateProvider
  .state('viewing', {
    url: '/'
    templateUrl: '/view/viewing'
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
  .state('viewing.playlist.view', {
    url: ':id'
    templateUrl: '/view/playlist_view'
    controller: 'PlaylistView'
  }) 

  $locationProvider.html5Mode(true)
])
.run(["CurrentUser", "$rootScope",(cu,$rootScope)->
  $rootScope.currentUser = cu

  cu.autoLogin()
])
.filter('time', ->
  return (input)->
    input = parseInt(input, 10)
    return "#{Math.floor(input/60)} Minutes #{input % 60} Seconds"
)
