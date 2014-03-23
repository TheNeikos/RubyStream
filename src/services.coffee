angular.module("RubyStream.Services",[])
.factory("CurrentUser", ["$http","$q", "WebSocket",($http, $q, WebSocket)->
  user = {}
  user.loggedIn = ->
    return user.data?

  user.login = (data)->
    deferred = $q.defer()
    $http.post('/api/user/login', data)
    .success (data)->
      if data.error
        deferred.reject(data.error)
      else
        user.data = data 
        localStorage['user_id'] = data.id
        localStorage['user_authkey'] = data.login_hash
        deferred.resolve()
        WebSocket.send "auth", {
          user_id: data.id
          user_authkey: data.login_hash
        }
    return deferred.promise

  user.autoLogin = ->
    if(localStorage['user_id'])
      $http.post('/api/user/auth', {'user_id':localStorage['user_id'], 'user_authkey':localStorage['user_authkey']})
      .success (data)->
        if data
          user.data = data 
          localStorage['user_id'] = data.id
          localStorage['user_authkey'] = data.login_hash
          WebSocket.send "auth", {
            user_id: data.id
            user_authkey: data.login_hash
          }

  user.isAdmin = ->
    return user.loggedIn() && user.data.is_admin

  user.isModerator = ->
    return user.loggedIn() && user.data.is_moderator

  user.post = (url, data={})->
    return unless user.loggedIn()
    data.user_id = user.data.id
    data.user_authkey = user.data.login_hash
    $http.post(url, data)
    .error((data, status)->
      if status == 400
        user.data = {}
    )

  return user
])
.factory("Playlists", ["$http", "$rootScope", "$q", ($http, $rootScope, $q)->
  funcs = {}
  funcs.playlists = []
  funcs.active = -1

  funcs.all = ->
    deferred = $q.defer()
    unless funcs.playlists.length > 0
      $http.get('/api/playlists')
      .success((data)->
        funcs.playlists = data
        deferred.resolve(funcs.playlists)
      )
    else
      deferred.resolve(funcs.playlists)
    return deferred.promise

  funcs.get = (id)->
    deferred = $q.defer()
    funcs.all().then (playlists)->
      returned = false
      playlists.forEach (playlist, index)->
        if playlist.id == parseInt(id, 10)
          deferred.resolve(funcs.playlists[index])
          returned = true
      unless returned
        deferred.reject()
    return deferred.promise

  funcs.reload = (id)->
    $http.get('/api/playlist/'+id)
    .success((data)->
      funcs.get(id).then((playlist)->
        angular.extend(playlist, data)
      , ->
        funcs.playlists.push data
      )
    )

  funcs.getActivePlaylist = (id)->
    pl = null
    funcs.playlists.forEach (playlist, id)->
      if playlist.active
        funcs.active = id 
        pl = playlist
    return pl
  return funcs
])  
.factory("WebSocket", ["Playlists", "$rootScope", "$timeout", "ChatMessages", "UserList",(Playlists, $rootScope, $timeout, ChatMessages, UserList)->

  socket = new WebSocket('ws://'+window.location.host+ '/websocket')

  socket.onopen = ->
    console.info("Opened")
  socket.onclose = ->
    console.info("Closed")
  socket.onmessage = (data)->
    $rootScope.$apply ->
      data = JSON.parse data.data
      switch data.action
        when "reloadPlaylists" 
          Playlists.reload(data.id)
        when "updateTime"
          $rootScope.$apply ->
            pl = Playlists.getActivePlaylist()
            if pl
              pl.current_time = data.time
        when "insertChatMessage"
          data = JSON.parse data.data
          data.type = "message"
          ChatMessages.add data
        when "insertUserJoined"
          data = data.data
          data.type = "userJoined"
          ChatMessages.add data
        when "insertUserLeft"
          data = data.data
          data.type = "userLeft"
          ChatMessages.add data
        when "updateUsers"
          data = data.data
          UserList.update data

  return {
    send: (action, data)->
      _send = ->
        if (socket.readyState != 1)
          $timeout(_send, 100)
        else
          socket.send(JSON.stringify({
            data: data
            action: action
          }))
      _send()

  }
])
.factory("ChatMessages", [->
  messages = {}
  messages.messages = []
  messages.add = (data)->
    messages.messages.push data
  return messages

])
.factory("UserList", [->
  list = {}
  list.list = []
  list.anons = 0
  list.update = (data)->
    list.anons = data.anons
    list.list.length = 0
    data.users.forEach (user)->
      user = JSON.parse user
      list.list.push user
    console.log list.list
  return list
])
