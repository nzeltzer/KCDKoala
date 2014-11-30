//
//  UITableView+KCDTableViewDataSource.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 10/31/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "UITableView+KCDKoala.h"
#import "KCDTableViewDataSource.h"

#pragma mark - UITableView+KCDKoala

@implementation UITableView (KCDKoala)

@dynamic KCDDataSource;

- (KCDTableViewDataSource *)KCDDataSource;
{
    if ([self.dataSource isKindOfClass:[KCDTableViewDataSource class]])
    {
        return (KCDTableViewDataSource*)[self dataSource];
    }
    return nil;
}

- (NSArray*)selectedTableViewObjects;
{
    return [[self KCDDataSource] selectedObjects];
}


NSString * KCDTableViewRowAnimationDescription(UITableViewRowAnimation rowAnimation)
{
    NSString *description = nil;
    switch (rowAnimation) {
        case UITableViewRowAnimationAutomatic:
            description = @"UITableViewRowAnimationAutomatic";
            break;
        case UITableViewRowAnimationBottom:
            description = @"UITableViewRowAnimationBottom";
            break;
        case UITableViewRowAnimationFade:
            description = @"UITableViewRowAnimationFade";
            break;
        case UITableViewRowAnimationLeft:
            description = @"UITableViewRowAnimationLeft";
            break;
        case UITableViewRowAnimationMiddle:
            description = @"UITableViewRowAnimationMiddle";
            break;
        case UITableViewRowAnimationNone:
            description = @"UITableViewRowAnimationNone";
            break;
        case UITableViewRowAnimationRight:
            description = @"UITableViewRowAnimationRight";
            break;
        case UITableViewRowAnimationTop:
            description = @"UITableViewRowAnimationTop";
            break;
        default:
            description = @"UITableViewRowAnimationNone";
            break;
    }
    return description;
}


@end
