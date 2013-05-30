//
//  ClearLayer.m
//  15Puzzle
//
//  Created by k16 on 2013/01/04.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "ClearLayer.h"
#import "TitleLayer.h"


@implementation ClearLayer

-(void)onEnter
{
    [super onEnter];
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    // Overlay translucent color layer due to see the message
    CCLayerColor* layer = [CCLayerColor layerWithColor:ccc4(100, 100, 100, 100)];
    [self addChild:layer];
    
    // To make clear label
    CCLabelTTF* label = [CCLabelTTF labelWithString:@"Congratulations!!" fontName:@"Chalkduster" fontSize:40];
    label.color = ccc3(30, 30, 255);
    label.scaleY = 1.5;
    label.position = CGPointMake(winSize.width / 2, winSize.height - winSize.height / 4);
    [self addChild:label];
    
    // To make "Return title"
    [CCMenuItemFont setFontName:@"Helvetica-BoldOblique"];
    [CCMenuItemFont setFontSize:30];
    CCMenuItemFont* item = [CCMenuItemFont itemFromString:@"Back to Title" block:^(id sender){
        // To display titlelayer
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:[TitleLayer scene] withColor:ccWHITE]];
    }];
        
    CCMenu* menu = [CCMenu menuWithItems:item, nil];
    menu.position = CGPointMake(winSize.width / 2, 60);
    [self addChild:menu];
}
@end
