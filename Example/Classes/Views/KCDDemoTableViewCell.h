//
//  KCDDemoTableViewCell.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/4/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

@import UIKit;

@interface KCDDemoTableViewCell : UITableViewCell

@property (nonatomic, readwrite, copy) NSString *title;

+ (CGSize)drawTitle:(NSString *)title
             inRect:(CGRect)rect
            context:(CGContextRef)ctx;

@end

@interface KCDDemoTableCollectionViewCell : UICollectionViewCell

@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, copy) UIColor *color;

+ (CGSize)drawTitle:(NSString *)title
             inRect:(CGRect)rect
            context:(CGContextRef)ctx;

@end
