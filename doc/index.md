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
When the pass was sucessfully downloaded and shown to the user, the `successCallback` callback executes. If there is an error, the `errorCallback` callback executes with an error string as the parameter

    Passbook.downloadPass(url,
                         [successCallback],
                         [errorCallback]);

### Parameters

- __url__: The URL of the pass that should be downloaded.

- __successCallback__: (Optional) The callback that executes when the pass is shown to the user.

- __errorCallback__: (Optional) The callback that executes if an error occurs, e.g if Passbook is not available, the URL is invalid or no valid pass was found at the given URL.


### Example

    // onSuccess Callback
    function onSuccess() {
        console.log('Pass shown to the user');
    }

    // onError Callback receives a string with the error message
    //
    function onError(error) {
    	alert('Could now show pass: ' + error);
    }

    Passbook.downloadPass('https://d.pslot.io/cQY2f', onSuccess, onError);


