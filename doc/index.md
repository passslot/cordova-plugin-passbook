# cordova-plugin-passbook

This plugin provides basic support for Passbook on iOS.
It allows you to show Passbook passes so that your users can add them directly to Passbook.

On cordova >= 3.1.0, this plugin registers for .pkpass URLs and automatically downloads and displays the pass to the user if the link was clicked.

## Installation

    cordova plugin add cordova-plugin-passbook

## Supported Platforms

- iOS

## Methods

- Passbook.available
- Passbook.downloadPass


## Passbook.available

Returns if Passbook is available on the current device to the `resultCallback` callback with a boolean as the parameter.

    Passbook.available(resultCallback);

### Parameters

- __resultCallback__: The callback that is passed if Passbook is available.


### Example
```javascript
// onSuccess Callback
// This method accepts a boolean, which specified if Passbook is available
//
var onResult = function(isAvailable) {
    if(!isAvailable) {
        alert('Passbook is not available');
    }
};

Passbook.available(onResult);
```
## Passbook.downloadPass

Downloads a pass from a the provided URL and shows it to the user.
When the pass was successfully downloaded and was shown to the user, and the user either canceld or added the pass, the `passCallback` callback executes. If there is an error, the `errorCallback` callback executes with an error string as the parameter
```javascript
Passbook.downloadPass(callData, [passCallback], [errorCallback]);
```

### Parameters

- __callData__: It could be either an URL or an Object in the form `{ url:<url>, headers?:<{}> }` .

- __passCallback__: (Optional) The callback that executes when the pass is shown to the user. Returns the downloaded pass (passTypeIdentifier, serialNumber, passURL) and if it was added to Passbook.

- __errorCallback__: (Optional) The callback that executes if an error occurs, e.g if Passbook is not available, the URL is invalid or no valid pass was found at the given URL.


### Simple Example

```javascript
// onSuccess Callback
function onSuccess(pass, added) {
    console.log('Pass shown to the user');
    console.log(pass, added);
}

// onError Callback receives a string with the error message
//
function onError(error) {
    alert('Could now show pass: ' + error);
}

Passbook.downloadPass('https://d.pslot.io/cQY2f', onSuccess, onError);
```

### Adding Header

```javascript
// onSuccess Callback
function onSuccess(pass, added) {
    console.log('Pass shown to the user');
    console.log(pass, added);
}

// onError Callback receives a string with the error message
//
function onError(error) {
  alert('Could now show pass: ' + error);
}

var callData =  {
                 "url":'https://d.pslot.io/cQY2f',
                 "headers":{ "authorization": "Bearer <token>" }
               };
Passbook.downloadPass(callData, onSuccess, onError);
```

## Passbook.downloadPasses

Downloads a list of passes from a the provided URLs and shows them to the user.
When the passes are successfully downloaded, shown to the user, and the user either cancelled or added the pass, the `passCallback` callback executes passing an array of passes and a boolean of value of if they were added or not. If there is an error, the `errorCallback` callback executes with an error string as the parameter
```javascript
Passbook.downloadPasses(callData, [passCallback], [errorCallback]);
```
### Parameters

- __callData__: It could be either an array of URL strings or an Object in the form `{ urls:[<url1>,<url2>], headers?:<{}> }` .

- __passCallback__: (Optional) The callback that executes when the pass is shown to the user. Returns the downloaded pass (passTypeIdentifier, serialNumber, passURL) and if it was added to Passbook.

- __errorCallback__: (Optional) The callback that executes if an error occurs, e.g if Passbook is not available, the URL is invalid or no valid pass was found at the given URL.

### Simple Example

```javascript
// onSuccess Callback
function onSuccess(passes, added) {
    console.log('Passes shown to the user');
    console.log(passes, added);
}

// onError Callback receives a string with the error message
//
function onError(error) {
    alert('Could now show passes: ' + error);
}

Passbook.downloadPasses(['https://d.pslot.io/cQY2f', 'https://d.pslot.io/DbM3E'], onSuccess, onError);
```

### Adding Header

```javascript
// onSuccess Callback
function onSuccess(passes, added) {
    console.log('Pass shown to the user');
    console.log(passes, added);
}

// onError Callback receives a string with the error message
//
function onError(error) {
  alert('Could now show passes: ' + error);
}

var callData =  {
                 "urls":['https://d.pslot.io/cQY2f', 'https://d.pslot.io/DbM3E'],
                 "headers":{ "authorization": "Bearer <token>" }
               };
Passbook.downloadPasses(callData, onSuccess, onError);
```

## Passbook.addPass

Add a pass from a the provided local file and shows it to the user.
When the pass was successfully shown to the user, and the user either canceled or added the pass, the `passCallback` callback executes. If there is an error, the `errorCallback` callback executes with an error string as the parameter
```javascript
Passbook.addPass(file, [passCallback], [errorCallback]);
```
### Parameters

- __file__: The file of the pass that should be shown. (e.g. file:///..../sample.pkpass)

- __passCallback__: (Optional) The callback that executes when the pass is shown to the user. Returns the local pass (passTypeIdentifier, serialNumber, passURL) and if it was added to Passbook.

- __errorCallback__: (Optional) The callback that executes if an error occurs, e.g if Passbook is not available, the URL is invalid or no valid pass was found at the given URL.


### Example
```javascript
// onSuccess Callback
function onSuccess(pass, added) {
    console.log('Pass shown to the user');
    console.log(pass, added);
}

// onError Callback receives a string with the error message
//
function onError(error) {
    alert('Could now show pass: ' + error);
}

Passbook.addPass(cordova.file.applicationDirectory + 'sample.pkpass', onSuccess, onError);
```
## Passbook.addPasses

Add a list of passes from a the provided local files and shows it to the user.
When the passes are successfully shown to the user, and the user either cancelled or added the passes, the `passCallback` callback executes. If there is an error, the `errorCallback` callback executes with an error string as the parameter
```javascript
Passbook.addPass(files, [passCallback], [errorCallback]);
```
### Parameters

- __files__: The files of the passes that should be shown. (e.g. ["file:///..../sample1.pkpass","file:///..../sample2.pkpass"])

- __passCallback__: (Optional) The callback that executes when the pass is shown to the user. Returns the local pass (passTypeIdentifier, serialNumber, passURL) and if it was added to Passbook.

- __errorCallback__: (Optional) The callback that executes if an error occurs, e.g if Passbook is not available, the URL is invalid or no valid pass was found at the given URL.


### Example
```javascript
// onSuccess Callback
function onSuccess(passes, added) {
    console.log('Passes shown to the user');
    console.log(passes, added);
}

// onError Callback receives a string with the error message
//
function onError(error) {
    alert('Could now show pass: ' + error);
}

Passbook.addPasses(
    [
        cordova.file.applicationDirectory + 'sample1.pkpass', 
        cordova.file.applicationDirectory + 'sample2.pkpass'
    ], 
    onSuccess, 
    onError
);
```