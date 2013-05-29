//
//  GameLayer.m
//  15Puzzle
//
//  Created by Keiichiro Nagashima on 2013/01/04.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"
#import "ClearLayer.h"


@interface GameLayer()
-(void)setTiles;
-(void)shuffle;
-(Tile*)getTileAtNow:(int)now;
-(void)NotifyFromNotificationCenter:(NSNotification*)notification;
-(void)tapTile:(Tile*)tile;
@end


@implementation GameLayer

@synthesize placementField = _placementField;
@synthesize request = _request;
@synthesize showsOverlaySwitch;
@synthesize animateSwitch;

+(CCScene*)scene
{
    CCScene* scene = [CCScene node];
    GameLayer* layer = [GameLayer node];
    [scene addChild:layer];
    
    return scene;
}

-(id)init
{
    if(self = [super init])
    {
        _tileCount = 16;  // will make 4x4
        _tileList = nil;
        
        _actionCount = 0;
        _finishedActionCount = 0;
    }
    return self;
}

-(void)dealloc
{
    [PHAPIRequest cancelAllRequestsWithDelegate:self];
    
    [_notificationView release], _notificationView = nil;
    [_placementField release], _placementField = nil;
    [_request release], _request = nil;
    
    [_tileList release];
    
    [super dealloc];
}

-(void)prePlayHavenRequest
{
    [[PHPublisherContentRequest requestForApp:@"b683fd5447b04d70aad080ba2de19705" secret:@"4b5231cfbb734a2e9d3c907fa2e331d3" placement:@"more_games" delegate:self] preload];
    
    _notificationView = [[PHNotificationView alloc] initWithApp:@"b683fd5447b04d70aad080ba2de19705" secret:@"4b5231cfbb734a2e9d3c907fa2e331d3" placement:@"more_games"];
    
    _notificationView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    [[[CCDirector sharedDirector] openGLView] addSubview:_notificationView];
//    [[[CCDirector sharedDirector] _notificationView] addSubview:_notificationView];
    [_notificationView setCenter:CGPointMake(winSize.width - 22, 19)];
    [_notificationView refresh];

}

-(void)startPlayHavenRequest
{
    if (self.request == nil)
    {
        NSString *placement = (![self.placementField.text isEqualToString:@""])? self.placementField.text : @"more_games";
        PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:@"b683fd5447b04d70aad080ba2de19705" secret:@"4b5231cfbb734a2e9d3c907fa2e331d3" placement:placement delegate:self];
        
        [request setShowsOverlayImmediately:[showsOverlaySwitch isOn]];
        [request setAnimated:[animateSwitch isOn]];
        [request send];
    
        [self setRequest:request];
    }
    else
    {
        [self addMessage:@"Request canceled!"];
    
        [self.request cancel];
        self.request = nil;
    }
}

-(void)onEnter
{
    [super onEnter];
    
    [self prePlayHavenRequest];
    
    // To regist observer method to center
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NotifyFromNotificationCenter:) name:nil object:nil];
    
    // To read in the picture for CCTexture2D
    CCTexture2D* tex = [[[CCTexture2D alloc] initWithImage:[UIImage imageNamed:@"image.png"]] autorelease];
    
    // To calculate each side of tile nums
    int sideTileCount = (int)sqrt((double)_tileCount);

    // To calculate tile size
    CGSize tileSize = CGSizeMake(tex.contentSize.width / sideTileCount, tex.contentSize.height / sideTileCount);
    
    // To make array to manage tile
    _tileList = [[CCArray alloc] initWithCapacity:_tileCount];
    
    // To make 16 tiles
    for(int i = 0; i < _tileCount; i++)
    {
        // To cut tile suitable
        Tile* tile = [Tile spriteWithTexture:tex rect:CGRectMake(tileSize.width * (i % sideTileCount), tileSize.height * (i / sideTileCount), tileSize.width, tileSize.height)];
        
        // To set array
        [_tileList addObject:tile];
        
        // To add layer
        [self addChild:tile z:1];
        
        // To record correct tile's position
        tile.Answer = i;
        
        // To make frame
        [tile createFrame];
        
        // if it is last, to set empty tile
        if(i == _tileCount - 1)
        {
            tile.IsBlank = YES;
        }
    }
    
    // To set tiles
    [self setTiles];
    
    // To shuffle tiles
    [self shuffle];
    
    [self startPlayHavenRequest];
}

-(void)onExit
{
    // To unregist observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_notificationView removeFromSuperview];
    [super onExit];
}

-(void)NotifyFromNotificationCenter:(NSNotification *)notification
{
    if(notification.name == TILE_MSG_NOTIFY_TAP)
    {
        [self tapTile:notification.object];
    }
}

-(void)tapTile:(Tile *)tile
{
    // result
    BOOL checkResult = NO;
    
    // To calculate each side of tile nums
    int sideTileCount = (int)sqrt((double)_tileCount);
    
    // To create temporary array to use checking
    CCArray* searchList = [CCArray arrayWithCapacity:sideTileCount];

    // Init
    _finishedActionCount = 0;
    
    // To get empty tile
    Tile* blankTile = [_tileList lastObject];
    
    // To check tile four direction line
    
    // 1, above
    int checkPosition = blankTile.Now - sideTileCount;
    while(checkPosition > -1)
    {
        [searchList addObject:[self getTileAtNow:checkPosition]];
        if(tile.Now == checkPosition)
        {
            checkResult = YES;
            break;
        }
        checkPosition -= sideTileCount;
    }
    
    // 2, Right
    if(checkResult == NO)
    {
        [searchList removeAllObjects];
        checkPosition = blankTile.Now + 1;
    
        while((checkPosition % sideTileCount != 0) && (checkPosition < _tileList.count))
        {
            [searchList addObject:[self getTileAtNow:checkPosition]];
            if(tile.Now == checkPosition)
            {
                checkResult = YES;
                break;
            }
            checkPosition++;
        }
    }

    // 3, bottom
    if(checkResult == NO)
    {
        [searchList removeAllObjects];
        checkPosition = blankTile.Now + sideTileCount;
        
        while(checkPosition < _tileList.count)
        {
            [searchList addObject:[self getTileAtNow:checkPosition]];
            if(tile.Now == checkPosition)
            {
                checkResult = YES;
                break;
            }
            checkPosition += sideTileCount;
        }
    }

    // 3, bottom
    if(checkResult == NO)
    {
        [searchList removeAllObjects];
        checkPosition = blankTile.Now - 1;
        
        while((checkPosition % sideTileCount != sideTileCount - 1) && (checkPosition > -1))
        {
            [searchList addObject:[self getTileAtNow:checkPosition]];
            if(tile.Now == checkPosition)
            {
                checkResult = YES;
                break;
            }
            checkPosition--;
        }
    }
    
    // if the checkResult is YES, the tile object which is in searchList is moving tile
    if(checkResult)
    {
        // Due to obtain action movie each tile, to make CCAction array to keep it
        CCArray* actionList = [CCArray arrayWithCapacity:searchList.count];
        
        // To make action movie in searchList tils
        for(Tile* tile in searchList)
        {
            // To keep temporary empty tile's now val
            int tempIndex = blankTile.Now;
            
            // To make action to move empty tile's position
            id move = [CCMoveTo actionWithDuration:0.1 position:blankTile.position];
            
            // To make action to judge clear or not
            id moveEnd = [CCCallBlock actionWithBlock:^{
                // Increment finished action
                _finishedActionCount++;
            
                if (_finishedActionCount == _actionCount)
                {
                    // if all action complete, to judge clear or not
                    BOOL isClear = YES;
                    for(Tile* tile in _tileList)
                    {
                        // if all tiles are correct postion, it will be clear
                        if(tile.Answer != tile.Now)
                        {
                            isClear = NO;
                            break;
                        }
                    }
                
                    if (isClear)
                    {
                        // To display ClearLayer
                        [self addChild:[ClearLayer node] z:2];
                    
                        // To display completion picture and to set NO to property
                        ((Tile*)[_tileList lastObject]).IsBlank = NO;
                    }
                }
            }];
            
            // To do seaquence moving action and finished moving action
            id seq = [CCSequence actions:move, moveEnd, nil];
            
            
            // To replace empty tile's postion with moving tile's position
            blankTile.position = tile.position;
            blankTile.Now = tile.Now;
            tile.Now = tempIndex;
            
            // To set action to array
            //[actionList addObject:move];
            
            [actionList addObject:seq];  // change for seq object
        }
        
        _actionCount = actionList.count;
        
        // To apply action for each tiles
        for(int i = 0; i < searchList.count; i++)
        {
            Tile* tile = [searchList objectAtIndex:i];
            id action = [actionList objectAtIndex:i];
            [tile runAction:action];
        }
    }
}

-(void)setTiles
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    // To get tile size
    CGSize tileSize = ((Tile*)[_tileList objectAtIndex:0]).contentSize;
    
    // To calculate each side of tile nums
    int sideTileCount = (int)sqrt((double)_tileCount);
    
    // To get horizontal space
    float blankX = (winSize.width - tileSize.width * sideTileCount) / 2;
    
    // To get vertical space
    float blankY = (winSize.height - tileSize.height * sideTileCount) / 2;
    
    // To set correct position seaquential
    for(int i = 0; i < _tileList.count; i++)
    {
        Tile* tile = [_tileList objectAtIndex:i];
        tile.position = CGPointMake(blankX + tileSize.width / 2 + tileSize.width * (i % sideTileCount), winSize.height - blankY - tileSize.height / 2 - tileSize.height * (i / sideTileCount));
        
        // To record current tiles' position
        tile.Now = i;
    }
}

-(void)shuffle
{
    // To get empty tile
    Tile* blankTile = [_tileList lastObject];
    
    // To calculate each side of tile nums
    int sideTileCount = (int)sqrt((double)_tileCount);

    // To move one hundred times as total tile num
    for(int i = 0; i < _tileCount * 100; i++)
    {
        // Initialize check val
        int checkPosition = -1;
        
        // To decide random direction
        int direction = arc4random() % 4;
        switch(direction)
        {
            // if it will move above, to set current position number
            case 0:
            {
                checkPosition = blankTile.Now - sideTileCount;
                if(checkPosition > 0)
                {
                }
                else
                {
                    // if it is impossible to move any more, to reset check val
                    checkPosition = -1;
                }
                break;
            }
            case 1:
            {
                // if it will move right, to set current position number
                checkPosition = blankTile.Now + 1;
                if(checkPosition % sideTileCount != 0)
                {
                }
                else
                {
                    // if it is impossible to move any more, to reset check val
                    checkPosition = -1;
                }
                break;
            }
            case 2:
            {
                // if it will move bottom, to set current position number
                checkPosition = blankTile.Now + sideTileCount;
                if(checkPosition < _tileList.count)
                {
                }
                else
                {
                    // if it is impossible to move any more, to reset check val
                    checkPosition = -1;
                }
                break;
            }
            case 3:
            {
                // if it will move bottom, to set current position number
                checkPosition = blankTile.Now - 1;
                if(checkPosition % sideTileCount != sideTileCount - 1)
                {
                }
                else
                {
                    // if it is impossible to move any more, to reset check val
                    checkPosition = -1;
                }
                break;
            }
            default:
            {
                checkPosition = -1;
                break;
            }
        }
        
        if (checkPosition > -1)
        {
            // To get tile after moving
            Tile* tile = [self getTileAtNow:checkPosition];
            
            // To replace moving tile with empty tile
            int tempIndex = blankTile.Now;
            CGPoint tempPosition = blankTile.position;
            blankTile.position = tile.position;
            blankTile.Now = tile.Now;
            tile.Now = tempIndex;
            tile.position = tempPosition;
        }
    }
}

// To return tile object which is designed
-(Tile*)getTileAtNow:(int)now
{
    Tile* result = nil;
    for(Tile* tile in _tileList)
    {
        if(tile.Now == now)
        {
            result = tile;
            break;
        }
    }
    return result;
}

-(void)addMessage:(NSString *)message
{
}

#pragma mark - PHPublisherContentRequestDelegate
-(void)requestWillGetContent:(PHPublisherContentRequest *)request{
    NSString *message = [NSString stringWithFormat:@"Getting content for placement: %@", request.placement];
    [self addMessage:message];
}

-(void)requestDidGetContent:(PHPublisherContentRequest *)request{
    NSString *message = [NSString stringWithFormat:@"Got content for placement: %@", request.placement];
    [self addMessage:message];
    //[self addElapsedTime];
}

-(void)request:(PHPublisherContentRequest *)request contentWillDisplay:(PHContent *)content{
    NSString *message = [NSString stringWithFormat:@"Preparing to display content: %@",content];
    [self addMessage:message];
    
    //[self addElapsedTime];
}

-(void)request:(PHPublisherContentRequest *)request contentDidDisplay:(PHContent *)content{
    //This is a good place to clear any notification views attached to this request.
    [_notificationView clear];
    
    NSString *message = [NSString stringWithFormat:@"Displayed content: %@",content];
    [self addMessage:message];
    
    //[self addElapsedTime];
}

-(void)request:(PHPublisherContentRequest *)request contentDidDismissWithType:(PHPublisherContentDismissType *)type{
    NSString *message = [NSString stringWithFormat:@"[OK] User dismissed request: %@ of type %@",request, type];
    [self addMessage:message];
    
    //[self finishRequest];
}

-(void)request:(PHPublisherContentRequest *)request didFailWithError:(NSError *)error{
    NSString *message = [NSString stringWithFormat:@"[ERROR] Failed with error: %@", error];
    //[self addMessage:message];
    //[self finishRequest];
    CCLOG(@"%@", message);
}

-(void)request:(PHPublisherContentRequest *)request unlockedReward:(PHReward *)reward{
    NSString *message = [NSString stringWithFormat:@"Unlocked reward: %dx %@", reward.quantity, reward.name];
    [self addMessage:message];
}

/*
 -(void)request:(PHPublisherContentRequest *)request makePurchase:(PHPurchase *)purchase{
 NSString *message = [NSString stringWithFormat:@"Initiating purchase for: %dx %@", purchase.quantity, purchase.productIdentifier];
 [self addMessage:message];
 
 [[IAPHelper sharedIAPHelper] startPurchase:purchase];
}
*/


@end
