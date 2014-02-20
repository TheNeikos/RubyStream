angular.module('RubyStream.Controllers', ['RubyStream.Services'])
.controller('PlaylistIndex', ["$scope","$http","Playlists", "CurrentUser", ($scope, $http, Playlists, CurrentUser)->
  Playlists.all().then (data)->
    $scope.playlists = data

  $scope.activatePlaylist = (id)->
    CurrentUser.post('/api/playlist/'+id+'/activate')      

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
.controller('PlaylistEdit', ["$scope","$http", "CurrentUser", "$state", "$stateParams", "Playlists",($scope, $http, CurrentUser, $state, $stateParams, Playlists)->
  $scope.playlist = {
    name: ""
  }

  Playlists.get($stateParams.id).then (playlist)->
    $scope.playlist = playlist

  $scope.updatePlaylist = ->
    CurrentUser.post('/api/playlist/'+$stateParams.id+'/update', $scope.playlist)
    .success (pl)->
      $state.go('viewing.playlist.view', {id: pl.id})
])
.controller('PlaylistView', ["$scope","$http","$stateParams", "CurrentUser", "Playlists",($scope, $http, $stateParams, CurrentUser, Playlists)->
  $scope.playlist = {
    name: ""
  }

  startIndex = 0

  $scope.sortableOptions = {
    axis: "y"
    containment: 'parent'
    placeholder: 'playlist-placeholder'
    forcePlaceholderSize: true
    handle: ".handle"
    scroll: true
    tolerance: 'pointer'
    start: (e,ui)->
      startIndex = ui.item.index()
    stop: (e, ui)->
      CurrentUser.post('/api/playlist/' + $stateParams.id + '/changeOrder', {startIndex: startIndex, newIndex: ui.item.index()} )
  }

  $scope.addVideo = ->
    CurrentUser.post('/api/playlist/' + $stateParams.id + '/add', $scope.video)
    $scope.video = ""

  $scope.removeVideo = (id)->
    CurrentUser.post('/api/playlist/' + $stateParams.id + '/removeVideo/' + id )

  $scope.setCurrentVideo = (position)->
    CurrentUser.post('/api/playlist/' + $stateParams.id + '/activateVideo/' + position )

  Playlists.get($stateParams.id).then (data)->
    $scope.playlist = data
])
.controller('Viewing', ["$scope","Playlists",($scope, Playlists)->
  Playlists.all().then ->
    $scope.$watch(Playlists.getActivePlaylist, (playlist)->
      $scope.playlist = playlist
      if playlist.items[playlist.current_video-1]
        $scope.currentVideoId = playlist.items[playlist.current_video-1].carrier_id
      else
        $scope.currentVideoId = 0
    , true)

])
.controller('Chat', ["$scope", "WebSocket", ($scope, WebSocket)->
  $scope.message = ""
  $scope.sendMessage = ->
    message = $scope.message
    $scope.message = ""
    WebSocket.send("chat_message", {
      message: message
    })
])
