//
//  ProductViewController.m
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

#import "ProductViewController.h"

#import "GradientView.h"
#import "AsyncImageView.h"
#import "OptionSelectionNavigationController.h"
#import "ProductViewPresentationController.h"
#import "ImageKit.h"
#import "ProductView.h"
#import "ProductHeaderCell.h"
#import "ProductDescriptionCell.h"
#import "ProductViewHeader.h"
#import "ProductImageCell.h"
#import "HeaderBackgroundView.h"
#import "HeaderOverlayView.h"
#import "ProductViewNavigationController.h"
#import "Theme+Additions.h"
#import "VariantSelectionViewController.h"
#import "CheckoutButton.h"
#import "ActionableFooterView.h"

CGFloat const BUYMaxProductViewWidth = 414.0; // We max out to the width of the iPhone 6+
CGFloat const BUYMaxProductViewHeight = 640.0;

@interface ProductViewController (Private)

@property (nonatomic, strong) BUYWebCheckoutPaymentProvider *webPaymentProvider;
@property (nonatomic, strong) BUYApplePayPaymentProvider *applePayPaymentProvider;

@end

@interface ProductViewController () <UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, VariantSelectionDelegate, ProductViewNavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) NSString *productId;
@property (nonatomic, strong) BUYProductVariant *selectedProductVariant;
@property (nonatomic, assign) NSUInteger selectedVariant;
@property (nonatomic, strong) Theme *theme;
@property (nonatomic, assign) BOOL hidesStatusBar;
@property (nonatomic, assign) BOOL shouldShowVariantSelector;
@property (nonatomic, assign) BOOL shouldEnableVariantSelection;
@property (nonatomic, assign) BOOL shouldShowDescription;
@property (nonatomic, strong) BUYProduct *product;
@property (nonatomic, strong) NSNumberFormatter *currencyFormatter;
@property (nonatomic, weak) BUYCart *cart;

// views
@property (nonatomic, strong) ProductView *productView;
@property (nonatomic, weak) UIView *navigationBar;
@property (nonatomic, weak) UILabel *navigationBarTitle;
@property (nonatomic, strong) ProductHeaderCell *headerCell;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

// Share items
@property (nonatomic, strong, readonly) NSString *titleForSharing;
@property (nonatomic, strong, readonly) NSURL *URLForSharing;
@property (nonatomic, strong, readonly) UIImage *imageForSharing;
@property (nonatomic, strong, readonly) NSArray *itemsForSharing;

@end

@implementation ProductViewController

- (instancetype)initWithClient:(BUYClient *)client
{
	self = [super initWithClient:client];
	if (self) {
		self.modalPresentationStyle = UIModalPresentationCustom;
		self.transitioningDelegate = self;
		
		_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
		_activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
		_activityIndicatorView.hidesWhenStopped = YES;
		[_activityIndicatorView startAnimating];
		[self.view addSubview:_activityIndicatorView];
		
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicatorView
															  attribute:NSLayoutAttributeCenterY
															  relatedBy:NSLayoutRelationEqual
																 toItem:self.view
															  attribute:NSLayoutAttributeCenterY
															 multiplier:1.0
															   constant:0.0]];
		
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicatorView
															  attribute:NSLayoutAttributeCenterX
															  relatedBy:NSLayoutRelationEqual
																 toItem:self.view
															  attribute:NSLayoutAttributeCenterX
															 multiplier:1.0
															   constant:0.0]];

	}
	return self;
}

- (instancetype)initWithClient:(BUYClient *)client theme:(Theme *)theme
{
	NSParameterAssert(client);

	self = [self initWithClient:client];
	if (self) {
		if (theme == nil) {
			theme = [Theme new];
		}
        self.hidesStatusBar = theme.hidesStatusBar;
		[theme styleProductViewController];
	}
	return self;
}

- (instancetype)initWithClient:(BUYClient *)client cart:(BUYCart *)cart
{
	NSParameterAssert(cart);
	
	self = [self initWithClient:client];
	
	if (self) {
		self.cart = cart;
	}
	
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (CGSize)preferredContentSize
{
	return CGSizeMake(MIN(BUYMaxProductViewWidth, self.view.bounds.size.width),
					  MIN(BUYMaxProductViewHeight, self.view.bounds.size.height));
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self setupNavigationBarAppearance];
	[self.navigationController setNavigationBarHidden:(self.presentingViewController && self.isLoading)];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Set Voice Over focus to the summary element
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.headerCell);
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	if (self.productView.hasSetVariantOnCollectionView == NO) {
		if ([self canCollectionViewDrawProductImages] || [self.product.images count] == 0) {
			[self setSelectedProductVariant:self.selectedProductVariant];
			self.productView.hasSetVariantOnCollectionView = YES;
		}
	}
}

- (BOOL)canCollectionViewDrawProductImages
{
	return [self.product.images count] > 0 && CGSizeEqualToSize(self.productView.productViewHeader.collectionView.bounds.size, CGSizeZero) == NO;
}

- (void)setupNavigationBarAppearance
{
	if (self.navigationBar == nil && _productView && self.presentingViewController != nil) {
		for (UIView *view in [self.navigationController.navigationBar subviews]) {
			if (CGRectGetHeight(view.bounds) >= 44) {
				// Get a reference to the UINavigationBar
				self.navigationBar = view;
				self.navigationBar.alpha = 0;
				break;
			} else if ([view.subviews count] == 1 && [view.subviews[0] isKindOfClass:[UILabel class]]) {
				// Get a reference to the UINavigationBar's title
				self.navigationBarTitle = view.subviews[0];
				self.navigationBarTitle.alpha = 0;
				continue;
			}
		}
		// Hide the navigation bar
		[self scrollViewDidScroll:self.productView.tableView];
	} else if (self.navigationController && _productView && self.presentingViewController == nil) {
		[self.productView setTopInset:CGRectGetHeight(self.navigationController.navigationBar.bounds) + self.navigationController.topLayoutGuide.length];
	}
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
	ProductViewPresentationController *presentationController = [[ProductViewPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
	presentationController.delegate = presentationController;
	presentationController.navigationDelegate = self;
	return presentationController;
}

- (void)loadWithProduct:(BUYProduct *)product completion:(void (^)(BOOL success, NSError *error))completion
{
    self.product = product;

	if (product == nil) {
		completion(NO, [NSError errorWithDomain:BUYShopifyError code:BUYShopifyError_NoProductSpecified userInfo:nil]);
	} else {
		if (self.shop == nil) {
			[self getShopWithCallback:^(BOOL success, NSError *error) {
                [self.activityIndicatorView stopAnimating];
				if (completion) {
					completion(success, error);
				}
			}];
		} else {
			self.product = product;
			dispatch_async(dispatch_get_main_queue(), ^{
                [self.activityIndicatorView stopAnimating];
				if (completion) {
					completion(YES, nil);
				}
			});
		}
	}
}

- (void)loadWithProduct:(BUYProduct *)product forDevice: (NSString *)deviceName completion:(void (^)(BOOL success, NSError *error))completion
{
    self.product = product;

    if (product == nil) {
        completion(NO, [NSError errorWithDomain:BUYShopifyError code:BUYShopifyError_NoProductSpecified userInfo:nil]);
    } else {
        // Loop thru varinats and find apropriate one
        NSOrderedSet *variants = product.variants;
        int variantIndex = 0;
        for (BUYProductVariant *variant in variants) {
            // Get SKU
            NSString *sku = variant.sku;
            if ([sku isEqualToString:deviceName]) {
                variantIndex = (int)[variants indexOfObject:variant];
            }
        }
        if (self.shop == nil) {
            [self getShopWithCallback:^(BOOL success, NSError *error) {
                self.selectedVariant = variantIndex;
                self.product = product;
                [self.activityIndicatorView stopAnimating];
                if (completion) {
                    completion(success, error);
                }
            }];
        } else {
            self.selectedVariant = variantIndex;
            self.product = product;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.activityIndicatorView stopAnimating];
                if (completion) {
                    completion(YES, nil);
                }
            });
        }
    }
}

- (void)getShopWithCallback:(void (^)(BOOL, NSError *))block
{
	// fetch shop details for the currency and country codes
	[self.client getShop:^(BUYShop *shop, NSError *error) {
		
		if (error == nil) {
			self.shop = shop;
            [self createProductView];
		}
		else {
			if ([self.delegate respondsToSelector:@selector(controllerFailedToStartApplePayProcess:)]) {
				[self.delegate controllerFailedToStartApplePayProcess:self];
			}
		}

        [self.activityIndicatorView stopAnimating];
		if (block) block((error == nil), error);
	}];
}

- (void)setProduct:(BUYProduct *)product
{
	_product = product;
    
	//self.selectedProductVariant = [_product.variants firstObject];
    NSUInteger variantIndex = _selectedVariant;
    self.selectedProductVariant = [_product.variants objectAtIndex:variantIndex];
    self.shouldShowVariantSelector = [_product isDefaultVariant] == NO;
    self.shouldEnableVariantSelection = self.shouldShowVariantSelector && [_product.variants count] > 1;
	self.shouldShowDescription = ([_product.htmlDescription length] == 0) == NO;
	[self setNeedsStatusBarAppearanceUpdate];
	if (self.presentingViewController) {
		[self.navigationController setNavigationBarHidden:NO];
	}
	
	if (self.theme.showsProductShareButton && self.URLForSharing && (!self.navigationItem.rightBarButtonItems || self.navigationItem.rightBarButtonItems.count < 1)) {
		UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareLink)];
        rightButton.accessibilityValue = NSLocalizedString(@"share", @"VoiceOver value for share button");
        self.navigationItem.rightBarButtonItem = rightButton;
	}
}

- (void)setShop:(BUYShop *)shop
{
	[super setShop:shop];
	self.currencyFormatter = [[NSNumberFormatter alloc] init];
	self.currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
	self.currencyFormatter.currencyCode = shop.currency;
}

- (void)createProductView
{
    _productView = [[ProductView alloc] initWithFrame:CGRectMake(0, 0, self.preferredContentSize.width, self.preferredContentSize.height) product:self.product shouldShowApplePaySetup:self.shouldShowApplePaySetup];
    _productView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_productView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_productView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_productView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_productView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_productView)]];
    
    _productView.tableView.delegate = self;
    _productView.tableView.dataSource = self;
    [_productView.productViewFooter setApplePayAvailable:self.shouldShowApplePayButton requiresSetup:self.shouldShowApplePaySetup];
    [_productView.productViewFooter.paymentButton addTarget:self action:@selector(checkoutWithApplePay) forControlEvents:UIControlEventTouchUpInside];
    
    // Setup variant view
    
    if (self.shouldShowVariantSelector) {
        ProductVariantView *variantView = [[ProductVariantView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 55)]; //self.preferredContentSize.width
        if (self.shouldEnableVariantSelection) {
            [variantView setOptionsForProductVariant:self.selectedProductVariant hideDisclosureIndicator:NO];
            UITapGestureRecognizer *variantSelectorFingerTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(openVariantSelector)];
            [_productView.productViewFooter.extensionView addGestureRecognizer:variantSelectorFingerTap];
        }
        if (!self.shouldEnableVariantSelection) {
            [variantView setOptionsForProductVariant:self.selectedProductVariant hideDisclosureIndicator:NO];
        }
        [_productView.productViewFooter.extensionView addSubview:variantView];
    }
    if (!self.shouldShowVariantSelector) {
         _productView.productViewFooter.extensionViewHeight.constant = 0;
    }
    
    if (self.cart) {
        [_productView.productViewFooter.actionButton setTitle:NSLocalizedString(@"Add to Cart", nil) forState:UIControlStateNormal];
        [_productView.productViewFooter.actionButton addTarget:self action:@selector(addSelectedVariantToCart) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        [_productView.productViewFooter.actionButton setTitle:NSLocalizedString(@"Payment methods", nil) forState:UIControlStateNormal];
        [_productView.productViewFooter.actionButton addTarget:self action:@selector(checkoutWithShopify) forControlEvents:UIControlEventTouchUpInside];
    }
    _productView.productViewHeader.collectionView.delegate = self;
    _productView.productViewHeader.collectionView.dataSource = self;
    
    int bottom = self.bottomLayoutGuide.length;
    bottom = bottom-bottom-bottom;
    
    _productView.layoutMargins = UIEdgeInsetsMake(self.productView.layoutMargins.top, self.productView.layoutMargins.left, bottom, self.productView.layoutMargins.right);
    [_productView.productViewFooter setApplePayAvailable:self.shouldShowApplePayButton requiresSetup:self.shouldShowApplePaySetup];
    [_productView.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];

    //self.navigationItem.title = _product.title;
    [self setupNavigationBarAppearance];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger rows = 0;
	if (self.product) {
		rows += 1; // product title and price
		rows += self.shouldShowDescription;
	}
	return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *theCell = nil;
	
	if (indexPath.row == 0) {
		ProductHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"headerCell"];
		[cell setProductVariant:self.selectedProductVariant withCurrencyFormatter:self.currencyFormatter];
		self.headerCell = cell;
		theCell = cell;
	} else if ((indexPath.row == 1 && self.shouldShowDescription) || (indexPath.row == 1 && self.shouldShowVariantSelector == NO && self.shouldShowDescription)) {
		ProductDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"descriptionCell"];
		cell.descriptionHTML = self.product.htmlDescription;
		cell.separatorInset = UIEdgeInsetsMake(0, CGRectGetWidth(self.productView.tableView.bounds), 0, 0);
		theCell = cell;
	}
	
	return theCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - BUYVariantSelection

- (void)openVariantSelector {
    VariantSelectionViewController *optionSelectionViewController = [[VariantSelectionViewController alloc] initWithProduct:self.product];
    optionSelectionViewController.selectedProductVariant = self.selectedProductVariant;
    optionSelectionViewController.delegate = self;
    optionSelectionViewController.currencyFormatter = self.currencyFormatter;
    OptionSelectionNavigationController *optionSelectionNavigationController = [[OptionSelectionNavigationController alloc] initWithRootViewController:optionSelectionViewController];
    [self presentViewController:optionSelectionNavigationController animated:YES completion:nil];
}

#pragma mark - BUYVariantSelectionViewControllerDelegate

- (void)variantSelectionController:(VariantSelectionViewController *)controller didSelectVariant:(BUYProductVariant *)variant
{
	if (self.selectedProductVariant != variant) {
		self.selectedProductVariant = variant;
		[self.productView.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	[self dismissViewControllerAnimated:YES completion:^{
		[self setNeedsStatusBarAppearanceUpdate];
		[self scrollViewDidScroll:self.productView.tableView];
	}];
}

- (void)variantSelectionControllerDidCancelVariantSelection:(VariantSelectionViewController *)controller atOptionIndex:(NSUInteger)optionIndex
{
	[self dismissViewControllerAnimated:YES completion:^{
		[self setNeedsStatusBarAppearanceUpdate];
	}];
}

- (void)setSelectedProductVariant:(BUYProductVariant *)selectedProductVariant {
	_selectedProductVariant = selectedProductVariant;
	if (self.headerCell) {
		[self.headerCell setProductVariant:selectedProductVariant withCurrencyFormatter:self.currencyFormatter];
        for (ProductVariantView *variantView in _productView.productViewFooter.extensionView.subviews) {
            if ([variantView isKindOfClass:[ProductVariantView class]]) {
                for (UIGestureRecognizer *recognizer in _productView.productViewFooter.extensionView.gestureRecognizers) {
                    [_productView.productViewFooter.extensionView removeGestureRecognizer:recognizer];
                }
                if (self.shouldEnableVariantSelection) {
                    [variantView setOptionsForProductVariant:self.selectedProductVariant hideDisclosureIndicator:NO];
                    UITapGestureRecognizer *variantSelectorFingerTap =
                    [[UITapGestureRecognizer alloc] initWithTarget:self
                                                            action:@selector(openVariantSelector)];
                    [_productView.productViewFooter.extensionView addGestureRecognizer:variantSelectorFingerTap];
                }
                if (!self.shouldEnableVariantSelection) {
                    [variantView setOptionsForProductVariant:self.selectedProductVariant hideDisclosureIndicator:YES];
                }
            }
        }
	}
	if (self.productView.productViewHeader.collectionView) {
		[self.productView.productViewHeader setImageForSelectedVariant:_selectedProductVariant withImages:[self.product.images array]];
		[self.productView updateBackgroundImage:[self.product.images array]];
	}
	if (self.productView.productViewFooter) {
		self.productView.productViewFooter.actionButton.enabled = selectedProductVariant.available.boolValue;
		self.productView.productViewFooter.paymentButton.enabled = selectedProductVariant.available.boolValue;
	}
	if (self.productView.tableView) {
		[self scrollViewDidScroll:self.productView.tableView];
	}
}

#pragma mark Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Dismiss if needed
    CGPoint offset = scrollView.contentOffset;
    if (offset.y < -self.view.frame.size.height/3) {
        // Dismiss
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    // Do sizing
	if ([scrollView isKindOfClass:[UITableView class]]) {
		if (self.productView.productViewHeader) {
			[self.productView scrollViewDidScroll:scrollView];
			if (self.navigationBar) {
				CGFloat duration = 0.3f;
				if (self.navigationBar.alpha != 1 && [self navigationBarThresholdReached] == YES) {
					[UIView animateWithDuration:duration
										  delay:0
										options:(UIViewAnimationOptionCurveLinear | UIViewKeyframeAnimationOptionBeginFromCurrentState)
									 animations:^{
										 [self setNeedsStatusBarAppearanceUpdate];
										 self.navigationBar.alpha = 1;
										 self.navigationBarTitle.alpha = 1;
									 }
									 completion:NULL];
				} else if (self.navigationBar.alpha != 0 && [self navigationBarThresholdReached] == NO)  {
					duration = 0.2f;
					[UIView animateWithDuration:duration
										  delay:0
										options:(UIViewAnimationOptionCurveLinear | UIViewKeyframeAnimationOptionBeginFromCurrentState)
									 animations:^{
										 [self setNeedsStatusBarAppearanceUpdate];
										 self.navigationBar.alpha = 0;
										 self.navigationBarTitle.alpha = 0;
									 }
									 completion:NULL];
				}
				[self.productView.productViewHeader.productViewHeaderOverlay scrollViewDidScroll:scrollView withNavigationBarHeight:CGRectGetHeight(self.navigationBar.bounds)];
			}
		} else if (self.productView.productViewHeader == nil && self.navigationBar && self.navigationBar.alpha == 0) {
			self.navigationBar.alpha = 1;
			self.navigationBarTitle.alpha = 1;
			CGFloat topInset = 0;
			if (self.presentingViewController) {
				topInset = CGRectGetHeight([[(UINavigationController*)self.presentingViewController navigationBar] bounds]) + self.presentingViewController.topLayoutGuide.length;
			}
			[self.productView setInsets:UIEdgeInsetsMake(topInset, 0, 0, 0) appendToCurrentInset:YES];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	if ([scrollView isKindOfClass:[UICollectionView class]]) {
		[self.productView updateBackgroundImage:[self.product.images array]];
	}
}

#pragma mark Checkout

- (void)addSelectedVariantToCart
{
	[self.cart addVariant:self.selectedProductVariant];
}

- (void)checkoutWithApplePay
{
	if (self.isApplePayAvailable) {
		
		self.checkout = [self checkoutWithVariant:self.selectedProductVariant];
		[self startApplePayCheckout:self.checkout];

	} else {
		[[[PKPassLibrary alloc] init] openPaymentSetup];
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
	}
}

- (void)checkoutWithShopify
{
	self.checkout = [self checkoutWithVariant:self.selectedProductVariant];
	[self startWebCheckout:self.checkout];
}

- (BUYCheckout *)checkoutWithVariant:(BUYProductVariant *)variant
{
	BUYModelManager *modelManager = self.client.modelManager;
	BUYCart *cart = [modelManager insertCartWithJSONDictionary:nil];
	[cart addVariant:variant];
	return [modelManager checkoutWithCart:cart];
}

#pragma mark UIStatusBar appearance

-(BOOL)prefersStatusBarHidden{
    BOOL prefersStatusBarHidden = self.hidesStatusBar;
    return prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	if (self.navigationController.navigationBar.barStyle == UIBarStyleBlack || ([self navigationBarThresholdReached] == NO && self.productView.productViewHeader)) {
		return UIStatusBarStyleLightContent;
	} else if (self.navigationController.navigationBar.barStyle == UIBarStyleBlack && self.productView.productViewHeader) {
		return UIStatusBarStyleLightContent;
	} else {
		return UIStatusBarStyleDefault;
	}
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
	return UIStatusBarAnimationFade;
}

- (BOOL)navigationBarThresholdReached
{
	return self.productView.tableView.contentOffset.y > CGRectGetHeight(self.productView.productViewHeader.bounds) - CGRectGetHeight(self.navigationBar.bounds);
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController
{
	
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController
{
	if ([self.delegate respondsToSelector:@selector(didDismissViewController:)]) {
		[self.delegate didDismissViewController:self];
	}
	
	_product = nil;
	_productId = nil;
	[_productView removeFromSuperview];
	_productView = nil;
}

#pragma mark - Collection View Delegate and Datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [self.product.images count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ProductImageCell *cell = (ProductImageCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
	BUYImageLink *image = self.product.images[indexPath.row];
	[cell.productImageView loadImageWithURL:image.sourceURL completion:NULL];
	[cell setContentOffset:self.productView.tableView.contentOffset];
	
	return cell;
}

- (void)presentPortraitInViewController:(UIViewController *)controller
{
	ProductViewNavigationController *navController = [[ProductViewNavigationController alloc] initWithRootViewController:self];
	navController.modalPresentationStyle = [ProductViewPresentationController adaptivePresentationStyle];
	navController.navigationDelegate = self;
	[controller presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Share sheet

- (void)shareLink
{
	UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:self.itemsForSharing applicationActivities:nil];
	[self presentViewController:activityController animated:YES completion:nil];
}

- (NSString *)titleForSharing
{
	return self.product.title;
}

- (NSURL *)URLForSharing
{
    if (self.shop.domain && self.product.handle) {
        NSString *urlString = [NSString stringWithFormat:@"%@/products/%@", self.shop.domain, self.product.handle];
        return [NSURL URLWithString:urlString];
    }

    return nil;
}

- (UIImage *)imageForSharing
{
	UICollectionView *collectionView = self.productView.productViewHeader.collectionView;
	NSIndexPath *selectedIndex = collectionView.indexPathsForVisibleItems.firstObject;
	ProductImageCell *cell = (ProductImageCell *)[collectionView cellForItemAtIndexPath:selectedIndex];
	return cell.productImageView.image;
}

- (NSArray *)itemsForSharing
{
	return [NSArray arrayWithObjects:self.titleForSharing, self.URLForSharing, self.imageForSharing, nil];
}

#pragma mark - Payment delegate methods

- (void)willStartCheckout
{
	[_productView.productViewFooter.actionButton showActivityIndicator:NO];

	if ([self.delegate respondsToSelector:@selector(controllerWillCheckoutViaWeb:)]) {
		[self.delegate controllerWillCheckoutViaWeb:self];
	}
}

- (void)didFailCheckoutWithError:(NSError *)error
{
	[_productView.productViewFooter.actionButton showActivityIndicator:NO];
	[self.productView showErrorWithMessage:@"Could not checkout at this time"];

	if ([self.delegate respondsToSelector:@selector(controller:failedToCreateCheckout:)]) {
		[self.delegate controller:self failedToCreateCheckout:error];
	}
}

#pragma mark - Accessibility

//- (BOOL) accessibilityPerformEscape {
//    self
//}

@end
