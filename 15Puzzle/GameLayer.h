//
//  GameLayer.h
//  15Puzzle
//
//  Created by k16 on 2013/01/04.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Tile.h"
#import "PlayHavenSDK.h"


@interface GameLayer : CCLayer<PHPublisherContentRequestDelegate>
{
    int _tileCount;      // Total tile nums
    CCArray* _tileList;  //
    
    int _actionCount;          // Total action nums have to move tiles
    int _finishedActionCount;  // Total action nums have finished to move
    
    PHNotificationView *_notificationView;
    UITextField *_placementField;
    PHPublisherContentRequest *_request;
}

+(CCScene*)scene;
@property (nonatomic, retain) IBOutlet UITextField *placementField;
@property (nonatomic, retain) IBOutlet UISwitch *showsOverlaySwitch;
@property (nonatomic, retain) IBOutlet UISwitch *animateSwitch;
@property (nonatomic, retain) PHPublisherContentRequest *request;

-(void)addMessage:(NSString *)message;

@end
