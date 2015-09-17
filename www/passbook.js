var passbook = exports;

var exec = require('cordova/exec');

passbook.available = function (resultCallback) {
    return exec(resultCallback, null, "Passbook", "available", []);
};

passbook.isPassInLibrary = function (path,resultCallback) {
    return exec(resultCallback, null, "Passbook", "isPassInLibrary", [path]);
};

passbook.openPass = function (path, successCallback, errorCallback) {
    return exec(successCallback, errorCallback, "Passbook", "openPass", [path]);
};

passbook.downloadPass = function (url, successCallback, errorCallback) {
    return exec(successCallback, errorCallback, "Passbook", "downloadPass", [url]);
};

