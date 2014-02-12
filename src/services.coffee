angular.module("RubyStream.Services",[])
.factory("CurrentUser", ["$http","$q", ($http,$q)->
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
    return deferred.promise

  user.autoLogin = ->
    if(localStorage['user_id'])
      $http.post('/api/user/auth', {'user_id':localStorage['user_id'], 'user_authkey':localStorage['user_authkey']})
      .success (data)->
        if data
          user.data = data 
          localStorage['user_id'] = data.id
          localStorage['user_authkey'] = data.login_hash



  user.isAdmin = ->
    return user.loggedIn() && user.data.is_admin

  user.isModerator = ->
    return user.loggedIn() && user.data.is_moderator

  user.post = (url, data)->
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
