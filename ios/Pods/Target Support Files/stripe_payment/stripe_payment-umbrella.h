#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "RCTConvert.h"
#import "StripePaymentPlugin.h"
#import "TPSError.h"
#import "TPSStripeManager+Constants.h"
#import "TPSStripeManager.h"

FOUNDATION_EXPORT double stripe_paymentVersionNumber;
FOUNDATION_EXPORT const unsigned char stripe_paymentVersionString[];

