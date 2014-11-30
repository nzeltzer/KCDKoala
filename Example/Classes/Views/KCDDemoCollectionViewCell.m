//
//  KCDDemoCollectionViewCell.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/4/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

#import "KCDDemoCollectionViewCell.h"
#import <KCDKoala/KCDKoala.h>

#pragma mark - KCDDemoCollectionViewCell

@interface KCDDemoCollectionViewCell()

@property (nonatomic, readwrite, strong) KCDDemoCircleView *circleView;

@end

@implementation KCDDemoCollectionViewCell

@synthesize selected = _selected;

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.circleView = ({
            KCDDemoCircleView *view = [[KCDDemoCircleView alloc] initWithFrame:CGRectZero];
            view.color = KCDRandomColor();
            [self.contentView addSubview:view];
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
            NSDictionary *views = NSDictionaryOfVariableBindings(view);
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                                     options:NSLayoutFormatAlignAllCenterY
                                                                                     metrics:nil
                                                                                       views:views]];
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                                     options:NSLayoutFormatAlignAllCenterX
                                                                                     metrics:nil
                                                                                       views:views]];
            view;
        });
    }
    return self;
}

- (void)setTitle:(NSString *)title;
{
    _title = title;
    [self.circleView setTitle:title];
}

- (void)setColor:(UIColor *)color;
{
    _color = color;
    [self.circleView setColor:color];
    [self setSelected:NO];
}

- (void)setSelected:(BOOL)selected;
{
    if (selected != _selected) {
        [self highlight:selected animated:YES];
    }
    _selected = selected;
}

- (void)highlight:(BOOL)highlight animated:(BOOL)animated;
{
    UIColor *highlightColor = (highlight) ? [UIColor blackColor] : [self color];
    if (animated) {
        [UIView transitionWithView:self.circleView duration:0.5 options:(highlight) ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self.circleView setColor:highlightColor];
        } completion:nil];
    }
    else {
        [self.circleView setColor:highlightColor];
    }
}

- (BOOL)isSelected;
{
    return _selected;
}


@end

#pragma mark - KCDDemoCircleView

@implementation KCDDemoCircleView

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setOpaque:NO];
    }
    return self;
}

- (void)setTitle:(NSString *)title;
{
    _title = title;
    [self setNeedsDisplay];
}

- (void)setColor:(UIColor *)color;
{
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect;
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [[UIColor clearColor] CGColor]);
    CGContextFillRect(ctx, rect);
    CGContextSetFillColorWithColor(ctx, [self.color CGColor]);
    CGContextFillEllipseInRect(ctx, rect);
    if ([self.title length] > 0) {
        // Draw the first letter in the center of the circle.
        NSString *title = [[self.title substringToIndex:1] capitalizedString];
        static NSDictionary *attributes = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            attributes = @{
                           NSForegroundColorAttributeName : [UIColor whiteColor],
                           NSFontAttributeName : [UIFont boldSystemFontOfSize:18]
                           };
        });
        NSAttributedString *attributedTitle = [[NSAttributedString alloc]
                                               initWithString:title
                                               attributes:attributes];
        NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin;
        CGRect bounds = [attributedTitle boundingRectWithSize:rect.size options:options context:nil];
        CGPoint origin = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        origin.x -= bounds.size.width/2;
        origin.y -= bounds.size.height/2;
        bounds.origin = origin;
        [attributedTitle drawWithRect:bounds options:options context:nil];
    }
}

@end