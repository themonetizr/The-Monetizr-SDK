//
//  BUYWebCheckoutPaymentProvider+Monetizr.m
//  Monetizr-SDK2-test
//
//  Created by Armands Avotins on 26/01/2018.
//  Copyright © 2018 E-Life PRO. All rights reserved.
//

#import "BUYWebCheckoutPaymentProvider+Monetizr.h"

@interface BUYWebCheckoutPaymentProvider (Private)

@property (nonatomic, strong) BUYCheckout *checkout;
@property (nonatomic, strong) BUYClient *client;
- (void)postCheckoutCompletion:checkout error:error;

@end

@implementation BUYWebCheckoutPaymentProvider (Private)

@dynamic checkout;
@dynamic client;
static void *AssociationKey;

- (id)somePrivateProperty
{
    return objc_getAssociatedObject(self, AssociationKey);
}

- (void)setSomePrivateProperty:(id)arg
{
    objc_setAssociatedObject(self, AssociationKey, arg, OBJC_ASSOCIATION_RETAIN);
}

@end

@implementation BUYWebCheckoutPaymentProvider (Monetizr)

#pragma mark - Method Swizzling
- (void)startCheckoutOverride:(BUYCheckout *)checkout
{
    if (self.isInProgress && ![checkout.token isEqual:self.checkout.token]) {
        return;
    }
    self.checkout = checkout;
    
    [self.client updateOrCreateCheckout:checkout completion:^(BUYCheckout *checkout, NSError *error) {
        [self postCheckoutCompletion:checkout error:error];
    }];
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL defaultSelector = @selector(startCheckout:);
        SEL swizzledSelector = @selector(startCheckoutOverride:);
        
        Method defaultMethod = class_getInstanceMethod(class, defaultSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL isMethodExists = !class_addMethod(class, defaultSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (isMethodExists) {
            method_exchangeImplementations(defaultMethod, swizzledMethod);
        }
        else {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(defaultMethod), method_getTypeEncoding(defaultMethod));
        }
    });
}

@end
