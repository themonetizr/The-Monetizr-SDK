//
//  ActionableFooterView.h
//  Mobile Buy SDK
//
//  Created by Shopify.
//  Copyright (c) 2015 Shopify Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@import UIKit;
#import "CheckoutButton.h"
#import "UIButton+PaymentButton.h"
#import "ProductVariantView.h"

@interface ActionableFooterView : UIView

- (void)setApplePayAvailable:(BOOL)applePayAvailable requiresSetup:(BOOL)requiresSetup;

@property (nonatomic, readonly) CheckoutButton *actionButton;

/**
 *  On iOS 8.3+ this will be a PKPaymentButton
 */
@property (nonatomic, readonly) UIButton *paymentButton;

@property (nonatomic) BOOL buttonsEnabled;

/**
 *  A view which sits above the buttons.
 *  Can be used to add a description or other content to the footer.
 */
@property (nonatomic, readonly)  UIView *extensionView;

@property (nonatomic) PaymentButtonStyle paymentButtonStyle UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *separatorColor UI_APPEARANCE_SELECTOR;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *extensionViewHeight;

@end
