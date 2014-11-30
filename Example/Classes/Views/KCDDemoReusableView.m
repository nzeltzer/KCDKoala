//
//  KCDDemoReusableView.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/4/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

#import "KCDDemoReusableView.h"
#import <KCDKoala/KCDKoala.h>

@interface KCDDemoResusableView()

@property (nonatomic, readwrite, strong) UILabel *label;

@end

@implementation KCDDemoResusableView

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = KCDRandomColor();
        self.label = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.font = [UIFont systemFontOfSize:18];
            label.textColor = [UIColor whiteColor];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:label];
            NSDictionary *views = NSDictionaryOfVariableBindings(label);
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(5)-[label]-(5)-|"
                                                                         options:NSLayoutFormatAlignAllCenterY
                                                                         metrics:nil
                                                                           views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|"
                                                                         options:NSLayoutFormatAlignAllCenterX
                                                                         metrics:nil
                                                                           views:views]];
            label;
        });
    }
    return self;
}

- (void)setTitle:(NSString *)sectionTitle;
{
    _title = sectionTitle;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.label setText:sectionTitle];
    });
}

@end