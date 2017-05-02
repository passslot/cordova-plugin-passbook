# com.passslot.cordova.plugin.passbook

This plugin provides support for showing Passbook passs to your users and allows them to add it to their native Wallet (regardless of how you create your passes, whether you do it on your own or using any third-party services like [PassSlot](http://www.PassSlot.com))

**NOTE**: This plugin does not allow you to create Passbook passes.

## Installation

    cordova plugin add cordova-plugin-passbook

Or the latest (unstable) version:

    cordova plugin add https://github.com/passslot/cordova-plugin-passbook

## Supported Platforms


- iOS
- ~~Android~~ (coming soon)

## Example

### Simple Call

```javascript
    Passbook.downloadPass('https://d.pslot.io/cQY2f', function (pass, added) {
        console.log(pass, added);
        if (added) {
            Passbook.openPass(pass);
        } else {
            alert('Please add the pass');
        }
    }, function (error) {
        console.error(error);
    });
```

### Adding Headers

```javascript

   var callData =  {
                    "url":'https://d.pslot.io/cQY2f',
                    "headers":{ "authorization": "Bearer <token>" }
                  };

    Passbook.downloadPass(callData, function (pass, added) {
        console.log(pass, added);
        if (added) {
            Passbook.openPass(pass);
        } else {
            alert('Please add the pass');
        }
    }, function (error) {
        console.error(error);
    });
```

## Documentation

Plugin documentation: [doc/index.md](doc/index.md)


## Creating Passbook Passes
This Plugin was written by [PassSlot](http://www.PassSlot.com).<br>
PassSlot is a Passbook service that makes Passbook usage easy for everybody. It helps you design and distribute mobile passes to all major mobile platforms.
