//
//  UIViewController+Utilities.m
//  Created by Pierluigi Cifani on 18/04/2019.
//

#include <TargetConditionals.h>

#if TARGET_OS_IOS

#import "UIViewController+Utilities.h"
#import <objc/runtime.h>

@implementation UIViewController (Utilities)
    
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzle:@selector(viewDidLayoutSubviews)
           withCustom:@selector(bsw_viewDidLayoutSubviews)];

        [self swizzle:@selector(viewWillTransitionToSize:withTransitionCoordinator:)
           withCustom:@selector(bsw_viewWillTransitionToSize:withTransitionCoordinator:)];

        [self swizzle:@selector(willTransitionToTraitCollection:withTransitionCoordinator:)
           withCustom:@selector(bsw_willTransitionToTraitCollection:withTransitionCoordinator:)];
    });
}
    
+ (void)swizzle:(SEL)originalSelector withCustom:(SEL)customSelector {
    
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(self, customSelector);
    
    BOOL didAddMethod =
    class_addMethod(self,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(self,
                            customSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

#pragma mark willTransitionToTraitCollection:withTransitionCoordinator:

- (void)bsw_willTransitionToTraitCollection:(UITraitCollection *)newCollection
                  withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self bsw_willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    if ([self bsw_regularConstraints] == nil || [self bsw_compactConstraints] == nil) {
        return;
    }
    if (self.traitCollection.horizontalSizeClass == newCollection.horizontalSizeClass) {
        return;
    }
    switch (newCollection.horizontalSizeClass) {
        case UIUserInterfaceSizeClassCompact:
            {
                [NSLayoutConstraint deactivateConstraints:[self bsw_regularConstraints]];
                [NSLayoutConstraint activateConstraints:[self bsw_compactConstraints]];
            }
            break;
        case UIUserInterfaceSizeClassRegular:
        {
            [NSLayoutConstraint deactivateConstraints:[self bsw_compactConstraints]];
            [NSLayoutConstraint activateConstraints:[self bsw_regularConstraints]];
        }
            break;
        default:
            break;
    }
}

#pragma mark viewWillTransitionToSize:withTransitionCoordinator:

- (void)bsw_viewWillTransitionToSize:(CGSize)size
           withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [self bsw_viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIView *loadedView = [self viewIfLoaded];
    if (loadedView == nil) {
        return;
    }
    UIView *firstView = [[loadedView subviews] firstObject];
    if (![firstView isKindOfClass:[UICollectionView class]]) {
        return;
    }
    UICollectionView *collectionView = (UICollectionView *)firstView;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [[collectionView collectionViewLayout] invalidateLayout];
        [collectionView reloadData];
    } completion:nil];
}

#pragma mark viewDidLayoutSubviews
    
- (void)bsw_viewDidLayoutSubviews {
    [self bsw_viewDidLayoutSubviews];
    NSNumber *originalFirstLayoutPassed = [self bsw_firstLayoutPassed];
    [self setBSWFirstLayoutPassed:@YES];
    if (originalFirstLayoutPassed == nil) {
        [self viewInitialLayoutDidComplete];
    }
}
    
- (void)setBSWFirstLayoutPassed:(NSNumber *)firstLayoutPassed {
    objc_setAssociatedObject(self, @selector(bsw_firstLayoutPassed), firstLayoutPassed, OBJC_ASSOCIATION_COPY);
}
    
- (NSNumber *)bsw_firstLayoutPassed {
    return objc_getAssociatedObject(self, @selector(bsw_firstLayoutPassed));
}
    
- (void)viewInitialLayoutDidComplete {
    // To be overriden by subclasses
}

#pragma mark Regular / Compact helpers

- (void)setBSWRegularConstraints:(NSArray<NSLayoutConstraint *>*)constraints {
    objc_setAssociatedObject(self, @selector(bsw_regularConstraints), constraints, OBJC_ASSOCIATION_COPY);
}
    
- (NSArray<NSLayoutConstraint *>*)bsw_regularConstraints {
    return objc_getAssociatedObject(self, @selector(bsw_regularConstraints));
}

- (void)setBSWCompactConstraints:(NSArray<NSLayoutConstraint *>*)constraints {
    objc_setAssociatedObject(self, @selector(bsw_compactConstraints), constraints, OBJC_ASSOCIATION_COPY);
}
    
- (NSArray<NSLayoutConstraint *>*)bsw_compactConstraints {
    return objc_getAssociatedObject(self, @selector(bsw_compactConstraints));
}

- (void)addConstraintsForHorizontalCompactSizeClass:(NSArray<NSLayoutConstraint *>*)compactConstraints
                                   regularSizeClass:(NSArray<NSLayoutConstraint *>*)regularConstraints {
    [self setBSWCompactConstraints:compactConstraints];
    [self setBSWRegularConstraints:regularConstraints];
    switch (self.traitCollection.horizontalSizeClass) {
        case UIUserInterfaceSizeClassCompact:
            [NSLayoutConstraint activateConstraints:[self bsw_compactConstraints]];
            break;
        case UIUserInterfaceSizeClassRegular:
            [NSLayoutConstraint activateConstraints:[self bsw_regularConstraints]];
            break;
        default:
            break;
    }
}

@end

#endif
