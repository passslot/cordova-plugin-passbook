var passbook = exports;

var exec = require('cordova/exec');

passbook.available = function (resultCallback) {
    return exec(resultCallback, null, "Passbook", "available", []);
};
               
passbook.downloadPass = function (url, successCallback, errorCallback) {
    return exec(successCallback, errorCallback, "Passbook", "downloadPass", [url]);
};
