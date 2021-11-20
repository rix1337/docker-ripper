let app = angular.module('logApp', []);

app.controller('logCtrl', function ($scope, $http, $timeout) {
    $(function () {
        $('[data-toggle="tooltip"]').tooltip()
    });


    $scope.loglength = 150;
    $scope.longlog = false;

    $scope.longerLog = function () {
        $scope.loglength = 999;
        $scope.longlog = true;
    };

    $scope.shorterLog = function () {
        $scope.loglength = 150;
        $scope.longlog = false;
    };

    $scope.init = getLog();

    $scope.deleteLog = function () {
        deleteLog();
    };

    $scope.deleteLogRow = function (row) {
        deleteLogRow(row);
    };

    function getLog() {
        $http.get('api/log/')
            .then(function (res) {
                $scope.log = res.data.log;
                console.log('Log loaded!');
            }, function () {
                console.log('Could not load log!');
                showDanger('Could not load log!');
            });
    }


    function deleteLog() {
        spinLog();
        $http.delete('api/log/')
            .then(function () {
                console.log('Log cleared!');
                showSuccess('Log cleared!');
                getLog();
            }, function () {
                console.log('Could not clear log!');
                showDanger('Could not clear log!');
            });
    }

    function deleteLogRow(title) {
        title = btoa(title);
        $http.delete('api/log_entry/' + title)
            .then(function () {
                console.log('Log entry deleted!');
                showSuccess('Log entry deleted!');
                getLog();
            }, function () {
                console.log('Could not delete log entry!');
                showDanger('Could not delete log entry!');
            });
    }

    function showSuccess(message) {
        $(".alert-success").html(message).fadeTo(3000, 500).slideUp(500, function () {
            $(".alert-success").slideUp(500);
        });
    }


    function showDanger(message) {
        $(".alert-danger").html(message).fadeTo(5000, 500).slideUp(500, function () {
            $(".alert-danger").slideUp(500);
        });
    }

    function spinLog() {
        $("#spinner-log").fadeIn().delay(1000).fadeOut();
    }

    $scope.updateLog = function () {
        $timeout(function () {
            getLog();
            $scope.updateLog();
        }, 5000)
    };

    $scope.updateLog();
})
;
