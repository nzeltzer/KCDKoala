//
//  UIViewController+KCDKoala.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/12/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import UIKit;

@class KCDObjectController;

@interface UIViewController (KCDKoala)

/**
 Adds an accessor for a KCDObjectController instance.
 */

@property (nonatomic, readwrite, strong) KCDObjectController *KCDObjectController;

@end
