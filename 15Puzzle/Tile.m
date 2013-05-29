//
//  Tile.m
//  15Puzzle
//
//  Created by Keiichiro Nagashima on 2013/01/04.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "Tile.h"


@interface Tile()
// Create same size between myself and image
-(UIImage*)shapingImageNamed:(NSString*)imageNamed;
// Notification event from center
-(void)NotifyFromNotificationCenter:(NSNotification*)notification;
// To return button location contains touch location
-(BOOL)containsTouchLocation:(UITouch*)touch;
//
-(void)showGuideNumByTouch:(UITouch*)touch;
//
-(void)scheduleEventTouchHold:(ccTime)delta;
// To display correct flame animation
-(void)blinkFrame;
@end

@implementation Tile	

@dynamic Answer;
-(int)Answer { return _answer; }
-(void)setAnswer:(int)Answer
{
    _answer = Answer;
    
    if (_lblAnswer == nil)
    {
        _lblAnswer = [CCLabelTTF labelWithString:@"99" fontName:@"Arial-BoldMT" fontSize:40];
        _lblAnswer.position = CGPointMake(self.contentSize.width / 2, self.contentSize.height /2);
        _lblAnswer.color = ccc3(255, 100, 40);
        [self addChild:_lblAnswer z:2];
        _lblAnswer.visible = NO;
        
        // The font size should be 0.8 times as big as image size
        _lblAnswer.scale = MIN((self.contentSize.width * 0.8) / _lblAnswer.contentSize.width, (self.contentSize.height * 0.8) / _lblAnswer.contentSize.height);
        if (_lblAnswer.scale > 1.0)
        {
            _lblAnswer.scale = 1.0;
        }
    }
    
    [_lblAnswer setString:[NSString stringWithFormat:@"%d", Answer + 1]];
}

@dynamic IsBlank;
-(BOOL)IsBlank { return _isBlank; }
-(void)setIsBlank:(BOOL)IsBlank
{
    _isBlank = IsBlank;
    if (_isBlank)
    {
        // if blank it sets clearly
        self.opacity = 0;
    }
    else
    {
        self.opacity = 255;
    }
}

@synthesize Now = _now;
@synthesize IsTouchHold = _isTouchHold;


-(id)init
{
    if (self = [super init])
    {
        // Initialize member val
        _imgFrame = nil;
        _imgBlinkFrame = nil;
        
        _lblAnswer = nil;
        _answer = 0;
        
        _now = 0;
        _isTouchBegin = NO;
        _isTouchHold = NO;
        _touchLocation = CGPointZero;
        _deltaTime = 0.0;
        _isBlank = NO;
    }
    return self;
}

-(void)onEnter
{
    [super onEnter];
    
    // To regist CCTouchDispather (high priority)
    //[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-9 swallowsTouches:YES];
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NotifyFromNotificationCenter:) name:nil object:nil];
}

-(void)onExit
{
    [super onExit];
    [[CCTouchDispatcher sharedDispatcher] removeAllDelegates];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL bResult = NO;
    
    //
    _isTouchHold = NO;
    
    if ([self containsTouchLocation:touch])
    {
        // If my self is touched, touch position will be convert and save cocos2d postion
        CGPoint touchLocation = [touch locationInView:[touch view]];
        _touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        
        // Make hold schedule
        _deltaTime = 0.0;
        [self schedule:@selector(scheduleEventTouchHold:)];
        
        // Begin touch flg
        _isTouchBegin = YES;
        bResult = YES;
    }
    return bResult;
}

// Notification while touching button
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // To convert the touching position to cocos2d postion
    CGPoint touchLocation = [touch locationInView:[touch view]];
    CGPoint currentTouchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    	
    // when the postion move from beginning postion	above a central level, we are treated as moving
    CGPoint difference = ccpSub(_touchLocation, currentTouchLocation);
    float factor = 20;
    
    if ((abs(difference.x) > factor)||
        (abs(difference.y) > factor))
    {
        NSDictionary* dic = [NSDictionary dictionaryWithObject:touch forKey:TILE_MSG_NOTIFY_TOUCH_MOVE];
        [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_TOUCH_MOVE object:self userInfo:dic];
        
        // It will change current touch postion to center position
        _touchLocation = currentTouchLocation;
    }
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // To stop hold schedule
    [self unschedule:@selector(scheduleEventTouchHold:)];
    
    if(_isTouchBegin == YES)
    {
        if([self containsTouchLocation:touch])
        {
            if(_isTouchHold == NO)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_TAP object:self];
            }
        }
    }
    
    // To issue touch notification
    [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_TOUCH_END object:self];
    
    // Init touch flg
    _isTouchBegin = NO;
    
}

// To return touch postion contain button position
-(BOOL)containsTouchLocation:(UITouch *)touch
{
    // To convert touch postion to cocos2d postion
    CGPoint touchLocation = [touch locationInView:[touch view]];
    CGPoint location = [[CCDirector sharedDirector] convertToGL:touchLocation];

    // To correspond parent node moves get boundingBox property.
    CGRect boundingBox = self.boundingBox;

    // To inherit CCLayer explore parent node
    CCNode* parent = self.parent;
    while (parent != NULL)
    {
        if ([parent isKindOfClass:[CCLayer class]])
        {
            break;
        }
        else
        {
            parent = parent.parent;
        }
    }
    
    
    if (parent != NULL)
    {
        // To add parent node postion and self postion
        boundingBox.origin = ccpAdd(boundingBox.origin, parent.position);
    }

    return CGRectContainsPoint(boundingBox, location);
}

// To display correct flame
-(void)blinkFrame
{
    float maxOpacity = 127;
    _imgBlinkFrame.opacity = maxOpacity;
    _imgBlinkFrame.visible = YES;
    
    id fadeOut = [CCFadeTo actionWithDuration:0.3 opacity:0];
    id fadeIn = [CCFadeTo actionWithDuration:0.8 opacity:maxOpacity];
    id seq = [CCSequence actions:fadeOut, fadeIn, nil];
    id rep = [CCRepeatForever actionWithAction:seq];
    
    [_imgBlinkFrame runAction:rep];
}

// Notification event from cener
-(void)NotifyFromNotificationCenter:(NSNotification *)notification
{
    if (notification.name == TILE_MSG_NOTIFY_TOUCH_END)
    {
        // one of tile is held
        // display guide number
        if (_isBlank == NO)
        {
            // normal tile
            if (_answer == _now)
            {
                // if the tile is correct, it will be bllinked of correct
                [self blinkFrame];
            }
            else
            {
                // if the tile is NOT correct, it will be blinked of incorrect
                _lblAnswer.visible = YES;
                _imgFrame.visible = YES;
            }
        }
        else
        {
            // if the tile is empty, it will be blinked of incorrect
            _imgFrame.visible = YES;
        }
    }
    else if(notification.name == TILE_MSG_NOTIFY_TOUCH_END)
    {
        // Any tile will finish to touch and it will finish to display guide number
        _lblAnswer.visible = NO;
        _imgFrame.visible = NO;
        [_imgBlinkFrame stopAllActions];
        _imgBlinkFrame.visible = NO;
    }
    else if(notification.name == TILE_MSG_NOTIFY_TOUCH_MOVE)
    {
        // Any tile will finish to touch and it will finish to display guide number
        if (((Tile*)notification.object).IsTouchHold)
        {
            // when tile is held, to judge to display guidenumber or not from currenct touch position
            [self showGuideNumByTouch:[notification.userInfo objectForKey:TILE_MSG_NOTIFY_TOUCH_MOVE]];
        }
    }
    else if(notification.name == TILE_MSG_NOTIFY_SHOW_NUMBER)
    {
        // To display any tile's correct postion or to display empty tile's guidenumber
        if ((_answer == _now) && (_isBlank == NO))
        {
            // if self is correct tile, to display guidenumber
            _lblAnswer.visible = YES;
        }
        else if(_isBlank && notification.object != self)
        {
            // if self is empty and didn't get any notification, to display guidenumber
            _lblAnswer.visible = NO;
        }
    }
    else if(notification.name == TILE_MSG_NOTIFY_HIDE_NUMBER)
    {
        // To not display guidenumber
        if (_isBlank || (_answer == _now))
        {
            // if empty tile or correct tile, it will erase guidenumber
            _lblAnswer.visible = NO;
        }
    }
}

//
-(void)showGuideNumByTouch:(UITouch *)touch
{
    if([self containsTouchLocation:touch])
    {
        if ((_answer == _now) || _isBlank)
        {
            // if self tile is correct position or empty, it will display guidenumber
            _lblAnswer.visible = YES;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_SHOW_NUMBER object:self];
            
        }
        else if(_answer != _now)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_HIDE_NUMBER object:self];
        }
    }
}

-(void)scheduleEventTouchHold:(ccTime)delta
{
    if(_isTouchBegin == NO)
    {
        // it is not self tile's touch event
        return;
    }
    
    _deltaTime += delta;
    if (_deltaTime > 2.0)
    {
        // if touch time is over 2sec, it regards hold
        _isTouchHold = YES;
        
        // To issue notification
        [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_TOUCH_HOLD object:self];
        
        //
        [self unschedule:_cmd];
        
        if ((_answer == _now) || _isBlank)
        {
            // To display guidenumber
            _lblAnswer.visible = YES;
            
            // To issue notification to display guidenumber
            [[NSNotificationCenter defaultCenter] postNotificationName:TILE_MSG_NOTIFY_SHOW_NUMBER object:self];
        }
    }
}

// Create same size between myself and image
-(UIImage*)shapingImageNamed:(NSString *)imageNamed
{
    UIImage* resultImage = [UIImage imageNamed:imageNamed];
    UIGraphicsBeginImageContext(CGSizeMake(self.contentSize.width, self.contentSize.height));
    [resultImage drawInRect:CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
    resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}


-(void)createFrame
{
    if (_imgFrame != nil)
    {
        [_imgFrame removeFromParentAndCleanup:YES];
        _imgFrame = nil;
    }
    if (_imgBlinkFrame != nil)
    {
        [_imgBlinkFrame removeFromParentAndCleanup:YES];
        _imgBlinkFrame = nil;
    }
    
    // Making frame img as same as myself
    _imgFrame = [CCSprite spriteWithCGImage:[self shapingImageNamed:@"Frame.png"].CGImage key:nil];
    _imgFrame.position = CGPointMake(self.contentSize.width /2 , self.contentSize.height / 2);
    _imgFrame.opacity = 127;
    [self addChild:_imgFrame z:1];
    _imgFrame.visible = NO;
    
    // Making frame img as same as myself
    _imgBlinkFrame = [CCSprite spriteWithCGImage:[self shapingImageNamed:@"BlinkFrame.png"].CGImage key:nil];
    _imgBlinkFrame.position = CGPointMake(self.contentSize.width /2 , self.contentSize.height / 2);
    _imgBlinkFrame.opacity = 127;
    [self addChild:_imgBlinkFrame z:1];
    _imgBlinkFrame.visible = NO;

}
@end
