//
//  UITableViewController+KCDKoala.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/11/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import UIKit;

#import "KCDTableViewDataSourceDelegate.h"

@class KCDTableViewDataSource;

@interface UITableViewController (KCDKoala) <KCDTableViewDataSourceDelegate>

@property (readonly) KCDTableViewDataSource *KCDDataSource;

- (instancetype)initWithStyle:(UITableViewStyle)style objects:(NSArray *)KCDObjects;

- (instancetype)initWithStyle:(UITableViewStyle)style sections:(NSArray *)KCDSections;

@end
