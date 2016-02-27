# Insider

[![Build Status](https://travis-ci.org/alexmx/Insider.svg?branch=master)](https://travis-ci.org/alexmx/Insider)
[![Twitter: @amaimescu](https://img.shields.io/badge/contact-%40amaimescu-blue.svg)](https://twitter.com/amaimescu)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/alexmx/ios-ui-automation-overview/blob/master/LICENSE)

Insider is a **testing utility framework** which sets an HTTP communication bridge between the app and testing environments like [Appium](http://appium.io/), [Calabash](http://calaba.sh/), [Frank](http://www.testingwithfrank.com/), etc. Some real use cases which could require such communication channel:
* Set a particular state for the app during the test scenario;
* Simulate push notifications;
* Simulate app invokation using custom schemes / universal links;
* Simulate backend responses;
* Put particular files in the application sandbox;
* Collect metrics from the app during test execution (CPU, memory, etc.);
* etc.

## Features

  | Built-in Features 
------------ | -------------
💡 | Invoke a method on a registered **delegate** with given parameters;
📎 | Invoke a method on a registered **delegate** with given parameters and wait for response;
📢 | Send local notifications through **NSNotificationCenter** with given parameters;
📱 | Get device system state information (CPU, memory, IP address, etc);

## Installation

#### Manual installation

In order to include the **Insider** library into your project, you need to build a dynamic framework from provided source code and include it into your project; however you can get a prebuilt version of the framework from the [release page](https://github.com/alexmx/Insider/releases).

#### Carthage

If you are using **Carthage**, you can always use it to build the library within your workspace by adding the line below to your `Cartfile`.

```
github "alexmx/Insider"
```

## Usage

Basic integration:

```swift

import Insider

class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
  
    Insider.sharedInstance().startWithDelegate(self)
        
    return true
  }
}

extension AppDelegate: InsiderDelegate {

  func insider(insider: Insider, invokeMethodWithParams params: AnyObject?) {
    // Received commands (params) from test script;
    // Using this params we can perform different simulations. Consider the use in the description section above;
    // Example: simulate app invokation using custom scheme:
    simulatedURL = params["url"]
    application(UIApplication.sharedApplication(), handleOpenURL: simulatedURL)
  }
  
  func insider(insider: Insider, invokeMethodForResponseWithParams params: AnyObject?) -> AnyObject? {
    // Received commands (params) from test script;
    // Perform some actions and return the result back to test script;
    // ...
    return resultParams
  }
    
  func insider(insider: Insider, didSendNotificationWithParams params: AnyObject?) {
    // Called after an Insider built notification" is sent through NSNotificationCenter with given params;
    // App should listen the notifications from Insider (Insider.insiderNotificationKey)
  }
    
  func insider(insider: Insider, didReturnSystemInfo systemInfo: Dictionary<String, AnyObject>?) {
    // Called after test script requests the full information about the system
    // The system information is collected and sent automatically by Insider.
  }
}

```


## License
This project is licensed under the terms of the MIT license. See the LICENSE file.
