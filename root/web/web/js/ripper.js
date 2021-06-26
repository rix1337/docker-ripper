let app = angular.module('crwlApp', []);

app.controller('crwlCtrl', function ($scope, $http, $timeout) {
    $(function () {
        $('[data-toggle="tooltip"]').tooltip()
    });

    $scope.results = [];

    $scope.currentPage = 0;
    $scope.pageSize = 10;
    $scope.resLength = 0;
    $scope.numberOfPages = function () {
        if (typeof $scope.results.bl !== 'undefined') {
            $scope.resLength = Object.values($scope.results.bl).length;
            return Math.ceil($scope.resLength / $scope.pageSize);
        }
    };

    $scope.currentPageLog = 0;
    $scope.pageSizeLog = 5;
    $scope.resLengthLog = 0;
    $scope.numberOfPagesLog = function () {
        if (typeof $scope.log !== 'undefined') {
            $scope.resLengthLog = $scope.log.length;
            let numPagesLog = Math.ceil($scope.resLengthLog / $scope.pageSizeLog);
            if (($scope.currentPageLog > 0) && (($scope.currentPageLog + 1) > numPagesLog)) {
                $scope.currentPageLog = numPagesLog - 1;
            }
            return numPagesLog;
        }
    };

    $scope.loglength = 65;
    $scope.longlog = false;

    $scope.longerLog = function () {
        $scope.loglength = 999;
        $scope.longlog = true;
    };

    $scope.shorterLog = function () {
        $scope.loglength = 65;
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
                console.log('Log abgerufen!');
            }, function () {
                console.log('Konnte Log nicht abrufen!');
                showDanger('Konnte Log nicht abrufen!');
            });
    }


    function deleteLog() {
        spinLog();
        $http.delete('api/log/')
            .then(function () {
                console.log('Log geleert!');
                showSuccess('Log geleert!');
                getLog();
            }, function () {
                console.log('Konnte Log nicht leeren!');
                showDanger('Konnte Log nicht leeren!');
            });
    }

    function deleteLogRow(title) {
        title = btoa(title);
        $http.delete('api/log_entry/' + title)
            .then(function () {
                console.log('Logeintrag gelöscht!');
                showSuccess('Logeintrag gelöscht!');
                getLog();
            }, function () {
                console.log('Konnte Logeintrag nicht löschen!');
                showDanger('Konnte Logeintrag nicht löschen!');
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
