//
//  KCDDemoCollectionViewCell.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/4/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

@import UIKit;
@class KCDDemoCircleView;

@interface KCDDemoCollectionViewCell : UICollectionViewCell

@property (nonatomic, readonly, strong) KCDDemoCircleView *circleView;
@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite) UIColor *color;

@end

@interface KCDDemoCircleView : UIView

@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, strong) UIColor *color;

@end
