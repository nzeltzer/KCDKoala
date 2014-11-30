//
//  UIViewController+KCDKoala.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/12/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "UIViewController+KCDKoala.h"
#import <objc/runtime.h>

@implementation UIViewController (KCDKoala)

char const * kKCDObjectControllerKey = "kKCDObjectControllerKey";

- (void)setKCDObjectController:(KCDObjectController *)KCDObjectController;
{
    objc_setAssociatedObject(self, kKCDObjectControllerKey, KCDObjectController, OBJC_ASSOCIATION_RETAIN);
}

- (KCDObjectController *)KCDObjectController;
{
    return objc_getAssociatedObject(self, kKCDObjectControllerKey);
}


@end
