//
//  UIColor+KCDDemo.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/13/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

#import "UIColor+KCDDemo.h"

@implementation UIColor (KCDDemo)

#pragma mark - KCDObject

- (BOOL)canEdit;
{
    return YES;
}

- (BOOL)canMove;
{
    return YES;
}

- (NSString *)identifier;
{
    return NSStringFromClass([UIColor class]);
}

#pragma mark - KCDCollectionViewObjectProtocol

- (UICollectionViewCell *)cellForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.identifier forIndexPath:indexPath];
    cell.backgroundColor = self;
    return cell;
}

- (CGSize)sizeForCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout;
{
    return CGSizeMake(44.0f, 44.0f);
}

#pragma mark - KCDTableViewObjectProtocol

- (UITableViewCell *)cellForTableView:(UITableView *)tableView;
{
    UITableViewCell *cell = nil;
    if (!(cell = [tableView dequeueReusableCellWithIdentifier:self.identifier])) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.identifier];
    }
    cell.backgroundColor = self;
    return cell;
}

- (CGFloat)heightForCellInTableView:(UITableView *)tableView;
{
    return 44.0f;
}

@end
