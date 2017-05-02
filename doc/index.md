# com.passslot.cordova.plugin.passbook

This plugin provides basic support for Passbook on iOS.
It allows you to show Passbook passes so that your users can add them directly to Passbook.

On cordova >= 3.1.0, this plugin registers for .pkpass URLs and automatically downloads and displays the pass to the user if the link was clicked.

## Installation

    cordova plugin add com.passslot.cordova.plugin.passbook

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

    // onSuccess Callback
    // This method accepts a boolean, which specified if Passbook is available
    //
    var onResult = function(isAvailable) {
    	if(!isAvailable) {
    		alert('Passbook is not available');
    	}
    };

   	Passbook.available(onResult);

## Passbook.downloadPass

Downloads a pass from a the provided URL and shows it to the user.
When the pass was successfully downloaded and was shown to the user, and the user either canceld or added the pass, the `passCallback` callback executes. If there is an error, the `errorCallback` callback executes with an error string as the parameter

    Passbook.downloadPass(callData,
                         [passCallback],
                         [errorCallback]);

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

## Passbook.addPass

Add a pass from a the provided local file and shows it to the user.
When the pass was successfully shown to the user, and the user either canceled or added the pass, the `passCallback` callback executes. If there is an error, the `errorCallback` callback executes with an error string as the parameter

    Passbook.addPass(file,
                         [passCallback],
                         [errorCallback]);

### Parameters

- __file__: The file of the pass that should be downloaded. (e.g. file:///..../sample.pkpass)

- __passCallback__: (Optional) The callback that executes when the pass is shown to the user. Returns the local pass (passTypeIdentifier, serialNumber, passURL) and if it was added to Passbook.

- __errorCallback__: (Optional) The callback that executes if an error occurs, e.g if Passbook is not available, the URL is invalid or no valid pass was found at the given URL.


### Example

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
