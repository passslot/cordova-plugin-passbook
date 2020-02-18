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

function toPass(pass) {
    return new Pass(pass.passTypeIdentifier, pass.serialNumber, pass.passURL)
}

function toPassArray(passes) {
    var result = [];
    for (var index = 0; index < passes.length; index++) {
        result.push(toPass(passes[index]));
    }
    return result;
}

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
 * @param {Object}  url:String | { url:String, headers?:Object }
 * @param {Function} passCallback
 * @param {Function} errorCallback
 */
passbook.downloadPass = function (callData, passCallback, errorCallback) {
    exec(function (result) {
        if (typeof(passCallback) === 'function') {
            var pass = result.pass;
            passCallback(toPass(pass), result.added);
        }
    }, errorCallback, "Passbook", "downloadPass", [callData]);
};

/**
 *
 * @param {(string[]|{urls: string[], headers?: Object})}  callData
 * @param {Function} passCallback
 * @param {Function} errorCallback
 */
passbook.downloadPasses = function (callData, passCallback, errorCallback) {
    exec(function (result) {
        if (typeof(passCallback) === 'function') {
            var passes = result.passes;
            passCallback(toPassArray(passes), result.added);
        }
    }, errorCallback, "Passbook", "downloadPasses", [callData]);
};
               

/**
 *
 * @param {string} file Local File URL, e.g. file:///path/pass.pkpass
 * @param {Function} passCallback
 * @param {Function} errorCallback
 */
passbook.addPass = function (file, passCallback, errorCallback) {
    exec(function (result) {
        if (typeof(passCallback) === 'function') {
            var pass = result.pass;
            passCallback(toPass(pass), result.added);
        }
    }, errorCallback, "Passbook", "addPass", [file]);
};

/**
 *
 * @param {string[]} files array of Local File URLs, e.g. file:///path/pass.pkpass
 * @param {Function} passCallback
 * @param {Function} errorCallback
 */
passbook.addPasses = function (file, passCallback, errorCallback) {
    exec(function (result) {
        if (typeof(passCallback) === 'function') {
            var passes = result.passes;
            passCallback(toPassArray(passes), result.added);
        }
    }, errorCallback, "Passbook", "addPasses", [file]);
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