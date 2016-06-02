//
//  NHGraphCoder.h
//  NHGraphCoderPro
//
//  Created by hu jiaju on 16/5/30.
//  Copyright © 2016年 hu jiaju. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NHGraphCoder;
typedef void(^NHGraphEvent)(NHGraphCoder *coder, BOOL success);
typedef UIImage * _Nonnull (^NHRefreshEvent)();

@interface NHGraphCoder : UIView

- (id)init NS_UNAVAILABLE;

- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/**
 *  @brief generate graph code view
 *
 *  @param img the bg image's instance
 *
 *  @return the graphic code view
 */
+ (NHGraphCoder *)codeWithImage:(UIImage *)img;

/**
 *  @brief generate graph code view
 *
 *  @param url the bg image's url
 *  @attention :TO BE Implementationed !
 *
 *  @return the graphic code view
 */
+ (NHGraphCoder *)codeWithURL:(NSString *)url;

/**
 *  @brief reset state
 */
- (void)resetStateForDetect;

/**
 *  @brief deal with the event
 *
 *  @param event the event
 */
- (void)handleGraphicCoderVerifyEvent:(NHGraphEvent)event;

NS_ASSUME_NONNULL_END

@end
