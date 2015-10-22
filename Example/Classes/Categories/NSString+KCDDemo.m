//
//  NSString+KCDDemo.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/13/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

#import "NSString+KCDDemo.h"
#import "KCDDemoTableViewCell.h"

@implementation NSString (KCDDemo)

#pragma mark - KCDObject

- (NSString *)identifier;
{
    return NSStringFromClass([NSString class]);
}

#pragma mark - KCDCollectionViewProtocol

- (KCDDemoTableCollectionViewCell *)cellForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;
{
    KCDDemoTableCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.identifier forIndexPath:indexPath];
    cell.title = [self copy];
    return cell;
}

- (CGSize)sizeForCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout;
{
    return [KCDDemoTableCollectionViewCell drawTitle:self inRect:(CGRect){ .size = CGSizeMake(collectionView.bounds.size.width*0.4, CGFLOAT_MAX) } context:NULL];
}

#pragma mark - KCDTableViewObjectProtocol

- (UITableViewCell *)cellForTableView:(UITableView *)tableView;
{
    KCDDemoTableViewCell *cell = nil;
    if (!(cell = [tableView dequeueReusableCellWithIdentifier:self.identifier])) {
        cell = [[KCDDemoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.identifier];
    }
    cell.title = [self copy];
    return cell;
}

- (CGFloat)heightForCellInTableView:(UITableView *)tableView;
{
    CGRect bounding = (CGRect){ .size = CGSizeMake(tableView.frame.size.width, CGFLOAT_MAX) };
    CGFloat height = [KCDDemoTableViewCell drawTitle:self inRect:bounding context:NULL].height;
    return height;
}

@end
