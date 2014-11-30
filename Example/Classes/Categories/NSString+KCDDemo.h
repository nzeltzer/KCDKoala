//
//  NSString+KCDDemo.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/13/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

@import UIKit;

#import <KCDKoala/KCDKoala.h>

/**
 A simple example of how an object can adopt the KCDObjects through a category.
 */

@interface NSString (KCDDemo) <KCDCollectionViewObject, KCDTableViewObject>

@end
