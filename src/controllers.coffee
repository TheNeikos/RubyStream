angular.module('RubyStream.Controllers', ['RubyStream.Services'])
.controller('PlaylistIndex', ["$scope","$http", ($scope,$http)->
  $http.get('/api/playlists')
  .success (data)->
    $scope.lists = data
])
.controller('PlaylistNew', ["$scope","$http", "CurrentUser", "$state",($scope, $http, CurrentUser, $state)->
  $scope.playlist = {
    name: ""
  }
  $scope.createPlaylist = ->
    CurrentUser.post('/api/playlist/new', $scope.playlist)
    .success (pl)->
      $state.go('viewing.playlist.view', {id: pl.id})
])
.controller('PlaylistView', ["$scope","$http","$stateParams", "CurrentUser",($scope, $http, $stateParams,CurrentUser)->
  $scope.playlist = {
    name: ""
  }

  $scope.addVideo = ->
    CurrentUser.post('/api/playlist/' + $stateParams.id + '/add', $scope.video)
    $scope.video = ""

  $http.get('/api/playlist/' + $stateParams.id)
  .success (playlist)->
    $scope.playlist = playlist  
])
