unless window.angular?
  alert("There has been an error loading AngularJS.")
  return

angular.module("RubyStream", ['ui.router', 'ui.bootstrap'])
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
  })
  .state('viewing.playlist.new', {
    url: 'new/'

  }) 

  $locationProvider.html5Mode(true)
])
.run(["CurrentUser", "$rootScope",(cu,$rootScope)->
  $rootScope.currentUser = cu
])
.factory("CurrentUser", ["$http","$q", ($http,$q)->
  user = {}
  user.loggedIn = ->
    return user.data?

  user.login = (data)->
    deferred = $q.defer()
    console.log data
    $http.post('/user/login', data)
    .success (data)->
      if data.error
        deferred.reject(data.error)
      else
        user.data = data 
        deferred.resolve()
    return deferred.promise

  user.isAdmin = ->
    return user.loggedIn() && user.data.is_admin

  user.isModerator = ->
    return user.loggedIn() && user.data.is_moderator

  return user
])
.directive("navbarUserStatus", ["CurrentUser",(CurrentUser)->
  {
    templateUrl: "/view/navbarUserStatus"
    link: (scope, element, attr)->
  } 
])
