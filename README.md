# Insider

[![Build Status](https://travis-ci.org/alexmx/Insider.svg?branch=master)](https://travis-ci.org/alexmx/Insider)
[![Twitter: @amaimescu](https://img.shields.io/badge/contact-%40amaimescu-blue.svg)](https://twitter.com/amaimescu)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/alexmx/ios-ui-automation-overview/blob/master/LICENSE)

Insider is a **testing utility framework** which sets an HTTP communication bridge between the app and testing environments like [Appium](http://appium.io/), [Calabash](http://calaba.sh/), [Frank](http://www.testingwithfrank.com/), etc. Some real use cases where Insider could be usefull:
* Set a particular state for the app during the test scenario;
* Simulate push notifications;
* Simulate app invokation using custom schemes / universal links;
* Simulate backend responses;
* Manage files/directories in application sandbox;
* Collect metrics from the app during test execution (CPU, memory, etc.);
* etc.

## Features

  | Built-in Features 
------------ | -------------
💡 | Invoke a method on a registered **delegate** with given parameters;
📎 | Invoke a method on a registered **delegate** with given parameters and wait for response;
📢 | Send local notifications through **NSNotificationCenter** with given parameters;
📱 | Get device system state information (CPU, memory, IP address, etc);
:floppy_disk: |  Manage files/directories in application sandbox (Documents, Library, tmp);

In the `scripts` directory can be found some sample ruby scripts which test the built-in features.

## Installation

#### Manual installation

In order to include the **Insider** library into your project, you need to build a dynamic framework from provided source code and include it into your project; however you can get a prebuilt version of the framework from the [release page](https://github.com/alexmx/Insider/releases).

#### Carthage

If you are using **Carthage**, you can always use it to build the library within your workspace by adding the line below to your `Cartfile`.

```
github "alexmx/Insider"
```

## Usage

#### Use case #1: Simulate Push Notifications

```swift

import Insider

class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        Insider.sharedInstance.startWithDelegate(self)
        
        return true
  }
  
  func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        // Process push notification
  }
}

extension AppDelegate: InsiderDelegate {

  func insider(insider: Insider, invokeMethodWithParams params: JSONDictionary?) {
        // Simulate push notification
        self .application(UIApplication.sharedApplication(), didReceiveRemoteNotification: params!);
  }
}

```
In order to test this example run `InsiderUseCases` application target, after go to `scripts` directory and run `invoke_method.rb` script.

#### Use case #2: Simulate app invocation using a custom scheme

```swift

import Insider

class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Insider.sharedInstance.startWithDelegate(self)
        
        return true
  }
  
  func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        // Process custom scheme invocation
        return true
    }
}

extension AppDelegate: InsiderDelegate {

  func insider(insider: Insider, invokeMethodForResponseWithParams params: JSONDictionary?) -> JSONDictionary? {
        // Simulate app invokation using a custom scheme
        let url = NSURL(string: "insiderDemo://somescheme/params")
        let response = application(UIApplication.sharedApplication(), handleOpenURL: url!)
        
        return ["response" : response]
    }
}

```
In order to test this example run `InsiderUseCases` application target, after go to `scripts` directory and run `invoke_method_with_response.rb` script.

## License
This project is licensed under the terms of the MIT license. See the LICENSE file.
