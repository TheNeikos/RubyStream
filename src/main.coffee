unless window.angular?
  alert("There has been an error loading AngularJS.")
  return

angular.module("RubyStream", ['ui.router'])
