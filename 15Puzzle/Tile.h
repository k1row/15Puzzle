//
//  Tile.h
//  15Puzzle
//
//  Created by k16 on 2013/01/04.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#define TILE_MSG_NOTIFY_TOUCH_HOLD  @"TileMsgNotifyTouchHold"
#define TILE_MSG_NOTIFY_TOUCH_END   @"TileMsgNotifyTouchEnd"
#define TILE_MSG_NOTIFY_TOUCH_MOVE  @"TileMsgNotifyTouchMove"
#define TILE_MSG_NOTIFY_SHOW_NUMBER @"TileMsgNotifyShowNumber"
#define TILE_MSG_NOTIFY_HIDE_NUMBER @"TileMsgNotifyHideNumber"
#define TILE_MSG_NOTIFY_TAP         @"TileMsgNotifyTap"


@interface Tile : CCSprite<CCTargetedTouchDelegate>
{
    CCSprite* _imgFrame;       // Frame of incorrect
    CCSprite* _imgBlinkFrame;  // Frame of correct

    CCLabelTTF* _lblAnswer;    // display correct position
    int _answer;               // correct position
    
    int _now;                  // current position
    BOOL _isTouchBegin;        //
    CGPoint _touchLocation;
    ccTime _deltaTime;         // progress time
    BOOL _isBlank;
}

@property (nonatomic, readwrite)int Answer;
@property (nonatomic, readwrite)int Now;
@property (nonatomic, readonly)BOOL IsTouchHold;
@property (nonatomic, readwrite)BOOL IsBlank;


-(void) createFrame;
@end
