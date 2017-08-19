# Insider

[![Build Status](https://travis-ci.org/alexmx/Insider.svg?branch=master)](https://travis-ci.org/alexmx/Insider)
[![Twitter: @amaimescu](https://img.shields.io/badge/contact-%40amaimescu-blue.svg)](https://twitter.com/amaimescu)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/alexmx/ios-ui-automation-overview/blob/master/LICENSE)

Insider is an utility framework which sets a **backdoor** into your app for testing tools like [Appium](http://appium.io/), [Calabash](http://calaba.sh/), [Frank](http://www.testingwithfrank.com/), etc. 

## Why do I need this?
* Set a particular state for the app during the test scenario;
* Simulate push notifications;
* Simulate app invocation using custom schemes / universal links;
* Simulate back-end responses;
* Manage files / directories in application sandbox;
* Collect metrics from the app during test execution (CPU, memory, etc.);
* etc.

Insider runs an HTTP server inside the application and listens for commands. By default Insider runs on `http://localhost:8080`. A command represents a simple HTTP request: `http://localhost:8080/<command>`

## Features

|  | Built-in Features | Commands | HTTP Method
------------ | ------------- | ------------- | -------------
💡 | Invoke a method on a registered **delegate** with given parameters; | `/invoke` | POST
📎 | Invoke a method on a registered **delegate** with given parameters and wait for response; | `/invokeForResponse` | POST
📢 | Send local notifications through **NSNotificationCenter** with given parameters; | `/notification` | POST
📱 | Get device system state information (CPU, memory, IP address, etc); | `/systemInfo` | GET
:floppy_disk: |  Manage files / directories in application sandbox (Documents, Library, tmp); | `/documents/<command>`<br /> `/library/<command>`<br /> `/tmp/<command>` | See the table below

Supported commands for file managing feature:

 File Managing Commands | HTTP Method 
------------ | ------------- 
List items: `/<directory>/list` | GET
Download items: `/<directory>/download`  | GET
Upload items: `/<directory>/upload`  | POST
Move items: `/<directory>/move`  | POST
Delete items: `/<directory>/delete`  | POST
Create folder: `/<directory>/create`  | POST

In the `scripts` directory can be found some sample ruby scripts which show the built-in features in action.

Check out the [API reference](http://alexmx.github.io/Insider/) for more information.

## Installation

#### Manual installation

In order to include the **Insider** library into your project, you need to build a dynamic framework from provided source code and include it into your project, or inlcude the entire **Insider** library as sub-project by copying it to your project directory or include as Git submodule.

#### Carthage

If you are using **Carthage**, you can always use it to build the library within your workspace by adding the line below to your `Cartfile`.

```
github "alexmx/Insider"
```

#### CocoaPods

If you are using **CocoaPods**, you can as well use it to integrate the library by adding the following lines to your `Podfile`.

```ruby
platform :ios, '8.0'
use_frameworks!

target 'YourAppTarget' do
    pod "Insider"
end

```

## Usage

#### Use case #1: Simulate Push Notifications

```swift

import Insider

class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        Insider.shared.start(withDelegate: self)
        
        return true
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) { 
  		// Process push notification 
  }
}

extension AppDelegate: InsiderDelegate {

  func insider(_ insider: Insider, invokeMethodWithParams params: JSONDictionary?) {
        // Simulate push notification
        application(UIApplication.shared, didReceiveRemoteNotification: params!)
  }
}

```
In order to test this example run `InsiderUseCases` application target, after go to `scripts` directory and run `invoke_method.rb` script.

#### Use case #2: Simulate app invocation using a custom scheme

```swift

import Insider

class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        Insider.shared.start(withDelegate: self)
        
        return true
  }
  
  func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        // Process custom scheme invocation
        return true
  }
}

extension AppDelegate: InsiderDelegate {

  func insider(_ insider: Insider, invokeMethodForResponseWithParams params: JSONDictionary?) -> JSONDictionary? {
        // Simulate app invokation using a custom scheme
        let url = URL(string: "insiderDemo://hello/params")
        let response = application(UIApplication.shared, handleOpen: url!)
        
        return ["response" as NSObject : response as AnyObject]
  }
}

```
In order to test this example run `InsiderUseCases` application target, after go to `scripts` directory and run `invoke_method_with_response.rb` script.

#### Use case #3: Get application system information during test execution

```swift
import Insider

class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        Insider.shared.start()
        
        return true
  }
}
```
As it is a built-in feature there is no need to set a delegate for Insider in this case. In order to test this example run `InsiderDemo` application target, after go to `scripts` directory and run `system_info.rb` script.

#### Use case #4: Add files to Documents folder in application sandbox.

```swift
import Insider

class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        Insider.shared.start()
        
        return true
  }
}
```
As it is a built-in feature there is no need to set a delegate for Insider in this case. 

There are 3 directories supported in application sandbox:
* **Documents**: `http://localhost:8080/documents`
* **Library**: `http://localhost:8080/library`
* **tmp**: `http://localhost:8080/tmp`

You can create new folders. Upload, download, move, remove files / folders from application sandbox. 

In order to test this example run `InsiderDemo` application target, and open [http://localhost:8080/documents](http://localhost:8080/documents), [http://localhost:8080/library](http://localhost:8080/library) or [http://localhost:8080/tmp](http://localhost:8080/tmp) url in your browser. You will see the files which are in your application sandbox.

![Insider](/assets/sandbox.png)

If you need to use the sandbox files managing API in your automation scripts please check **File Managing Commands** section above.

## Credits
**Insider** uses these amazing libaries under the hood:
* [GCDWebServer](https://github.com/swisspol/GCDWebServer)
* [iOS-System-Services](https://github.com/Shmoopi/iOS-System-Services)

## License
This project is licensed under the terms of the MIT license. See the LICENSE file.
