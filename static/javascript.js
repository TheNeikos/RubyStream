// Generated by CoffeeScript 1.6.3
(function() {
  angular.module('RubyStream.Controllers', ['RubyStream.Services']).controller('PlaylistIndex', [
    "$scope", "$http", "Playlists", "CurrentUser", function($scope, $http, Playlists, CurrentUser) {
      Playlists.all().then(function(data) {
        return $scope.playlists = data;
      });
      return $scope.activatePlaylist = function(id) {
        return CurrentUser.post('/api/playlist/' + id + '/activate');
      };
    }
  ]).controller('PlaylistNew', [
    "$scope", "$http", "CurrentUser", "$state", function($scope, $http, CurrentUser, $state) {
      $scope.playlist = {
        name: ""
      };
      return $scope.createPlaylist = function() {
        return CurrentUser.post('/api/playlist/new', $scope.playlist).success(function(pl) {
          return $state.go('viewing.playlist.view', {
            id: pl.id
          });
        });
      };
    }
  ]).controller('PlaylistEdit', [
    "$scope", "$http", "CurrentUser", "$state", "$stateParams", "Playlists", function($scope, $http, CurrentUser, $state, $stateParams, Playlists) {
      $scope.playlist = {
        name: ""
      };
      Playlists.get($stateParams.id).then(function(playlist) {
        return $scope.playlist = playlist;
      });
      return $scope.updatePlaylist = function() {
        return CurrentUser.post('/api/playlist/' + $stateParams.id + '/update', $scope.playlist).success(function(pl) {
          return $state.go('viewing.playlist.view', {
            id: pl.id
          });
        });
      };
    }
  ]).controller('PlaylistView', [
    "$scope", "$http", "$stateParams", "CurrentUser", "Playlists", function($scope, $http, $stateParams, CurrentUser, Playlists) {
      var startIndex;
      $scope.playlist = {
        name: ""
      };
      startIndex = 0;
      $scope.sortableOptions = {
        axis: "y",
        containment: 'parent',
        placeholder: 'playlist-placeholder',
        forcePlaceholderSize: true,
        handle: ".handle",
        scroll: true,
        tolerance: 'pointer',
        start: function(e, ui) {
          return startIndex = ui.item.index();
        },
        stop: function(e, ui) {
          return CurrentUser.post('/api/playlist/' + $stateParams.id + '/changeOrder', {
            startIndex: startIndex,
            newIndex: ui.item.index()
          });
        }
      };
      $scope.addVideo = function() {
        CurrentUser.post('/api/playlist/' + $stateParams.id + '/add', $scope.video);
        return $scope.video = "";
      };
      $scope.removeVideo = function(id) {
        return CurrentUser.post('/api/playlist/' + $stateParams.id + '/removeVideo/' + id);
      };
      $scope.setCurrentVideo = function(position) {
        return CurrentUser.post('/api/playlist/' + $stateParams.id + '/activateVideo/' + position);
      };
      return Playlists.get($stateParams.id).then(function(data) {
        return $scope.playlist = data;
      });
    }
  ]).controller('Viewing', [
    "$scope", "Playlists", function($scope, Playlists) {
      return Playlists.all().then(function() {
        return $scope.$watch(Playlists.getActivePlaylist, function(playlist) {
          $scope.playlist = playlist;
          if (playlist.items[playlist.current_video - 1]) {
            return $scope.currentVideoId = playlist.items[playlist.current_video - 1].carrier_id;
          } else {
            return $scope.currentVideoId = 0;
          }
        }, true);
      });
    }
  ]).controller('Chat', [
    "$scope", "WebSocket", function($scope, WebSocket) {
      $scope.message = "";
      return $scope.sendMessage = function() {
        var message;
        message = $scope.message;
        $scope.message = "";
        return WebSocket.send("chat_message", {
          message: message
        });
      };
    }
  ]);

  angular.module("RubyStream.Directives", []).directive("navbarUserStatus", [
    "CurrentUser", function(CurrentUser) {
      return {
        templateUrl: "/view/navbarUserStatus",
        link: function(scope, element, attr) {}
      };
    }
  ]).directive("overlay", [
    "$state", function($state) {
      return {
        restrict: 'C',
        link: function(scope, element) {
          element.bind('click', function(e) {
            if (e.toElement === element[0]) {
              return $state.transitionTo('viewing');
            }
          });
        }
      };
    }
  ]).directive("youtube", [
    "$window", "$rootScope", "$interval", function($window, $rootScope, $interval) {
      return {
        restrict: 'E',
        scope: {
          id: '@',
          time: '='
        },
        link: function(scope, element) {
          var startPlayer;
          startPlayer = function() {
            var player;
            return player = new YT.Player('youtube-player', {
              events: {
                onReady: function() {
                  var interval, oldId;
                  oldId = "";
                  if (scope.id && scope.time) {
                    player.loadVideoById(scope.id, scope.time);
                  }
                  scope.$watchCollection('[time, id]', function(newProperties, oldProperties) {
                    var curTime;
                    if (!((scope.id != null) && (scope.time != null))) {
                      return;
                    }
                    curTime = player.getCurrentTime();
                    if (Math.abs(curTime - scope.time) > 10 || newProperties[1] !== oldId) {
                      player.loadVideoById(scope.id, scope.time);
                      return oldId = newProperties[1];
                    }
                  });
                  interval = $interval(function() {
                    return scope.time = player.getCurrentTime();
                  }, 1000);
                  return element.on('$destroy', function() {
                    return $interval.cancel(interval);
                  });
                }
              }
            });
          };
          if ($window.YT && $window.YT.Player) {
            startPlayer();
          } else {
            $window.onYouTubeIframeAPIReady = function() {
              return scope.$apply(function() {
                return startPlayer();
              });
            };
          }
        }
      };
    }
  ]).directive("chatInput", [
    function() {
      return {
        restrict: 'A',
        scope: {
          onEnter: '&'
        },
        link: function(scope, element, attr) {
          return element.on("keypress", function(e) {
            return scope.$apply(function() {
              if (e.keyCode === 13 && e.shiftKey === false) {
                e.preventDefault();
                return scope.onEnter();
              }
            });
          });
        }
      };
    }
  ]).directive("chatWindow", [
    "$timeout", function($timeout) {
      return {
        restrict: 'A',
        scope: {
          msgs: '=messages'
        },
        link: function(scope, element, attr) {
          scope.$watch('msgs', function() {
            return $timeout(function() {
              return element.scrollTop(element[0].scrollHeight);
            }, 1);
          }, true);
        }
      };
    }
  ]);

  if (window.angular == null) {
    alert("There has been an error loading AngularJS.");
    return;
  }

  angular.module("RubyStream", ['ui.router', 'ui.bootstrap', 'ui.sortable', 'RubyStream.Services', 'RubyStream.Directives', 'RubyStream.Controllers']).config([
    "$stateProvider", "$locationProvider", "$sceDelegateProvider", function($stateProvider, $locationProvider, $sceDelegateProvider) {
      $stateProvider.state('viewing', {
        url: '/',
        templateUrl: '/view/viewing',
        controller: 'Viewing'
      }).state('viewing.user', {
        url: 'user/',
        abstract: true
      }).state('viewing.user.login', {
        url: 'login',
        onEnter: [
          "$stateParams", "$state", "$modal", "CurrentUser", function($stateParams, $state, $modal, CurrentUser) {
            return $modal.open({
              templateUrl: '/view/user_login',
              controller: [
                '$scope', function($scope) {
                  $scope.user = {
                    name: "",
                    password: ""
                  };
                  $scope.dismiss = function() {
                    return $scope.$dismiss();
                  };
                  return $scope.login = function() {
                    return CurrentUser.login($scope.user).then(function() {
                      return $scope.dismiss();
                    }, function(error) {
                      return $scope.error = error;
                    });
                  };
                }
              ],
              keyboard: true
            }).result["finally"](function(result) {
              return $state.transitionTo('viewing');
            });
          }
        ]
      }).state('viewing.playlist', {
        url: 'playlist/',
        templateUrl: '/view/playlist_layout',
        abstract: true
      }).state('viewing.playlist.index', {
        url: '',
        templateUrl: '/view/playlist_index',
        controller: 'PlaylistIndex'
      }).state('viewing.playlist.new', {
        url: 'new/',
        templateUrl: '/view/playlist_new',
        controller: 'PlaylistNew'
      }).state('viewing.playlist.edit', {
        url: ':id/edit',
        templateUrl: '/view/playlist_edit',
        controller: 'PlaylistEdit'
      }).state('viewing.playlist.view', {
        url: ':id',
        templateUrl: '/view/playlist_view',
        controller: 'PlaylistView'
      });
      $locationProvider.html5Mode(true);
      return $sceDelegateProvider.resourceUrlWhitelist(['self', 'https://youtube.com/*']);
    }
  ]).run([
    "CurrentUser", "$rootScope", "WebSocket", "ChatMessages", function(cu, $rootScope, WebSocket, ChatMessages) {
      var tag;
      $rootScope.currentUser = cu;
      $rootScope.chatMessages = ChatMessages;
      cu.autoLogin();
      tag = document.createElement('script');
      tag.src = "https://www.youtube.com/iframe_api";
      return document.getElementsByTagName('body')[0].appendChild(tag);
    }
  ]).filter('time', function() {
    return function(input, output) {
      input = parseInt(input, 10);
      if (output === 'short') {
        return "" + (Math.floor(input / 60)) + ":" + (input % 60);
      } else {
        return "" + (Math.floor(input / 60)) + " Minutes " + (input % 60) + " Seconds";
      }
    };
  });

  angular.module("RubyStream.Services", []).factory("CurrentUser", [
    "$http", "$q", "WebSocket", function($http, $q, WebSocket) {
      var user;
      user = {};
      user.loggedIn = function() {
        return user.data != null;
      };
      user.login = function(data) {
        var deferred;
        deferred = $q.defer();
        $http.post('/api/user/login', data).success(function(data) {
          if (data.error) {
            return deferred.reject(data.error);
          } else {
            user.data = data;
            localStorage['user_id'] = data.id;
            localStorage['user_authkey'] = data.login_hash;
            deferred.resolve();
            return WebSocket.send("auth", {
              user_id: data.id,
              user_authkey: data.login_hash
            });
          }
        });
        return deferred.promise;
      };
      user.autoLogin = function() {
        if (localStorage['user_id']) {
          return $http.post('/api/user/auth', {
            'user_id': localStorage['user_id'],
            'user_authkey': localStorage['user_authkey']
          }).success(function(data) {
            if (data) {
              user.data = data;
              localStorage['user_id'] = data.id;
              localStorage['user_authkey'] = data.login_hash;
              return WebSocket.send("auth", {
                user_id: data.id,
                user_authkey: data.login_hash
              });
            }
          });
        }
      };
      user.isAdmin = function() {
        return user.loggedIn() && user.data.is_admin;
      };
      user.isModerator = function() {
        return user.loggedIn() && user.data.is_moderator;
      };
      user.post = function(url, data) {
        if (data == null) {
          data = {};
        }
        if (!user.loggedIn()) {
          return;
        }
        data.user_id = user.data.id;
        data.user_authkey = user.data.login_hash;
        return $http.post(url, data).error(function(data, status) {
          if (status === 400) {
            return user.data = {};
          }
        });
      };
      return user;
    }
  ]).factory("Playlists", [
    "$http", "$rootScope", "$q", function($http, $rootScope, $q) {
      var funcs;
      funcs = {};
      funcs.playlists = [];
      funcs.active = -1;
      funcs.all = function() {
        var deferred;
        deferred = $q.defer();
        if (!(funcs.playlists.length > 0)) {
          $http.get('/api/playlists').success(function(data) {
            funcs.playlists = data;
            return deferred.resolve(funcs.playlists);
          });
        } else {
          deferred.resolve(funcs.playlists);
        }
        return deferred.promise;
      };
      funcs.get = function(id) {
        var deferred;
        deferred = $q.defer();
        funcs.all().then(function(playlists) {
          var returned;
          returned = false;
          playlists.forEach(function(playlist, index) {
            if (playlist.id === parseInt(id, 10)) {
              deferred.resolve(funcs.playlists[index]);
              return returned = true;
            }
          });
          if (!returned) {
            return deferred.reject();
          }
        });
        return deferred.promise;
      };
      funcs.reload = function(id) {
        return $http.get('/api/playlist/' + id).success(function(data) {
          return funcs.get(id).then(function(playlist) {
            return angular.extend(playlist, data);
          }, function() {
            return funcs.playlists.push(data);
          });
        });
      };
      funcs.getActivePlaylist = function(id) {
        var pl;
        pl = null;
        funcs.playlists.forEach(function(playlist, id) {
          if (playlist.active) {
            funcs.active = id;
            return pl = playlist;
          }
        });
        return pl;
      };
      return funcs;
    }
  ]).factory("WebSocket", [
    "Playlists", "$rootScope", "$timeout", "ChatMessages", function(Playlists, $rootScope, $timeout, ChatMessages) {
      var socket;
      socket = new WebSocket('ws://' + window.location.host + '/websocket');
      socket.onopen = function() {
        return console.info("Opened");
      };
      socket.onclose = function() {
        return console.info("Closed");
      };
      socket.onmessage = function(data) {
        return $rootScope.$apply(function() {
          data = JSON.parse(data.data);
          switch (data.action) {
            case "reloadPlaylists":
              return Playlists.reload(data.id);
            case "updateTime":
              return $rootScope.$apply(function() {
                var pl;
                pl = Playlists.getActivePlaylist();
                if (pl) {
                  return pl.current_time = data.time;
                }
              });
            case "insertChatMessage":
              data = JSON.parse(data.data);
              data.type = "message";
              return ChatMessages.add(data);
            case "insertUserJoined":
              data = data.data;
              data.type = "userJoined";
              return ChatMessages.add(data);
            case "insertUserLeft":
              data = data.data;
              data.type = "userLeft";
              return ChatMessages.add(data);
          }
        });
      };
      return {
        send: function(action, data) {
          var _send;
          _send = function() {
            if (socket.readyState !== 1) {
              return $timeout(_send, 100);
            } else {
              return socket.send(JSON.stringify({
                data: data,
                action: action
              }));
            }
          };
          return _send();
        }
      };
    }
  ]).factory("ChatMessages", [
    function() {
      var messages;
      messages = {};
      messages.messages = [];
      messages.add = function(data) {
        return messages.messages.push(data);
      };
      return messages;
    }
  ]);

}).call(this);
