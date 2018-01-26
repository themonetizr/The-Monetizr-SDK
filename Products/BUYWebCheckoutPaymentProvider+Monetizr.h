//
//  BUYWebCheckoutPaymentProvider+Monetizr.h
//  Monetizr-SDK2-test
//
//  Created by Armands Avotins on 26/01/2018.
//  Copyright © 2018 E-Life PRO. All rights reserved.
//

#import <Buy/Buy.h>
#import <objc/runtime.h>

@interface BUYWebCheckoutPaymentProvider (Monetizr)

- (void)startCheckoutOverride:(BUYCheckout *)checkout;

@end
