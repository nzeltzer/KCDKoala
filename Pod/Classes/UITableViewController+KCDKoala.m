//
//  UITableViewController+KCDKoala.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/11/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "UITableViewController+KCDKoala.h"
#import "UIViewController+KCDKoala.h"
#import "KCDTableViewDataSource.h"

@implementation UITableViewController (KCDKoala)

@dynamic KCDDataSource;

- (instancetype)initWithStyle:(UITableViewStyle)style
                      objects:(NSArray *)KCDObjects;
{
    self = [self initWithStyle:style];
    if (self) {
        NSArray *sections = nil;
        if ([KCDObjects count] > 0) {
            id<KCDSection> sec = [KCDTableViewDataSource sectionWithName:nil objects:KCDObjects];
            sections = @[sec];
        }
        KCDTableViewDataSource *dataSource = [[KCDTableViewDataSource alloc]
                                              initWithDelegate:self
                                              sections:sections];
        [self setKCDObjectController:dataSource];
        [dataSource setTableView:self.tableView];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
                     sections:(NSArray *)KCDSections;
{
    self = [self initWithStyle:style];
    if (self) {
        KCDTableViewDataSource *dataSource = [[KCDTableViewDataSource alloc]
                                              initWithDelegate:self
                                              sections:KCDSections];
        [self setKCDObjectController:dataSource];
        [dataSource setTableView:self.tableView];
    }
    return self;
}

- (KCDTableViewDataSource *)KCDDataSource;
{
    KCDTableViewDataSource * controller = nil;
    if (!(controller = (KCDTableViewDataSource *)[self KCDObjectController]) ||
        ![controller isKindOfClass:[KCDTableViewDataSource class]]) {
        return nil;
    }
    return controller;
}

@end
