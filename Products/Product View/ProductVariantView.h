//
//  ProductVariantView.h
//
//  Monetizr SDK
//
//  Created by Monetizr.
//  Copyright (c) 2017 Monetizr Inc. All rights reserved.
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

//#import <UIKit/UIKit.h>
@import UIKit;
@import Buy;

#import "DisclosureIndicatorView.h"
#import "ImageKit.h"
#import "Theme+Additions.h"
#import "VariantOptionView.h"

@interface ProductVariantView : UIView

@property (nonatomic, strong) VariantOptionView *optionView1;
@property (nonatomic, strong) VariantOptionView *optionView2;
@property (nonatomic, strong) VariantOptionView *optionView3;
@property (nonatomic, strong) NSArray *constraints;
@property (nonatomic, strong) DisclosureIndicatorView *disclosureIndicatorImageView;

/**
 *  Set the options for a product variant
 *
 *  @param productVariant The selected product variant
 */
- (void)setOptionsForProductVariant:(BUYProductVariant *)productVariant hideDisclosureIndicator:(BOOL)hide;

@end
