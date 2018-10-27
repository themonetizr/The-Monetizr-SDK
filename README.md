[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)]()
![GitHub release](https://img.shields.io/badge/release-1.2.7-blue.svg)

# TheMonetizr SDK for iOS
TheMonetizr SDK makes it simple to sell physical products inside your mobile app. With a few lines of code, you can let your users buy products using Apple Pay or their credit card.

TheMonetizr SDK requires Shopify’s [Mobile Buy SDK](https://github.com/Shopify/mobile-buy-sdk-ios) distributed under MIT license

### Documentation
Official documentation can be found on the [TheMonetizr website](http://themonetizr.com).

### Installation
[Install Shopify’s Mobile Buy SDK](https://github.com/Shopify/mobile-buy-sdk-ios#installation)

[Install AFNetworking 3.x](https://github.com/AFNetworking/AFNetworking#installation)

<a href="https://github.com/themonetizr/The-Monetizr-SDK">Download TheMonetizr</a>

Add Monetizr-SDK to your Xcode project.

### Quick Start

* Import the header

```objc
#import "Monetizr.h";
```
* Setup and enable Apple Pay in your project (Optional)

Find setup instructions on [Apple developer website](https://developer.apple.com/apple-pay/) and [The Monetizr website](http://themonetizr.com/implementation/). Use Certificate Signing Request (CSR) provided by TheMonetizr.

* Configure Monetizr.plist

```objc
@{
    @"apiUrl": @"", // Provided by TheMonetizr
    @"applePayMerchantId": @"", // Optional
    @"appId": @"", // Provided by TheMonetizr
    @"shopDomain": @"", // Provided by TheMonetizr
    @"apiKey": @"", // Provided by TheMonetizr 
    @"developerApiKey": @"", // Provided by TheMonetizr 
};
```

* To open product view using Product ID

```objc
[Monetizr showProductWithID:@"Provided product ID"]
```
* To open product view using Product ID and get callback

```objc
[Monetizr showProductWithID:@"11645793606" completion:^(BOOL success, NSError *error)]
```

* To open product view using Product TAG

```objc
[Monetizr showProductForTag:@"TAG" forUser:@"user"]
```
* To open product view using Product TAG and get callback

```objc
[Monetizr showProductForTag:@"TAG" forUser:@"user" completion:^(BOOL success, NSError *error)]
```
### Help

For help, please contact [TheMonetizr](http://themonetizr.com).

### License

TheMonetizr SDK is provided under an MIT Licence.  See the [LICENSE](LICENSE) file
