var passbook = exports;

var exec = require('cordova/exec');

/**
 * Pass
 *
 * @param {string} passTypeIdentifier
 * @param {string} serialNumber {string}
 * @param {string} passURL
 * @constructor
 */
var Pass = function (passTypeIdentifier, serialNumber, passURL) {
    this.passTypeIdentifier = passTypeIdentifier || null;
    this.serialNumber = serialNumber || null;
    this.passURL = passURL || null;
};


Pass.prototype.open = function () {
    passbook.openPass(this.passURL, null, null);
};

passbook.Pass = Pass;

/**
 *
 * @param resultCallback {Function} is called with result
 */
passbook.available = function (resultCallback) {
    exec(resultCallback, null, "Passbook", "available", []);
};
/**
 *
 * @param {string} url
 * @param {Function} passCallback
 * @param {Function} errorCallback
 */
passbook.downloadPass = function (url, passCallback, errorCallback) {
    exec(function (result) {
        if (typeof(passCallback) === 'function') {
            var pass = result.pass;
            passCallback(new Pass(pass.passTypeIdentifier, pass.serialNumber, pass.passURL), result.added);
        }
    }, errorCallback, "Passbook", "downloadPass", [url]);
};

/**
 *
 * @param file Local File URL, e.g. file:///path/pass.pkpass
 * @param {Function} passCallback
 * @param {Function} errorCallback
 */
passbook.addPass = function (file, passCallback, errorCallback) {
    exec(function (result) {
        if (typeof(passCallback) === 'function') {
            var pass = result.pass;
            passCallback(new Pass(pass.passTypeIdentifier, pass.serialNumber, pass.passURL), result.added);
        }
    }, errorCallback, "Passbook", "addPass", [file]);
};

/**
 *
 * @param {Pass|string} passOrUrl
 * @param {Function} successCallback
 * @param {Function} errorCallback
 */
passbook.openPass = function (passOrUrl, successCallback, errorCallback) {
    exec(successCallback, errorCallback, "Passbook", "openPass", [passOrUrl]);
};
