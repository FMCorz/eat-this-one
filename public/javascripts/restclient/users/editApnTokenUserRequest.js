angular.module('eat-this-one')
    .factory('editApnTokenUserRequest', ['redirecter', '$http', 'appStatus', 'notifier', 'eatConfig', 'authManager', 'sessionManager', 'newLogRequest', function(redirecter, $http, appStatus, notifier, eatConfig, authManager, sessionManager, newLogRequest) {

    return function($scope, redirectUrl, actionDone, errorWhere) {

        var requestData = {
            provider : 'apntoken',
            name : $scope.name.value,
            email : $scope.email.value,
            apntoken : localStorage.getItem('apnToken')
        };

        $http({
            method : 'POST',
            url : eatConfig.backendUrl + '/users',
            data : requestData
        }).success(function(data) {

            authManager.authenticate(data._id);
            sessionManager.setUser(data);

            newLogRequest(actionDone, 'account', data._id);

            redirecter.redirect(redirectUrl);

        }).error(function(data, errorStatus, errorMsg) {
            appStatus.completed('signup');
            newLogRequest('error', errorWhere, errorMsg);
            notifier.show($scope.lang.error, $scope.lang.weird);
        });
    };

}]);
