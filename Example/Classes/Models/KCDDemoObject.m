//
//  KCDDemoCellObject.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/4/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

#import "KCDDemoObject.h"
#import "KCDDemoReusableView.h"
#import "KCDDemoCollectionViewCell.h"
#import "KCDDemoTableViewCell.h"

NSString * const KCDDefaultCellIdentifier = @"KCDDefaultCellIdentifier";
NSString * const KCDCircleCellIdentifier = @"KCDCircleCellIdentifier";
NSString * const KCDSquareCellIdentifier = @"KCDSquareCellIdentifier";

@interface KCDDemoTableViewCell()

@end

@implementation KCDDemoObject

#pragma mark - KCDObject Subclass

- (void)configureCollectionViewCell:(UICollectionViewCell *)cell;
{
    if ([cell isKindOfClass:[KCDDemoCollectionViewCell class]]) {
        KCDDemoCollectionViewCell *KCDCell = (KCDDemoCollectionViewCell *)cell;
        KCDCell.title = self.title;
        if (!_backgroundColor) {
            _backgroundColor = KCDRandomColor();
        }
        KCDCell.color = self.backgroundColor;
    }
    else if ([cell isKindOfClass:[KCDDemoTableCollectionViewCell class]]) {
        KCDDemoTableCollectionViewCell *KCDTableCell = (KCDDemoTableCollectionViewCell *)cell;
        KCDTableCell.title = self.title;
        KCDTableCell.color = self.backgroundColor;
    }
    else if ([cell isKindOfClass:[KCDCollectionViewCell class]]) {
        KCDCollectionViewCell *KCDCell = (KCDCollectionViewCell *)cell;
        KCDCell.backgroundColor = [UIColor whiteColor];
    }
}

+ (NSDictionary *)collectionViewCellClassMap;
{
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
                NSStringFromClass(self) : NSStringFromClass([KCDCollectionViewCell class]),
                KCDCircleCellIdentifier : NSStringFromClass([KCDDemoCollectionViewCell class]),
                KCDSquareCellIdentifier : NSStringFromClass([KCDDemoTableCollectionViewCell class]),
                KCDDefaultCellIdentifier : NSStringFromClass([KCDCollectionViewCell class]),
                };
    });
    return map;
}

#pragma mark - KCDObject

- (BOOL)canEdit;
{
    return YES;
}

- (BOOL)canMove;
{
    return YES;
}

#pragma makr - KCDTableViewObjectProtocol

- (UITableViewCell *)cellForTableView:(UITableView *)tableView;
{
    KCDDemoTableViewCell *cell = nil;
    if (!(cell = [tableView dequeueReusableCellWithIdentifier:self.identifier])) {
        cell = [[KCDDemoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.identifier];
    }
    [cell setTitle:self.title];
    return cell;
}

- (CGFloat)heightForCellInTableView:(UITableView *)tableView;
{
    CGRect sizingRect = (CGRect){.size = CGSizeMake(tableView.frame.size.width, CGFLOAT_MAX) };
    CGSize size = [KCDDemoTableViewCell drawTitle:self.title
                                           inRect:sizingRect
                                          context:NULL];
    return size.height;
}

#pragma mark - KCDCollectionViewObject Protocol

- (UICollectionViewCell *)cellForCollectionView:(UICollectionView *)view
                                    atIndexPath:(NSIndexPath *)indexPath;
{
    return [super cellForCollectionView:view atIndexPath:indexPath];
}

- (CGSize)sizeForCollectionView:(UICollectionView *)collectionView
                         layout:(UICollectionViewLayout *)layout;
{
    NSDictionary *cellClassMap = [[self class] collectionViewCellClassMap];
    if (cellClassMap[self.identifier] == [KCDDemoTableCollectionViewCell class]) {
        CGRect sizingRect = CGRectZero;
        if ([layout isKindOfClass:NSClassFromString(@"KCDCollectionViewTableLayout")]) {
            CGFloat inset = 0.0f;
            if ([layout isKindOfClass:[UICollectionViewFlowLayout class]]) {
                UIEdgeInsets edgeInsets = [(UICollectionViewFlowLayout *)layout sectionInset];
                inset = (edgeInsets.left + edgeInsets.right);
            }
            sizingRect = (CGRect){.size = CGSizeMake(collectionView.frame.size.width-inset, CGFLOAT_MAX) };
        }
        else {
            sizingRect = (CGRect){.size = CGSizeMake(100, CGFLOAT_MAX) };;
        }
        CGSize size = [KCDDemoTableCollectionViewCell
                drawTitle:self.title
                inRect:sizingRect
                context:NULL];
        return size;
    }
    return CGSizeMake(50, 50);
}

@end
