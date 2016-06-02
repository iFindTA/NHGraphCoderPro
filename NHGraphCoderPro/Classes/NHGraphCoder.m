//
//  NHGraphCoder.m
//  NHGraphCoderPro
//
//  Created by hu jiaju on 16/5/30.
//  Copyright © 2016年 hu jiaju. All rights reserved.
//

#import "NHGraphCoder.h"
#import <objc/runtime.h>
#import "FBShimmeringView.h"
#import "JGAFImageCache.h"

#ifndef PBSCREEN_WIDTH
#define PBSCREEN_WIDTH   ([[UIScreen mainScreen]bounds].size.width)
#endif
#ifndef PBSCREEN_HEIGHT
#define PBSCREEN_HEIGHT  ([[UIScreen mainScreen]bounds].size.height)
#endif
#ifndef PBSCREEN_SCALE
#define PBSCREEN_SCALE  ([UIScreen mainScreen].scale)
#endif
#ifndef PBCONTENT_OFFSET
#define PBCONTENT_OFFSET  (20*PBSCREEN_SCALE)
#endif
#ifndef PBCONTENT_SIZE
#define PBCONTENT_SIZE  (PBSCREEN_WIDTH - PBCONTENT_OFFSET*2)
#endif

#ifndef PBTile_SIZE
#define PBTile_SIZE                 100
#endif
#ifndef PB_BALL_RADIUS_SCALE
#define PB_BALL_RADIUS_SCALE        4
#endif
#ifndef PB_BALL_RADIUS_OFFSET
#define PB_BALL_RADIUS_OFFSET       0.5
#endif
#ifndef PB_BALL_SIZE
#define PB_BALL_SIZE                (PBTile_SIZE/PB_BALL_SCALE)
#endif
#ifndef PBSLIDER_SIZE
#define PBSLIDER_SIZE               40
#endif



#pragma mark -- Custom Slider --

typedef void(^NHSliderEvent)(CGFloat p, BOOL end);

@interface NHGraphicSlider : UIControl

/**
 *  @brief the block event
 */
@property (nonatomic, copy) NHSliderEvent event;

/**
 * The current value of the receiver.
 *
 * Setting this property causes the receiver to redraw itself using the new value.
 * If you try to set a value that is below the minimum or above the maximum value, the minimum or maximum value is set instead. The default value of this property is 0.0.
 */
@property (nonatomic) float value;

/**
 * The minimum value of the receiver.
 *
 * If you change the value of this property, and the current value of the receiver is below the new minimum, the current value is adjusted to match the new minimum value automatically.
 * The default value of this property is 0.0.
 */
@property (nonatomic) float minimumValue;

/**
 * The maximum value of the receiver.
 *
 * If you change the value of this property, and the current value of the receiver is above the new maximum, the current value is adjusted to match the new maximum value automatically.
 * The default value of this property is 1.0.
 */
@property (nonatomic) float maximumValue;

/**
 * The color shown for the portion of the slider that is filled.
 */
@property(nonatomic, retain) UIColor *minimumTrackTintColor;

/**
 * The color shown for the portion of the slider that is not filled.
 */
@property(nonatomic, retain) UIColor *maximumTrackTintColor;

/**
 * The color used to tint the standard thumb.
 */
@property(nonatomic, retain) UIColor *thumbTintColor;

/**
 *  @brief called when the slider's value changed
 *
 *  @param event the value change
 */
- (void)handleSliderValueChangedEvent:(NHSliderEvent)event;

@end

@interface NHGraphicSlider ()

@property (nonatomic, assign, getter=isContinuous) BOOL continuous;
@property (nonatomic, assign) CGPoint thumbCenterPoint;

@property (nonatomic, assign) BOOL sliderAbel,sliding;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) FBShimmeringView *shimmer;

#pragma mark - Init and Setup methods
- (void)setup;

#pragma mark - Thumb management methods
- (BOOL)isPointInThumb:(CGPoint)point;

@end

@implementation NHGraphicSlider

@synthesize value = _value;
- (void)setValue:(float)value {
    if (value != _value) {
        if (value > self.maximumValue) { value = self.maximumValue; }
        if (value < self.minimumValue) { value = self.minimumValue; }
        _value = value;
        [self setNeedsDisplay];
        if (self.isContinuous) {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
}
@synthesize minimumValue = _minimumValue;
- (void)setMinimumValue:(float)minimumValue {
    if (minimumValue != _minimumValue) {
        _minimumValue = minimumValue;
        if (self.maximumValue < self.minimumValue)	{ self.maximumValue = self.minimumValue; }
        if (self.value < self.minimumValue)			{ self.value = self.minimumValue; }
    }
}
@synthesize maximumValue = _maximumValue;
- (void)setMaximumValue:(float)maximumValue {
    if (maximumValue != _maximumValue) {
        _maximumValue = maximumValue;
        if (self.minimumValue > self.maximumValue)	{ self.minimumValue = self.maximumValue; }
        if (self.value > self.maximumValue)			{ self.value = self.maximumValue; }
    }
}

@synthesize minimumTrackTintColor = _minimumTrackTintColor;
- (void)setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor {
    if (![minimumTrackTintColor isEqual:_minimumTrackTintColor]) {
        _minimumTrackTintColor = minimumTrackTintColor;
        [self setNeedsDisplay];
    }
}

@synthesize maximumTrackTintColor = _maximumTrackTintColor;
- (void)setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor {
    if (![maximumTrackTintColor isEqual:_maximumTrackTintColor]) {
        _maximumTrackTintColor = maximumTrackTintColor;
        [self setNeedsDisplay];
    }
}

@synthesize thumbTintColor = _thumbTintColor;
- (void)setThumbTintColor:(UIColor *)thumbTintColor {
    if (![thumbTintColor isEqual:_thumbTintColor]) {
        _thumbTintColor = thumbTintColor;
        [self setNeedsDisplay];
    }
}

@synthesize continuous = _continuous;

//@synthesize sliderStyle = _sliderStyle;
//- (void)setSliderStyle:(UICircularSliderStyle)sliderStyle {
//    if (sliderStyle != _sliderStyle) {
//        _sliderStyle = sliderStyle;
//        [self setNeedsDisplay];
//    }
//}

@synthesize thumbCenterPoint = _thumbCenterPoint;

/** @name Init and Setup methods */
#pragma mark - Init and Setup methods
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)awakeFromNib {
    [self setup];
}

- (void)setup {
    self.sliderAbel = true;
    self.value = 0.0;
    self.minimumValue = 0.0;
    self.maximumValue = 1.0;
    self.minimumTrackTintColor = [UIColor blueColor];
    self.maximumTrackTintColor = [UIColor whiteColor];
    self.thumbTintColor = [UIColor darkGrayColor];
    self.continuous = YES;
    self.thumbCenterPoint = CGPointZero;
    
    /**
     * This tapGesture isn't used yet but will allow to jump to a specific location in the circle
     */
//    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHappened:)];
//    [self addGestureRecognizer:tapGestureRecognizer];
//    
//    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHappened:)];
//    panGestureRecognizer.maximumNumberOfTouches = panGestureRecognizer.minimumNumberOfTouches;
//    [self addGestureRecognizer:panGestureRecognizer];
    
    self.backgroundColor = [UIColor lightGrayColor];
    
    UIImage *thumbImage = [self thumbWithColor:[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0]];
    
    
    _slider = [[UISlider alloc] initWithFrame:self.bounds];
    _slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    CGPoint ctr = _slider.center;
    CGRect sliderFrame = _slider.frame;
    sliderFrame.size.width -= 4; //each "edge" of the track is 2 pixels wide
    _slider.frame = sliderFrame;
    _slider.center = ctr;
    _slider.backgroundColor = [UIColor clearColor];
    [_slider setThumbImage:thumbImage forState:UIControlStateNormal];
    
    UIImage *clearImage = [self clearPixel];
    [_slider setMaximumTrackImage:clearImage forState:UIControlStateNormal];
    [_slider setMinimumTrackImage:clearImage forState:UIControlStateNormal];
    
    _slider.minimumValue = 0.0;
    _slider.maximumValue = 1.0;
    _slider.continuous = YES;
    _slider.value = 0.0;
    [self addSubview:_slider];
    
    CGSize thumbSize = thumbImage.size;
    CGFloat infoStart_x = thumbSize.width ;
    CGRect bounds = CGRectMake(infoStart_x,0,CGRectGetWidth(self.bounds)-infoStart_x,CGRectGetHeight(self.bounds));
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:bounds];
    //infoLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.font = [UIFont boldSystemFontOfSize:20];
    infoLabel.text = @"拖动滑块完成验证>>>";
    //[self addSubview:infoLabel];
    FBShimmeringView *shimmer = [[FBShimmeringView alloc] initWithFrame:bounds];
    shimmer.shimmering = true;
    shimmer.shimmeringBeginFadeDuration = 1.5;
    shimmer.shimmeringOpacity = 0.3;
    shimmer.contentView = infoLabel;
    [self addSubview:shimmer];
    self.shimmer = shimmer;
    
    // Set the slider action methods
    [_slider addTarget:self
                action:@selector(sliderUp:)
      forControlEvents:UIControlEventTouchUpInside];
    [_slider addTarget:self
                action:@selector(sliderUp:)
      forControlEvents:UIControlEventTouchUpOutside];
    [_slider addTarget:self
                action:@selector(sliderDown:)
      forControlEvents:UIControlEventTouchDown];
    [_slider addTarget:self
                action:@selector(sliderChanged:)
      forControlEvents:UIControlEventValueChanged];
}

- (void)resetSlider {
    [_slider setValue:0.0 animated: YES];
    self.shimmer.alpha = 1.0;
    if (_event) {
        _event(0, false);
    }
}

// UISlider actions
- (void) sliderUp:(UISlider *)sender {
    
    if (_sliding) {
        _sliding = NO;
        if (_event) {
            _event(sender.value, true);
        }
    }
}

- (void) sliderDown:(UISlider *)sender {
    
    if (!_sliding) {
        //[_label setAnimated:NO];
    }
    _sliding = YES;
}

- (void) sliderChanged:(UISlider *)sender {
    
    self.shimmer.alpha = MAX(0.0, 1.0 - (_slider.value * 3.5));
    if (_event) {
        _event(sender.value, false);
    }
}

- (UIImage *) thumbWithColor:(UIColor*)color {
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale<1.0) {scale = 1.0;}
    
    CGSize size = CGSizeMake(68.0*scale, 44.0*scale);
    CGFloat radius = 10.0*scale;
    // create a new bitmap image context
    UIGraphicsBeginImageContext(size);
    
    // get context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // push context to make it current
    // (need to do this manually because we are not drawing in a UIView)
    UIGraphicsPushContext(context);
    
    [color setFill];
    [[[UIColor blackColor] colorWithAlphaComponent:0.8] setStroke];
    
    CGFloat radiusp = radius+0.5;
    CGFloat wid1 = size.width-0.5;
    CGFloat hei1 = size.height-0.5;
    CGFloat wid2 = size.width-radiusp;
    CGFloat hei2 = size.height-radiusp;
    
    // Path
    CGContextMoveToPoint(context, 0.5, radiusp);
    CGContextAddArcToPoint(context, 0.5, 0.5, radiusp, 0.5, radius);
    CGContextAddLineToPoint(context, wid2, 0.5);
    CGContextAddArcToPoint(context, wid1, 0.5, wid1, radiusp, radius);
    CGContextAddLineToPoint(context, wid1, hei2);
    CGContextAddArcToPoint(context, wid1, hei1, wid2, hei1, radius);
    CGContextAddLineToPoint(context, radius, hei1);
    CGContextAddArcToPoint(context, 0.5, hei1, 0.5, hei2, radius);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    
    // Arrow
    [[[UIColor blueColor] colorWithAlphaComponent:0.6] setFill];
    [[[UIColor blackColor] colorWithAlphaComponent:0.3] setStroke];
    
    CGFloat points[8]= {    (19.0*scale)+0.5,
        (16.0*scale)+0.5,
        (36.0*scale)+0.5,
        (10.0*scale)+0.5,
        (52.0*scale)+0.5,
        (22.0*scale)+0.5,
        (34.0*scale)+0.5,
        (28.0*scale)+0.5 };
    
    CGContextMoveToPoint(context, points[0], points[1]);
    CGContextAddLineToPoint(context, points[2], points[1]);
    CGContextAddLineToPoint(context, points[2], points[3]);
    CGContextAddLineToPoint(context, points[4], points[5]);
    CGContextAddLineToPoint(context, points[2], points[6]);
    CGContextAddLineToPoint(context, points[2], points[7]);
    CGContextAddLineToPoint(context, points[0], points[7]);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    
    // Light
    [[[UIColor whiteColor] colorWithAlphaComponent:0.2] setFill];
    
    CGFloat mid = lround(size.height/2.0)+0.5;
    CGContextMoveToPoint(context, 0.5, radiusp);
    CGContextAddArcToPoint(context, 0.5, 0.5, radiusp, 0.5, radius);
    CGContextAddLineToPoint(context, wid2, 0.5);
    CGContextAddArcToPoint(context, wid1, 0.5, wid1, radiusp, radius);
    CGContextAddLineToPoint(context, wid1, mid);
    CGContextAddLineToPoint(context, 0.5, mid);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFill);
    
    // pop context
    UIGraphicsPopContext();
    
    // get a UIImage from the image context
    UIImage *outputImage = [[UIImage alloc] initWithCGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage scale:scale orientation:UIImageOrientationUp];
    //write (debug)
    //[UIImagePNGRepresentation(outputImage) writeToFile:@"/Users/mathieu/Desktop/test.png" atomically:YES];
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (UIImage *) clearPixel {
    CGRect rect = CGRectMake(0.0, 0.0, 1.0, 1.0);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/** @name Drawing methods */
#pragma mark - Drawing methods
#define kLineWidth 5.0
#define kThumbRadius 12.0
- (CGFloat)sliderRadius {
    CGFloat radius = MIN(self.bounds.size.width/2, self.bounds.size.height/2);
    radius -= MAX(kLineWidth, kThumbRadius);
    return radius;
}
- (void)drawThumbAtPoint:(CGPoint)sliderButtonCenterPoint inContext:(CGContextRef)context {
    UIGraphicsPushContext(context);
    CGContextBeginPath(context);
    
    CGContextMoveToPoint(context, sliderButtonCenterPoint.x, sliderButtonCenterPoint.y);
    CGContextAddArc(context, sliderButtonCenterPoint.x, sliderButtonCenterPoint.y, kThumbRadius, 0.0, 2*M_PI, NO);
    
    CGContextFillPath(context);
    UIGraphicsPopContext();
}

- (CGPoint)drawCircularTrack:(float)track atPoint:(CGPoint)center withRadius:(CGFloat)radius inContext:(CGContextRef)context {
    UIGraphicsPushContext(context);
    CGContextBeginPath(context);
    
//    float angleFromTrack = translateValueFromSourceIntervalToDestinationInterval(track, self.minimumValue, self.maximumValue, 0, 2*M_PI);
    float angleFromTrack = 0;
    CGFloat startAngle = -M_PI_2;
    CGFloat endAngle = startAngle + angleFromTrack;
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, NO);
    
    CGPoint arcEndPoint = CGContextGetPathCurrentPoint(context);
    
    CGContextStrokePath(context);
    UIGraphicsPopContext();
    
    return arcEndPoint;
}

- (CGPoint)drawPieTrack:(float)track atPoint:(CGPoint)center withRadius:(CGFloat)radius inContext:(CGContextRef)context {
    UIGraphicsPushContext(context);
    
//    float angleFromTrack = translateValueFromSourceIntervalToDestinationInterval(track, self.minimumValue, self.maximumValue, 0, 2*M_PI);
    float angleFromTrack = 0;
    CGFloat startAngle = -M_PI_2;
    CGFloat endAngle = startAngle + angleFromTrack;
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, NO);
    
    CGPoint arcEndPoint = CGContextGetPathCurrentPoint(context);
    
    CGContextClosePath(context);
    CGContextFillPath(context);
    UIGraphicsPopContext();
    
    return arcEndPoint;
}

/** @name Thumb management methods */
#pragma mark - Thumb management methods
- (BOOL)isPointInThumb:(CGPoint)point {
    CGRect thumbTouchRect = CGRectMake(self.thumbCenterPoint.x - kThumbRadius, self.thumbCenterPoint.y - kThumbRadius, kThumbRadius*2, kThumbRadius*2);
    return CGRectContainsPoint(thumbTouchRect, point);
}

/** @name UIGestureRecognizer management methods */
#pragma mark - UIGestureRecognizer management methods
- (void)panGestureHappened:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint tapLocation = [panGestureRecognizer locationInView:self];
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateChanged: {
            
            self.thumbCenterPoint = tapLocation;
            self.value = tapLocation.x/CGRectGetMaxX(self.bounds);
            break;
        }
        case UIGestureRecognizerStateEnded:
            if (!self.isContinuous) {
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }
            if ([self isPointInThumb:tapLocation]) {
                [self sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
            else {
                [self sendActionsForControlEvents:UIControlEventTouchUpOutside];
            }
            break;
        default:
            break;
    }
}
- (void)tapGestureHappened:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint tapLocation = [tapGestureRecognizer locationInView:self];
        self.sliderAbel = [self isPointInThumb:tapLocation];
    }
}

/** @name Touches Methods */
#pragma mark - Touches Methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    if ([self isPointInThumb:touchLocation]) {
        [self sendActionsForControlEvents:UIControlEventTouchDown];
    }
}

- (void)handleSliderValueChangedEvent:(NHSliderEvent)event {
    self.event = [event copy];
}


@end

#pragma mark -- state view --

@interface UIImage (NHHelper)

- (UIImage *) imageWithTintColor:(UIColor *)tintColor;

@end

@implementation UIImage (NHHelper)

- (UIImage *) imageWithTintColor:(UIColor *)tintColor {
    //We want to keep alpha, set opaque to NO; Use 0.0f for scale to use the scale factor of the device’s main screen.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    
    //Draw the tinted image in context
    [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

@end

typedef void(^NHStateOnceMoreEvent)(void);

@interface NHGraphicState : UIView

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel,*subLabel;
@property (nonatomic, strong) UIButton *moreBtn;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, copy) NHStateOnceMoreEvent event;

- (void)loadingState:(BOOL)load;

- (void)handleStateOnceMoreEvent:(NHStateOnceMoreEvent)event;

@end

@implementation NHGraphicState

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self __initSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self __initSetup];
    }
    return self;
}

- (void)__initSetup {
    CGFloat m_icon_size = PBSLIDER_SIZE;
    CGSize size = self.bounds.size;
    CGRect bounds = CGRectMake((size.width-m_icon_size)*0.5, m_icon_size, m_icon_size, m_icon_size);
    UIImageView *imgv = [[UIImageView alloc] initWithFrame:bounds];
    [self addSubview:imgv];
    self.iconView = imgv;
    
    bounds = CGRectMake(0, m_icon_size*2, size.width, 30);
    UILabel *label = [[UILabel alloc] initWithFrame:bounds];
    label.font = [UIFont boldSystemFontOfSize:20];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    [self addSubview:label];
    self.titleLabel = label;
    
    bounds.origin.y += 30;
    label = [[UILabel alloc] initWithFrame:bounds];
    label.font = [UIFont boldSystemFontOfSize:15];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    [self addSubview:label];
    self.subLabel = label;
    
    CGFloat m_btn_size = m_icon_size * 2;
    bounds = CGRectMake((size.width-m_btn_size)*0.5, m_icon_size*3.5, m_btn_size, 30);
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = bounds;
    [btn setTitle:@"再试一次" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onceMoreEvent) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btn];
    self.moreBtn = btn;
    btn.hidden = true;
    
    UIActivityIndicatorView *actor = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    actor.hidesWhenStopped = true;
    [self addSubview:actor];
    self.indicatorView = actor;
    CGPoint mCenter = CGPointMake(CGRectGetWidth(self.bounds)*0.5, CGRectGetHeight(self.bounds)*0.5);
    actor.center = mCenter;
}

- (void)loadingState:(BOOL)load {
    self.iconView.hidden = load;
    self.titleLabel.hidden = load;
    self.subLabel.hidden = load;
    self.moreBtn.hidden = load;
    if (load) {
        [self.indicatorView startAnimating];
        self.backgroundColor = [UIColor lightGrayColor];
    }else{
        [self.indicatorView stopAnimating];
    }
}

- (void)handleStateOnceMoreEvent:(NHStateOnceMoreEvent)event {
    self.event = [event copy];
}

- (void)onceMoreEvent {
    if (_event) {
        _event();
    }
}

@end

#pragma mark -- Custom Graphic --

struct PBShapeBumper {
    BOOL            arrow_left;
    BOOL            arrow_up;
    BOOL            m_h_isBump;
    BOOL            m_v_isBump;
    CGPoint         m_center;
    int             m_ball_radius;
    int             m_rect_radius;
};

typedef struct PBShapeBumper PBShapeBumper;

@interface NHGraphCoder ()

@property (nonatomic, strong) UIImage *img, *innerImg, *flagImg;
@property (nonatomic, copy) NHGraphEvent event;
@property (nonatomic) PBShapeBumper shapeBumper;
@property (nonatomic, strong) UIBezierPath *shapePath;
@property (nonatomic, strong) UIImageView *mFlag;

@property (nonatomic, strong) NHGraphicSlider *slider;
@property (nonatomic, strong) NHGraphicState *stater;

@property (nonatomic, assign) BOOL endDetect;

@end

static NHGraphCoder *instance = nil;

@implementation NHGraphCoder

- (void)dealloc {
    _img = nil;
    _event = nil;
}

//+ (NHGraphCoder *)shared {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        if (instance == nil) {
//            instance = [[NHGraphCoder alloc] init];
//        }
//    });
//    return instance;
//}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
}

+ (NHGraphCoder *)codeWithImage:(UIImage *)img {
    return [[NHGraphCoder alloc] initWithImage:img];
}

- (void)handleGraphicCoderVerifyEvent:(NHGraphEvent)event {
    self.event = [event copy];
}

//- (id)init {
//    self = [super init];
//    if (self) {
//    }
//    return self;
//}
//
//- (id)initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        [self __initSetup];
//    }
//    return self;
//}
//
//- (id)initWithCoder:(NSCoder *)aDecoder {
//    self = [super initWithCoder:aDecoder];
//    if (self) {
//        [self __initSetup];
//    }
//    return self;
//}

- (id)initWithImage:(UIImage *)img {
    
    NHGraphCoder *coder = [NHGraphCoder new];
    CGSize tmpSize = (CGSize){PBCONTENT_SIZE,PBCONTENT_SIZE};
    CGRect bounds = (CGRect){
        .origin = CGPointZero,
        .size = tmpSize
    };
    img = ((img != nil)?img:[UIImage imageNamed:@"coder_default.jpg"]);
    [coder setFrame:bounds];
    [coder __initSetupImg:img];
    return coder;
}

- (void)setImg:(UIImage *)img {
    if (_img) {
        _img = nil;
    }
    _img = img;
    [self updateInnerImg:img];
}

- (void)__initSetupImg:(UIImage *)img {
    self.img = img;
    [self __initSetup];
}

- (void)updateInnerImg:(UIImage *)img {
    /* Don't resize if we already meet the required destination size. */
    CGSize dstSize = (CGSize){PBCONTENT_SIZE,PBCONTENT_SIZE};
    if (CGSizeEqualToSize(img.size, dstSize)) {
        self.innerImg = img;
        return ;
    }
    CGSize originSize = img.size;
    BOOL keepAspect = false;
    CGRect scaledImageRect = CGRectZero;
    
    CGFloat aspectWidth = dstSize.width / originSize.width;
    CGFloat aspectHeight = dstSize.height / originSize.height;
    CGFloat aspectRatio = keepAspect?MIN(aspectWidth, aspectHeight):MAX(aspectWidth, aspectHeight);
    
    scaledImageRect.size.width = originSize.width * aspectRatio;
    scaledImageRect.size.height = originSize.height * aspectRatio;
    scaledImageRect.origin.x = (dstSize.width - scaledImageRect.size.width) / 2.0f;
    scaledImageRect.origin.y = (dstSize.height - scaledImageRect.size.height) / 2.0f;
    
    UIGraphicsBeginImageContextWithOptions( dstSize, NO, 0 );
    [img drawInRect:scaledImageRect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.innerImg = scaledImage;
}

- (void)__initSetup {
    
    //[self addSubview:self.mFlag];
    
    [self setNeedsDisplay];
    //
    CGFloat m_btn_size = PBSLIDER_SIZE * 0.5;
    CGRect bounds = CGRectMake(PBCONTENT_SIZE-m_btn_size, 0, m_btn_size, m_btn_size);
//    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//    btn.frame = bounds;
//    //    [btn setTitle:@"refresh" forState:UIControlStateNormal];
//    //    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [btn setImage:img forState:UIControlStateNormal];
//    [btn addTarget:self action:@selector(refreshState) forControlEvents:UIControlEventTouchUpInside];
//    [self addSubview:btn];
    
    UIImageView *v_img = [[UIImageView alloc] init];
    [self addSubview:v_img];
    self.mFlag = v_img;
    
    __weak typeof(self) weakSelf = self;
    bounds = CGRectMake(0, PBCONTENT_SIZE-PBSLIDER_SIZE, PBCONTENT_SIZE, PBSLIDER_SIZE);
    NHGraphicSlider *slider = [[NHGraphicSlider alloc] initWithFrame:bounds];
    slider.backgroundColor = [UIColor lightGrayColor];
    [slider handleSliderValueChangedEvent:^(CGFloat p, BOOL end) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf sliderValueChanged:p];
        if (end) {
            [strongSelf endDetectSliderValue:p];
        }
    }];
    [self addSubview:slider];
    self.slider = slider;
    
    bounds = self.bounds;
    bounds.size.height -= PBSLIDER_SIZE;
    NHGraphicState *stater = [[NHGraphicState alloc] initWithFrame:bounds];
    [stater handleStateOnceMoreEvent:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf refreshState];
    }];
    [self addSubview:stater];
    self.stater = stater;
    stater.hidden = true;
}

- (CAShapeLayer *)getBorderLayer {
    CGRect bounds = CGRectMake(0, 0, PBTile_SIZE, PBTile_SIZE);
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    //    shapeLayer.backgroundColor = [UIColor yellowColor].CGColor;
    shapeLayer.frame = bounds;
    [shapeLayer setFillRule:kCAFillRuleEvenOdd];
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    shapeLayer.path = self.shapePath.CGPath;
    shapeLayer.shadowOffset = CGSizeMake(2, 2);
    shapeLayer.shadowPath = self.shapePath.CGPath;
    shapeLayer.shadowColor = [UIColor yellowColor].CGColor;
    shapeLayer.strokeColor = [UIColor yellowColor].CGColor;
    shapeLayer.lineWidth = 2;
    return shapeLayer;
}

- (void)updateFlag {
    CGRect bounds = CGRectMake(0, self.shapeBumper.m_center.y-PBTile_SIZE*0.5, PBTile_SIZE, PBTile_SIZE);
    self.mFlag.image = self.flagImg;
    self.mFlag.frame = bounds;
    [self.mFlag.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    CAShapeLayer *borderLayer = [self getBorderLayer];
    [self.mFlag.layer addSublayer:borderLayer];
    CAShapeLayer *shapeLayer = [self getShapeLayer];
    self.mFlag.layer.mask = shapeLayer;

}

- (void)setShapeBumper:(PBShapeBumper)shapeBumper {
    _shapeBumper = shapeBumper;
    if (_shapePath) {
        _shapePath = nil;
    }
    self.shapePath = [self copyShapePath];
    self.flagImg = [self getThumbiaFlagByPath:self.shapePath];
    [self updateFlag];
}

- (UIBezierPath *)copyShapePath {
    PBShapeBumper *tmpBumper = malloc(sizeof(PBShapeBumper));
    tmpBumper->arrow_left = self.shapeBumper.arrow_left;
    tmpBumper->arrow_up = self.shapeBumper.arrow_up;
    tmpBumper->m_h_isBump = self.shapeBumper.m_h_isBump;
    tmpBumper->m_v_isBump = self.shapeBumper.m_v_isBump;
    tmpBumper->m_ball_radius = self.shapeBumper.m_ball_radius;
    tmpBumper->m_rect_radius = self.shapeBumper.m_rect_radius;
    tmpBumper->m_center = CGPointMake(50, 50);
    return [self getPathForBumper:*tmpBumper];
}

- (CAShapeLayer *)getShapeLayer {
    CGRect bounds = CGRectMake(0, 0, PBTile_SIZE, PBTile_SIZE);
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
//    shapeLayer.backgroundColor = [UIColor yellowColor].CGColor;
    shapeLayer.frame = bounds;
    [shapeLayer setFillRule:kCAFillRuleEvenOdd];
    shapeLayer.fillColor = [[UIColor yellowColor] CGColor];
    shapeLayer.path = self.shapePath.CGPath;
    
    return shapeLayer;
}

- (UIImage *)getShapeImage {
//    UIBezierPath *tmpPath = [self copyShapePath];
//    return [self getThumbiaFlagByPath:tmpPath];
    return self.flagImg;
}

- (UIBezierPath *)getShapePath {
    return [self shapePath];
}

- (UIImage *)getThumbiaFlagByPath:(UIBezierPath *)path{
    
    //destnation bounds
    //CGPoint startPoint = [self getStartPointBy:self.shapeBumper];
    int x_start = self.shapeBumper.m_center.x - PBTile_SIZE * 0.5;
    int y_start = self.shapeBumper.m_center.y - PBTile_SIZE * 0.5;
    int m_width = PBTile_SIZE;
    UIImage *img = self.innerImg;
    CGFloat m_scale = img.scale;
    //NSLog(@"x:%d-y:%d-size:%d",x_start,y_start,m_width);
    
    CGFloat scale = MAX(m_scale, 1.0f);
    CGRect scaledBounds = CGRectMake(x_start * scale, y_start * scale, m_width * scale, m_width * scale);
    CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], scaledBounds);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    
    return croppedImage;
}

- (void)resetStateForDetect {
    [self refreshState];
}

- (void)refreshState {
    NSLog(@"refresh state");
    self.endDetect = false;
    self.slider.userInteractionEnabled = !self.endDetect;
    self.mFlag.hidden = self.endDetect;
    [self.stater loadingState:false];
    self.stater.hidden = !self.endDetect;
    [self setNeedsDisplay];
}

- (void)sliderValueChanged:(CGFloat)value {
    if (value < 0 || value > 1) {
        return;
    }
    CGRect bounds = CGRectMake((PBCONTENT_SIZE-PBTile_SIZE-PBSLIDER_SIZE)*value, self.shapeBumper.m_center.y-PBTile_SIZE*0.5, PBTile_SIZE, PBTile_SIZE);
    self.mFlag.frame = bounds;
}
//滑动slider结束后调用
- (void)endDetectSliderValue:(CGFloat)value {
    CGFloat tmp_x = (PBCONTENT_SIZE-PBTile_SIZE-PBSLIDER_SIZE)*value;
    tmp_x = self.mFlag.center.x;
    const int error_offset = 5;
    BOOL success = (fabs(tmp_x - self.shapeBumper.m_center.x) <= error_offset);
    self.endDetect = true;
    [self setNeedsDisplay];
    self.slider.userInteractionEnabled = !self.endDetect;
    self.mFlag.hidden = self.endDetect;
    [self.slider resetSlider];
    [self endVerify:success];
}

- (void)endVerify:(BOOL)success {
    UIImage *m_img;UIColor *m_bg_color;
    NSString *m_title,*m_sub_title;
    if (success) {
        m_img = [UIImage imageNamed:@"success"];
        m_img = [m_img imageWithTintColor:[UIColor whiteColor]];
        m_bg_color = [UIColor colorWithRed:80/255.0 green:95/255.0 blue:235/255.0 alpha:0.6];
        m_title = @"验证成功";
    }else{
        m_img = [UIImage imageNamed:@"error"];
        m_img = [m_img imageWithTintColor:[UIColor whiteColor]];
        m_bg_color = [UIColor colorWithRed:197/255.0 green:100/255.0 blue:66/255.0 alpha:0.6];
        m_title = @"验证失败";
        m_sub_title = @"拖动滑块将悬浮图像正确拼合";
    }
    self.stater.iconView.image = m_img;
    self.stater.backgroundColor = m_bg_color;
    self.stater.titleLabel.text = m_title;
    self.stater.subLabel.text = m_sub_title;
    self.stater.hidden = false;
    self.stater.moreBtn.hidden = success;
    
    if (_event) {
        _event(self, success);
    }
}

- (int)randomFrom:(int)min to:(int)max {
    return arc4random() % (max-min) + min;
}

- (CGPoint)getStartPointBy:(PBShapeBumper)bumper {
    int m_rect_center_y = bumper.m_center.y;
    int m_rect_center_x = bumper.m_center.x;
    BOOL arrow_left = bumper.arrow_left;
    BOOL arrow_up = bumper.arrow_up;
    BOOL m_h_isBump = bumper.m_h_isBump;
    BOOL m_v_isBump = bumper.m_v_isBump;
    int m_ball_radius = bumper.m_ball_radius;
    int m_rect_radius = bumper.m_rect_radius;
    //destnation bounds
    CGFloat x_start, y_start;
    if (arrow_left && m_h_isBump) {
        //左凸
        m_rect_center_x += m_ball_radius * 1.5 * 0.5;
    }else if (!arrow_left && m_h_isBump){
        //右凸
        m_rect_center_x -= m_ball_radius * 1.5 * 0.5;
    }
    if (arrow_up && m_v_isBump) {
        //上凸
        m_rect_center_y += m_ball_radius * 1.5 * 0.5;
    }else if (!arrow_up && m_v_isBump){
        //下凸
        m_rect_center_y -= m_ball_radius * 1.5 * 0.5;
    }
    x_start = m_rect_center_x-m_rect_radius;
    y_start = m_rect_center_y-m_rect_radius;
    
    return CGPointMake(x_start, y_start);
}

- (UIBezierPath *)graphWithBallTheta:(CGFloat)theta_rad shapeBump:(PBShapeBumper)bumper{
    
//    int m_rect_center_y = bumper.m_center.y;
//    int m_rect_center_x = bumper.m_center.x;
    BOOL arrow_left = bumper.arrow_left;
    BOOL arrow_up = bumper.arrow_up;
    BOOL m_h_isBump = bumper.m_h_isBump;
    BOOL m_v_isBump = bumper.m_v_isBump;
    int m_ball_radius = bumper.m_ball_radius;
    int m_rect_radius = bumper.m_rect_radius;
    int m_rectangle_size = m_rect_radius * 2;
    //destnation bounds
    CGPoint startPoint = [self getStartPointBy:bumper];
    CGFloat x_start = startPoint.x;
    CGFloat y_start = startPoint.y;
    int m_small_rect_center_x = x_start + m_rect_radius;
    int m_small_rect_center_y = y_start + m_rect_radius;
    NSLog(@"start:%@--ball:%d*rect:%d",NSStringFromCGPoint(startPoint),m_ball_radius,m_rect_radius);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
//    CGFloat theta_rad = acos(0.5);
    //NSLog(@"theta :%f",theta_rad);
    CGFloat xuan_half = m_ball_radius*sin(theta_rad);
    CGFloat m_tmp_len = m_rect_radius-xuan_half;
    
    //begin path
    //先移动到左上角 逆时针绘制
    CGPoint tmp_p = CGPointMake(x_start, y_start);
    [path moveToPoint:tmp_p];
    //left
    tmp_p = CGPointMake(x_start, y_start+m_tmp_len);
    [path addLineToPoint:tmp_p];
    if (arrow_left) {
        if (m_h_isBump) {
            //是凸出
            CGPoint tmp_center = CGPointMake(x_start-m_ball_radius*0.5, m_small_rect_center_y);
            [path addArcWithCenter:tmp_center radius:m_ball_radius startAngle:(M_PI*2-theta_rad) endAngle:theta_rad clockwise:false];
        }else{
            //凹陷
            CGPoint tmp_center = CGPointMake(x_start+m_ball_radius*0.5, m_small_rect_center_y);
            [path addArcWithCenter:tmp_center radius:m_ball_radius startAngle:(M_PI+theta_rad) endAngle:(M_PI-theta_rad) clockwise:true];
        }
    }
    tmp_p.y += m_tmp_len + xuan_half*2;
    [path addLineToPoint:tmp_p];
    
    //bottom
    CGFloat theta_rad_left = M_PI_2 - theta_rad;
    tmp_p.x += m_tmp_len;
    [path addLineToPoint:tmp_p];
    if (!arrow_up) {
        if (m_v_isBump) {
            //凸出
            CGPoint tmp_center = CGPointMake(m_small_rect_center_x, y_start+m_rectangle_size+m_ball_radius*0.5);
            [path addArcWithCenter:tmp_center radius:m_ball_radius startAngle:(M_PI+theta_rad_left) endAngle:(M_PI*2-theta_rad_left) clockwise:false];
        }else{
            //凹陷
            CGPoint tmp_center = CGPointMake(m_small_rect_center_x, y_start+m_rectangle_size-m_ball_radius*0.5);
            [path addArcWithCenter:tmp_center radius:m_ball_radius startAngle:(M_PI-theta_rad_left) endAngle:(M_PI*2+theta_rad_left) clockwise:true];
        }
    }
    tmp_p = CGPointMake(x_start+m_rectangle_size, y_start+m_rectangle_size);
    [path addLineToPoint:tmp_p];
    //right
    tmp_p = CGPointMake(x_start+m_rectangle_size, y_start+m_rectangle_size-m_tmp_len);
    [path addLineToPoint:tmp_p];
    if (!arrow_left) {
        if (m_h_isBump) {
            //凸出
            CGPoint tmp_center = CGPointMake(m_small_rect_center_x+m_rect_radius+m_ball_radius*0.5, m_small_rect_center_y);
            [path addArcWithCenter:tmp_center radius:m_ball_radius startAngle:(M_PI-theta_rad) endAngle:(M_PI+theta_rad) clockwise:false];
        }else{
            //凹陷
            CGPoint tmp_center = CGPointMake(m_small_rect_center_x+m_rect_radius-m_ball_radius*0.5, m_small_rect_center_y);
            [path addArcWithCenter:tmp_center radius:m_ball_radius startAngle:theta_rad endAngle:(M_PI*2-theta_rad) clockwise:true];
        }
    }
    tmp_p = CGPointMake(x_start+m_rectangle_size, y_start);
    [path addLineToPoint:tmp_p];
    //up
    tmp_p = CGPointMake(x_start+m_rectangle_size-m_tmp_len, y_start);
    [path addLineToPoint:tmp_p];
    if (arrow_up) {
        if (m_v_isBump) {
            //凸出
            CGPoint tmp_center = CGPointMake(m_small_rect_center_x, y_start-m_ball_radius*0.5);
            [path addArcWithCenter:tmp_center radius:m_ball_radius startAngle:(theta_rad_left) endAngle:(M_PI-theta_rad_left) clockwise:false];
        }else{
            //凹陷
            CGPoint tmp_center = CGPointMake(m_small_rect_center_x, y_start+m_ball_radius*0.5);
            [path addArcWithCenter:tmp_center radius:m_ball_radius startAngle:(-theta_rad_left) endAngle:(M_PI+theta_rad_left) clockwise:true];
        }
    }
    tmp_p = CGPointMake(x_start, y_start);
    [path addLineToPoint:tmp_p];
    //test
    
    [path closePath];
    
    return path;
}

- (UIBezierPath *)generateRandomPath {
    
    int m_tmp_direction_h = arc4random() % 2;
    BOOL arrow_left = m_tmp_direction_h == 0;
    int m_h_Bump = arc4random() % 2;
    BOOL m_h_isBump = (m_h_Bump == 0);
    int m_tmp_direction_v = arc4random() % 2;
    BOOL arrow_up = m_tmp_direction_v == 0;
    BOOL m_v_isBump = !m_h_isBump;
    
    int m_radius_scale = PB_BALL_RADIUS_SCALE;
    float m_ball_cross_scale = 0.5;//球心外到边框距离倍数
//    int m_ball_radius = PBTile_SIZE/((1+m_ball_cross_scale)+m_radius_scale);
    int m_ball_radius = PBTile_SIZE/(m_radius_scale*2);
    int m_rectangle_size = m_ball_radius*m_radius_scale;
    int m_rect_radius = m_rectangle_size * 0.5;
    
    int min = PBTile_SIZE+PBSLIDER_SIZE;
    int max = PBCONTENT_SIZE-min;
    int m_rect_center_y = [self randomFrom:min to:max];
    int m_rect_center_x = [self randomFrom:min to:max];
    NSLog(@"random path center x:%d---y:%d",m_rect_center_x,m_rect_center_y);
    PBShapeBumper bumper = {
        .arrow_up = arrow_up,
        .arrow_left = arrow_left,
        .m_h_isBump = m_h_isBump,
        .m_v_isBump = m_v_isBump,
        .m_ball_radius = m_ball_radius,
        .m_rect_radius = m_rect_radius,
        .m_center = CGPointMake(m_rect_center_x, m_rect_center_y)
    };
    UIBezierPath *m_path = [self graphWithBallTheta:acos(m_ball_cross_scale) shapeBump:bumper];
    self.shapeBumper = bumper;
    
    return m_path;
}

- (UIBezierPath *)getPathForBumper:(PBShapeBumper)bumper {
    float m_ball_cross_scale = 0.5;//球心外到边框距离倍数
    UIBezierPath *m_path = [self graphWithBallTheta:acos(m_ball_cross_scale) shapeBump:bumper];
    
    return m_path;
}

- (UIBezierPath *)path4Size:(CGSize)size {
    //bezier path
    
    int m_tmp_direction_h = arc4random() % 2;
    BOOL arrow_left = m_tmp_direction_h == 0;
    int m_h_Bump = arc4random() % 2;
    BOOL m_h_isBump = (m_h_Bump == 0);
    int m_tmp_direction_v = arc4random() % 2;
    BOOL arrow_up = m_tmp_direction_v == 0;
    BOOL m_v_isBump = !m_h_isBump;
    
    int m_radius_scale = 4;
    float m_ball_cross_scale = 0.5;//球心外到边框距离倍数
    int m_avaliable_size = size.width;
    int m_ball_radius = m_avaliable_size/((1+m_ball_cross_scale)+m_radius_scale);
    int m_rectangle_size = m_ball_radius*m_radius_scale;
    int m_rect_radius = m_rectangle_size * 0.5;
    int m_rect_center_y = m_avaliable_size * 0.5;
    int m_rect_center_x = m_avaliable_size * 0.5;
    
    PBShapeBumper bumper = {
        .arrow_up = arrow_up,
        .arrow_left = arrow_left,
        .m_h_isBump = m_h_isBump,
        .m_v_isBump = m_v_isBump,
        .m_ball_radius = m_ball_radius,
        .m_rect_radius = m_rect_radius,
        .m_center = CGPointMake(m_rect_center_x, m_rect_center_y)
    };
    UIBezierPath *m_path = [self graphWithBallTheta:acos(m_ball_cross_scale) shapeBump:bumper];
    
    return m_path;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [self.innerImg drawInRect:rect];
    
    UIColor *maskColor = [UIColor colorWithWhite:0 alpha:0.7];
//    maskColor = [UIColor blackColor];
    //绘制路径
    if (!self.endDetect) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        UIBezierPath *path = [self generateRandomPath];
        CGContextAddPath(ctx, path.CGPath);
        CGContextSetFillColorWithColor(ctx, maskColor.CGColor);
        CGContextFillPath(ctx);
    }
}

#pragma mark -- Net Graphic Code --
+ (NHGraphCoder *)codeWithURL:(NSString *)url {
    return [[NHGraphCoder alloc] initWithURL:url];
}

- (id)initWithURL:(NSString *)url {
    NHGraphCoder *coder = [NHGraphCoder new];
    CGSize tmpSize = (CGSize){PBCONTENT_SIZE,PBCONTENT_SIZE};
    CGRect bounds = (CGRect){
        .origin = CGPointZero,
        .size = tmpSize
    };
    [coder setBounds:bounds];
//    coder.backgroundColor = [UIColor lightGrayColor];
    if (url == nil) {
        UIImage *img = [UIImage imageNamed:@"coder_default.jpg"];
        [coder __initSetupImg:img];
    }else{
        coder.endDetect = true;
        [coder __initSetup];
        coder.mFlag.hidden = true;
        coder.slider.userInteractionEnabled = false;
        coder.stater.hidden = false;
        [coder.stater loadingState:true];
        __weak typeof(coder) weakCoder = coder;
        [[JGAFImageCache sharedInstance] imageForURL:url completion:^(UIImage * _Nullable image) {
            __strong typeof(weakCoder) strongCoder = weakCoder;
            if (image == nil) {
                NSLog(@"下载图片失败!将使用默认图片本地验证");
                image = [UIImage imageNamed:@"coder_default.jpg"];
            }
            [strongCoder setImg:image];
            [strongCoder resetStateForDetect];
        }];
    }
    return coder;
}

@end
