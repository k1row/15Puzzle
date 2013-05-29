//
//  TitleLayer.m
//  15Puzzle
//
//  Created by Keiichiro Nagashima on 2013/01/04.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "TitleLayer.h"
#import "GameLayer.h"


@implementation TitleLayer

+(CCScene*)scene
{
    CCScene* scene = [CCScene node];
    TitleLayer* layer = [TitleLayer node];
    [scene addChild:layer];
    return scene;
}

-(void)onEnter
{
    [super onEnter];
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    // display background
    CCSprite* backImage = [CCSprite spriteWithFile:@"image.png"];
    backImage.position = CGPointMake(winSize.width / 2, winSize.height / 2);
    backImage.color = ccc3(100, 100, 100);
    [self addChild:backImage z:0];
    
    // display game start menu
    [CCMenuItemFont setFontName:@"Helvetica-BoldOblique"];
    [CCMenuItemFont setFontSize:60];
    CCMenuItemFont* item = [CCMenuItemFont itemFromString:@"Game Start" block:^(id sender) {
        // To display GameLayer
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1.0 scene:[GameLayer scene] withColor:ccWHITE]];
    }];

    CCMenu* menu = [CCMenu menuWithItems:item, nil];
    menu.position = CGPointMake(winSize.width / 2, 60);
    [self addChild:menu];
}

@end



