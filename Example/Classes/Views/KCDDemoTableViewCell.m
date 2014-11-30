//
//  KCDDemoTableViewCell.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/4/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

#import "KCDDemoTableViewCell.h"

#pragma mark - Drawing and Sizing

CGSize KCDDemoViewDrawTitleInRect(NSString *title, CGRect rect, CGContextRef ctx) {
    if (title.length == 0) {
        return CGSizeMake(rect.size.width, 44.0f);
    }
    CGFloat padding = 10.0f;
    
    static NSDictionary *attributes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        para.lineBreakMode = NSLineBreakByWordWrapping;
        para.alignment = NSTextAlignmentLeft;
        para.hyphenationFactor = 1.0f;
        attributes = @{ NSFontAttributeName : [UIFont systemFontOfSize:16], NSForegroundColorAttributeName : [UIColor blackColor], NSParagraphStyleAttributeName : para };
    });
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:title attributes:attributes];
    CGRect bufferedRect = CGRectInset(rect, padding, padding);
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin;
    CGRect canvas = [string boundingRectWithSize:bufferedRect.size options:options context:nil];
    canvas = CGRectIntegral(canvas);
    if (ctx) {
        canvas.origin = bufferedRect.origin;
        [string drawWithRect:canvas options:options context:nil];
    }
    CGRect returnRect = (CGRect) { .size = CGSizeMake(rect.size.width, canvas.size.height+(padding * 2)) };
    return returnRect.size;
}

#pragma mark - KCDCellContentView

@protocol KCDCellContentViewHostProtocol <NSObject>

- (void)drawContentViewInRect:(CGRect)rect;

@end

@interface KCDCellContentView : UIView

@end

@implementation KCDCellContentView

- (void)drawRect:(CGRect)rect;
{
    if ([self.superview respondsToSelector:@selector(drawContentViewInRect:)]) {
        [(id<KCDCellContentViewHostProtocol>)self.superview drawContentViewInRect:rect];
    }
}

@end

#pragma mark - KCDDemoTableViewCell

@interface KCDDemoTableViewCell() <KCDCellContentViewHostProtocol>

@end

@implementation KCDDemoTableViewCell

@synthesize contentView = _contentView;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _contentView = ({
            KCDCellContentView *view = [[KCDCellContentView alloc] initWithFrame:CGRectZero];
            [view setContentMode:UIViewContentModeRedraw];
            [view setOpaque:NO];
            [view setBackgroundColor:[UIColor clearColor]];
            [self addSubview:view];
            [view setFrame:self.bounds];
            view;
        });
    }
    return self;
}

- (void)drawContentViewInRect:(CGRect)rect;
{
    if ([self title]) {
        [[self class] drawTitle:self.title
                         inRect:rect
                        context:UIGraphicsGetCurrentContext()];
    }
}

- (void)setNeedsDisplay;
{
    [super setNeedsDisplay];
    [self.contentView setNeedsDisplay];
}

+ (CGSize)drawTitle:(NSString *)title
             inRect:(CGRect)rect
            context:(CGContextRef)ctx;
{
    return KCDDemoViewDrawTitleInRect(title, rect, ctx);
}

- (void)setTitle:(NSString *)title;
{
    _title = title;
    [self setNeedsDisplay];
}


@end

#pragma mark - KCDDemoTableCollectionViewCell

@interface KCDDemoTableCollectionViewCell() <KCDCellContentViewHostProtocol>

@end

@implementation KCDDemoTableCollectionViewCell

@synthesize contentView = _contentView;

- (instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        _contentView = ({
            KCDCellContentView *view = [[KCDCellContentView alloc] initWithFrame:CGRectZero];
            [view setContentMode:UIViewContentModeRedraw];
            [view setOpaque:NO];
            [view setBackgroundColor:[UIColor clearColor]];
            [self addSubview:view];
            [view setTranslatesAutoresizingMaskIntoConstraints:NO];
            NSDictionary *bindings = NSDictionaryOfVariableBindings(view);
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                  
                                                                         options:NSLayoutFormatAlignAllCenterY
                                                                         metrics:nil
                                                                           views:bindings]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                  
                                                                         options:NSLayoutFormatAlignAllCenterX
                                                                         metrics:nil
                                                                           views:bindings]];
            view;
        });
        self.backgroundView = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.backgroundColor = [UIColor whiteColor];
            view;
        });
    }
    return self;
}

- (void)drawContentViewInRect:(CGRect)rect;
{
    if ([self title]) {
        [[self class] drawTitle:self.title
                         inRect:rect
                        context:UIGraphicsGetCurrentContext()];
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(ctx, NO);
    CGFloat lineWidth = 1.0/[[UIScreen mainScreen] scale];
    CGRect lineRect = CGRectIntegral(CGRectInset(rect, 15, lineWidth));
    CGPoint bl = CGPointMake(CGRectGetMinX(lineRect), CGRectGetMaxY(lineRect));
    CGPoint br = CGPointMake(CGRectGetMaxX(lineRect), CGRectGetMaxY(lineRect));
    bl.y -= lineWidth;
    br.y -= lineWidth;
    CGPoint * lineSegments = malloc(sizeof(CGPoint)*2);
    lineSegments[0] = bl;
    lineSegments[1] = br;
    CGContextSetLineWidth(ctx, lineWidth);
    CGContextSetStrokeColorWithColor(ctx, [[UIColor lightGrayColor] CGColor]);
    CGContextStrokeLineSegments(ctx, lineSegments, 2);
    free(lineSegments);
}

- (void)setNeedsDisplay;
{
    [super setNeedsDisplay];
    [self.contentView setNeedsDisplay];
}

+ (CGSize)drawTitle:(NSString *)title
             inRect:(CGRect)rect
            context:(CGContextRef)ctx;
{
    return KCDDemoViewDrawTitleInRect(title, rect, ctx);
}

- (void)setTitle:(NSString *)title;
{
    _title = title;
    [self setNeedsDisplay];
}

- (void)setColor:(UIColor *)color;
{
    _color = color;
    [self setBackgroundColor:color];
}

@end
