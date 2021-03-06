//
//  BTBubbleView.m
//  bluetooth-demo
//
//  Created by John Bender on 9/26/13.
//  Copyright (c) 2013 General UI, LLC. All rights reserved.
//

#import "BTBubbleView.h"
#import "UIColor+RandomColor.h"
#import <QuartzCore/QuartzCore.h>
#import "BTBluetoothManager.h"

static NSString* const animationKey = @"myCornerRadiusAnimation";

@interface BTBubbleView ()
{
    BOOL isMoving;
    UITouch *movingTouch;
    CGSize touchOffset;
    CGPoint originalPosition;
}
@end

@implementation BTBubbleView

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if( self ) {
        self.backgroundColor = [UIColor randomColor];
    }
    return self;
}


-(void) pickUp
{
    isMoving = TRUE;

    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    a.duration = 0.3;
    a.toValue = @50.;
    a.delegate = self;
    [self.layer addAnimation:a forKey:animationKey];

    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.85;
        CGAffineTransform t = CGAffineTransformMakeScale( 1.11, 1.11 );
        t = CGAffineTransformRotate( t, M_PI );
        self.transform = t;
    } completion:^(BOOL finished) {
        self.layer.cornerRadius = [a.toValue floatValue];
    }];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( isMoving ) return;

    movingTouch = [touches anyObject];

    CGPoint touchPoint = [movingTouch locationInView:self.superview];
    touchOffset = CGSizeMake( self.center.x - touchPoint.x, self.center.y - touchPoint.y );
    originalPosition = self.center;
    [self pickUp];

    NSDictionary *dict = @{@"command": @(BluetoothCommandPickUp),
                           @"viewNumber": @(_originalIndex)};
    [[BTBluetoothManager instance] sendDictionaryToPeers:dict];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( [touches containsObject:movingTouch] ) {
        CGPoint touchPoint = [movingTouch locationInView:self.superview];
        self.center = CGPointMake( touchPoint.x + touchOffset.width, touchPoint.y + touchOffset.height );

        NSDictionary *dict = @{@"command": @(BluetoothCommandMove),
                               @"viewNumber": @(_originalIndex),
                               @"newCenter": [NSValue valueWithCGPoint:self.center]};
        [[BTBluetoothManager instance] sendDictionaryToPeers:dict];
    }
}

-(void) drop
{
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    a.duration = 0.3;
    a.toValue = @0.;
    a.delegate = self;
    [self.layer addAnimation:a forKey:animationKey];

    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.;
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.layer.cornerRadius = [a.toValue floatValue];
    }];

    isMoving = FALSE;
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( [touches containsObject:movingTouch] ) {
        [self drop];
        movingTouch = nil;

        NSDictionary *dict = @{@"command": @(BluetoothCommandDrop),
                               @"viewNumber": @(_originalIndex)};
        [[BTBluetoothManager instance] sendDictionaryToPeers:dict];
    }
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( [touches containsObject:movingTouch] ) {
        [UIView animateWithDuration:0.3 animations:^{
            self.center = originalPosition;
        } completion:^(BOOL finished) {
            [self touchesEnded:touches withEvent:event];
        }];
    }
}


#pragma mark - Animation delegate

-(void) animationDidStart:(CAAnimation *)anim
{
}

-(void) animationDidStop:(CABasicAnimation *)anim finished:(BOOL)flag
{
    [self.layer removeAnimationForKey:animationKey];
}


@end
