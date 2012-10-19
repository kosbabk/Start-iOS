//
//  AlarmView.m
//  Start
//
//  Created by Nick Place on 6/15/12.
//  Copyright (c) 2012 TackMobile. All rights reserved.
//

#import "AlarmView.h"

@implementation AlarmView
@synthesize delegate, index, isSet, isTimerMode, newRect;
@synthesize alarmInfo, countdownEnded;
@synthesize radialGradientView, /*backgroundImage,*/ patternOverlay, toolbarImage;
@synthesize selectSongView, selectActionView, selectDurationView, selectedTimeView, deleteLabel;
@synthesize countdownView, timerView, selectAlarmBg;

const float Spacing = 0.0f;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {        
        shouldSet = AlarmViewShouldNone;
        [self setClipsToBounds:YES];
        pickingSong = NO;
        pickingAction = NO;
        cancelTouch = NO;
        countdownEnded = NO;
        isSnoozing = NO;
        
        musicManager = [[MusicManager alloc] init];
        PListModel *pListModel = [delegate getPListModel];
        
        // Views
        CGSize bgImageSize = CGSizeMake(520, 480);
        CGRect frameRect = [[UIScreen mainScreen] applicationFrame];
        
        // bgImageRect = 
        radialRect = CGRectMake((self.frame.size.width-bgImageSize.width)/2, (self.frame.size.height-bgImageSize.height)/2, bgImageSize.width, bgImageSize.height);;
        
        CGRect toolBarRect = CGRectMake(0, 0, self.frame.size.width, 135);
        selectSongRect = CGRectMake(Spacing-16, 0, frameRect.size.width-75, 80);
        selectActionRect = CGRectMake(Spacing+frameRect.size.width-50, 0, 50, 80);
        selectDurRect = CGRectMake(Spacing, self.frame.size.height-frameRect.size.width-45, frameRect.size.width, frameRect.size.width);
        alarmSetDurRect = CGRectOffset(selectDurRect, 0, -150);
        timerModeDurRect = CGRectOffset(selectDurRect, 0, 150);
        selectedTimeRect = CGRectExtendFromPoint(CGRectCenter(selectDurRect), 65, 65);
        CGRect durationMaskRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        countdownRect = CGRectMake(Spacing, alarmSetDurRect.origin.y+alarmSetDurRect.size.height, frameRect.size.width, self.frame.size.height - (alarmSetDurRect.origin.y+alarmSetDurRect.size.height) - 65);
        timerRect = CGRectMake(Spacing, timerModeDurRect.origin.y-countdownRect.size.height, frameRect.size.width, countdownRect.size.height);
        CGRect deleteLabelRect = CGRectMake(Spacing, 0, frameRect.size.width, 70);
        CGRect selectAlarmRect = CGRectMake(0, self.frame.size.height-50, self.frame.size.width, 50);
        
        // backgroundImage = [[UIImageView alloc] initWithFrame:bgImageRect];
        radialGradientView = [[RadialGradientView alloc] initWithFrame:radialRect];
        
        //patternOverlay = [[UIImageView alloc] initWithFrame:radialGradientRect];
        toolbarImage = [[UIImageView alloc] initWithFrame:toolBarRect];
        selectSongView = [[SelectSongView alloc] initWithFrame:selectSongRect delegate:self presetSongs:[pListModel getPresetSongs]];
        selectActionView = [[SelectActionView alloc] initWithFrame:selectActionRect delegate:self actions:[pListModel getActions]];
        selectDurationView = [[SelectDurationView alloc] initWithFrame:selectDurRect delegate:self];
        durImageView = [[UIImageView alloc] init];
        selectedTimeView = [[SelectedTimeView alloc] initWithFrame:selectedTimeRect];
        countdownView = [[CountdownView alloc] initWithFrame:countdownRect];
        UIView *durationMaskView = [[UIView alloc] initWithFrame:durationMaskRect];
        timerView = [[TimerView alloc] initWithFrame:timerRect];
        deleteLabel = [[UILabel alloc] initWithFrame:deleteLabelRect];
        selectAlarmBg = [[UIImageView alloc] initWithFrame:selectAlarmRect];
        
        [selectAlarmBg setImage:[UIImage imageNamed:@"bottom-fade"]];
        
        //[self addSubview:backgroundImage];
        [self addSubview:radialGradientView];
        //[self addSubview:patternOverlay];
        //[self addSubview:selectAlarmBg];
        [self addSubview:countdownView];
        [self addSubview:timerView];
        [self addSubview:durationMaskView];
            [durationMaskView addSubview:selectDurationView];
        [self addSubview:durImageView];
        //[self addSubview:toolbarImage];
        [self addSubview:selectSongView];
        [self addSubview:selectActionView];
        [self addSubview:selectedTimeView];
        [self addSubview:deleteLabel];
        
        [deleteLabel setFont:[UIFont fontWithName:@"Roboto" size:30]];
        [deleteLabel setBackgroundColor:[UIColor clearColor]]; [deleteLabel setTextColor:[UIColor whiteColor]];
        [deleteLabel setAlpha:0];
        [deleteLabel setTextAlignment:UITextAlignmentCenter];
        [deleteLabel setNumberOfLines:0];
        [deleteLabel setText:@"Pinch to Delete"];
                
        [patternOverlay setImage:[UIImage imageNamed:@"grid"]];
        
        [durImageView setAlpha:0];
        [durImageView setUserInteractionEnabled:NO];
        
        // pinch to delete
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(alarmPinched:)];
        [self addGestureRecognizer:pinch];
        
        // initial properties
        [selectedTimeView updateDate:[selectDurationView getDate] part:SelectDurationNoHandle];
        [toolbarImage setImage:[UIImage imageNamed:@"toolbarBG"]];
        //[backgroundImage setImage:[UIImage imageNamed:@"epsilon"]];
        [self setBackgroundColor:[UIColor blackColor]];
        [countdownView setAlpha:0];
        [timerView setAlpha:0];
        [patternOverlay setAlpha:0];
        [toolbarImage setAlpha:0];
        [selectAlarmBg setAlpha:0];
        CGRect selectActionTableViewRect = CGRectMake(0, 0, frameRect.size.width-75, self.frame.size.height);
        [selectActionView.actionTableView setFrame:selectActionTableViewRect];
        
        // add gradient mask to countdownMaskView
        CAGradientLayer *gradient = [CAGradientLayer layer];
        NSArray *gradientColors = [NSArray arrayWithObjects:
                                   (id)[[UIColor clearColor] CGColor],
                                   (id)[[UIColor whiteColor] CGColor],
                                   /*(id)[[UIColor whiteColor] CGColor],
                                   (id)[[UIColor clearColor] CGColor],*/ nil];
        
        float topFadeHeight = toolBarRect.size.height/self.frame.size.height;
        //float bottomFadeHeight = 1 - (selectAlarmRect.size.height/self.frame.size.height);
        
        NSArray *gradientLocations = [NSArray arrayWithObjects:
                                      [NSNumber numberWithFloat:0.05f],
                                      [NSNumber numberWithFloat:topFadeHeight],
                                      /*[NSNumber numberWithFloat:bottomFadeHeight],
                                      [NSNumber numberWithFloat:1.0f-.05f],*/ nil];
        
        [gradient setColors:gradientColors];
        [gradient setLocations:gradientLocations];
        [gradient setFrame:durationMaskRect];
        [durationMaskView.layer setMask:gradient];
        [durationMaskView.layer setMasksToBounds:YES];
        
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame index:(int)aIndex delegate:(id<AlarmViewDelegate>)aDelegate alarmInfo:(NSDictionary *)theAlarmInfo {
    if (theAlarmInfo)
        alarmInfo = [[NSMutableDictionary alloc] initWithDictionary:theAlarmInfo];
    else
        alarmInfo = nil;
    index = aIndex;
    delegate = aDelegate;
    return [self initWithFrame:frame];
}

- (void) viewWillAppear {
    // init the picker's stuff
    if (!alarmInfo) {
        NSArray *infoKeys = [[NSArray alloc] initWithObjects:@"date", @"songID", @"actionID", @"isSet", @"themeID", @"isTimerMode", @"timerDateBegan", nil];
        NSArray *infoObjects = [[NSArray alloc] initWithObjects:[NSDate dateWithTimeIntervalSinceNow:77777], [NSNumber numberWithInt:0],[NSNumber numberWithInt:0], [NSNumber numberWithBool:NO], [NSNumber numberWithInt:-1], [NSNumber numberWithBool:NO], [NSDate date], nil];
        alarmInfo = [[NSMutableDictionary alloc] initWithObjects:infoObjects forKeys:infoKeys];
        [selectDurationView setDate:[alarmInfo objectForKey:@"date"]];
        [selectSongView selectCellWithID:[NSNumber numberWithInt:-1]];
    } else {
        // init the duration picker & theme & action & song
        // select duration
        [selectDurationView setDate:[alarmInfo objectForKey:@"date"]];
        // select song
        [selectSongView selectCellWithID:(NSNumber *)[alarmInfo objectForKey:@"songID"]];
        // select action
        [selectActionView selectActionWithID:(NSNumber *)[alarmInfo objectForKey:@"actionID"]];
        // set isSet
        if ([(NSNumber *)[alarmInfo objectForKey:@"isSet"] boolValue]) {
            isSet = YES;
        }
        if ([(NSNumber *)[alarmInfo objectForKey:@"isTimerMode"] boolValue]) {
            isTimerMode = NO;
            [alarmInfo setObject:[NSNumber numberWithBool:NO] forKey:@"isTimerMode"];
        } // does not hide selectsong properly
        [self animateSelectDurToRest];
    }
    
    [selectedTimeView updateDate:selectDurationView.getDate part:0];
}

- (bool) canMove {
    return !(pickingSong || pickingAction);
}

- (void) alarmCountdownEnded {
    if (!countdownEnded && isSet) {
        [delegate alarmCountdownEnded:self];
        countdownEnded = YES;
        [selectedTimeView showSnooze];
    }
}

#pragma mark - Touches
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {    
    UITouch *touch = [touches anyObject];
    
    CGPoint touchLoc = [touch locationInView:self];
    CGPoint prevTouchLoc = [touch previousLocationInView:self];
    
    CGSize touchVel = CGSizeMake(touchLoc.x-prevTouchLoc.x, touchLoc.y-prevTouchLoc.y);
    
    // check if dragging between alarms
    if (pickingSong || pickingAction) {
        if (fabsf(touchVel.width) > 15) {
            if (touchVel.width < 0 && pickingSong) {
                [selectSongView quickSelectCell];
            } else {
                [selectActionView quickSelectCell];
            }
            cancelTouch = YES;
            if ([selectDurationView draggingOrientation] == SelectDurationDraggingHoriz)
                [selectDurationView setDraggingOrientation:SelectDurationDraggingCancel];
        }
    }
    if (fabsf(touchVel.width) > fabsf(touchVel.height) && !cancelTouch)
        if ([delegate respondsToSelector:@selector(alarmView:draggedWithXVel:)])
            [delegate alarmView:self draggedWithXVel:touchVel.width];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    cancelTouch = NO;
    if ([delegate respondsToSelector:@selector(alarmView:stoppedDraggingWithX:)])
        [delegate alarmView:self stoppedDraggingWithX:self.frame.origin.x];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

-(void)alarmPinched:(UIPinchGestureRecognizer *)pinchRecog {
    if (![self canMove])
        return;
    
    [selectDurationView touchesCancelled:nil withEvent:nil];
    if (pinchRecog.velocity < 0 && pinchRecog.state == UIGestureRecognizerStateBegan) {
        [durImageView setAlpha:0];

        [UIView animateWithDuration:.2 animations:^{
            [selectSongView setAlpha:0];
            [selectActionView setAlpha:0];
            [deleteLabel setAlpha:1];
        }];
        // compress the duration picker!
        UIGraphicsBeginImageContext(selectDurationView.bounds.size);
        [selectDurationView.layer renderInContext:UIGraphicsGetCurrentContext()];
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), selectedTimeView.frame.origin.x-selectDurationView.frame.origin.x,
                              selectedTimeView.frame.origin.y-selectDurationView.frame.origin.y);
        [selectedTimeView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *durImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [durImageView setImage:durImage];
        [durImageView sizeToFit];
        [durImageView setCenter:selectDurationView.center];
        // switch out the duration picker with a fake!
        [selectDurationView setAlpha:0];
        [selectedTimeView setAlpha:0];
        [durImageView setAlpha:1];
    } else if (pinchRecog.state == UIGestureRecognizerStateChanged) {
        [selectDurationView setAlpha:0];
        if (pinchRecog.scale > 1)
            pinchRecog.scale = 1;
        float scale = 1-(.1 * (1-pinchRecog.scale));
        float cScale = 1-(3 * (1-pinchRecog.scale));
        CGSize selectDurSize = selectDurationView.frame.size;
        if (isSet)
            countdownView.alpha = cScale;
        
        CGSize compressedDurSize =CGSizeMake(scale*selectDurSize.width, scale*selectDurSize.height);
        durImageView.frame = CGRectInset([self currRestedSelecDurRect], selectDurSize.width-compressedDurSize.width, selectDurSize.height-compressedDurSize.height);
        durImageView.alpha = scale;
        
    } else {
        if (pinchRecog.scale < .7) {
            if ([delegate respondsToSelector:@selector(alarmViewPinched:)] )
                if ([delegate alarmViewPinched:self])
                    return;
        }
        [UIView animateWithDuration:.2 animations:^{
            [durImageView setFrame:selectDurationView.frame];
            [selectSongView setAlpha:1];
            [selectActionView setAlpha:1];
            [deleteLabel setAlpha:0];
            if (isSet)
                countdownView.alpha = 1;
        } completion:^(BOOL finished) {
            [selectDurationView setAlpha:1];
            [selectedTimeView setAlpha:1];
            [durImageView setAlpha:0];
        }];
    }
}

#pragma mark - Posiitoning/Drawing
// parallax shiz
- (void) shiftedFromActiveByPercent:(float)percent {
    if (pickingSong || pickingAction)
        return;
    
    float screenWidth = self.frame.size.width;
    
    float durPickOffset =       200 * percent;
    float countDownOffset =     120 * percent;
    float songPickOffset =      100 * percent;
    float actionPickOffset =    75 * percent;
    float backgroundOffset =    (radialGradientView.frame.size.width - screenWidth)/2 * percent;
    
    CGRect shiftedDurRect = CGRectOffset([self currRestedSelecDurRect], durPickOffset, 0);
    CGRect shiftedCountdownRect = CGRectOffset(countdownRect, countDownOffset, 0);
    CGRect shiftedTimerRect = CGRectOffset(timerRect, countDownOffset, 0);
    CGRect shiftedSongRect = CGRectOffset(selectSongRect, songPickOffset, 0);
    CGRect shiftedActionRect = CGRectOffset(selectActionRect, actionPickOffset, 0);
    CGRect shiftedRadialRect = CGRectOffset(radialRect, backgroundOffset, 0);
    
    [selectDurationView setFrame:shiftedDurRect];
    [selectedTimeView setCenter:selectDurationView.center];
    [countdownView setFrame:shiftedCountdownRect];
    [timerView setFrame:shiftedTimerRect];
    [selectSongView setFrame:shiftedSongRect];
    [selectActionView setFrame:shiftedActionRect];
    [radialGradientView setFrame:shiftedRadialRect];
}
- (void) menuOpenWithPercent:(float)percent {
    [radialGradientView setAlpha:1.0f-(.8/(1.0f/percent))];
    if ([delegate respondsToSelector:@selector(alarmViewOpeningMenuWithPercent:)])
        [delegate alarmViewOpeningMenuWithPercent:percent];
}

- (void) menuCloseWithPercent:(float)percent {
    if (percent==1)
        [radialGradientView setAlpha:1];
    else 
        [radialGradientView setAlpha:(.8/(1.0f/percent))];
    
    if ([delegate respondsToSelector:@selector(alarmViewClosingMenuWithPercent:)])
        [delegate alarmViewClosingMenuWithPercent:percent];
}

- (void) updateThemeWithArtwork:(UIImage *)artwork {
    int themeID = [(NSNumber *)[alarmInfo objectForKey:@"themeID"] intValue];
    NSDictionary *theme;
    if (themeID < 7 && themeID > -1) { // preset theme
        theme = [musicManager getThemeWithID:themeID];
        artwork = [theme objectForKey:@"bgImg"];
        [radialGradientView setInnerColor:[theme objectForKey:@"bgInnerColor"] outerColor:[theme objectForKey:@"bgOuterColor"]];
        [toolbarImage setAlpha:0];
        [selectAlarmBg setAlpha:0];
        [patternOverlay setAlpha:0];
        [selectDurationView updateTheme:theme];
        NSLog(@"update theme");
    } else {
        [toolbarImage setAlpha:1];
        [selectAlarmBg setAlpha:1];
        theme = [musicManager getThemeForSongID:[alarmInfo objectForKey:@"songID"]];
        [selectDurationView updateTheme:theme];
        [radialGradientView setInnerColor:[theme objectForKey:@"bgInnerColor"] outerColor:[theme objectForKey:@"bgOuterColor"]];
        [toolbarImage setAlpha:0];
    }
    /*if (artwork) {
        // fade in the background 
        UIImageView *oldBg = [[UIImageView alloc] initWithImage:backgroundImage.image];
        [oldBg setFrame:backgroundImage.frame];
        [oldBg setAlpha:1];
        [backgroundImage setImage:artwork];
        [self insertSubview:oldBg aboveSubview:backgroundImage];
        [UIView animateWithDuration:.35 animations:^{
            [oldBg setAlpha:0];
        } completion:^(BOOL finished) {
            [oldBg removeFromSuperview];
        }];
    }*/
   // else // no theme
        //theme = [musicManager getThemeForSongID:[alarmInfo objectForKey:@"songID"]];
}

- (void) updateProperties {
    // make sure the date is in future
    if (!countdownEnded) {
        while ([(NSDate *)[alarmInfo objectForKey:@"date"] timeIntervalSinceNow] < 0)
            [alarmInfo setObject:[NSDate dateWithTimeInterval:86400 sinceDate:[alarmInfo objectForKey:@"date"]] forKey:@"date"];
        // check to see if it will go off
        if (isSet && floorf([[alarmInfo objectForKey:@"date"] timeIntervalSinceNow]) < .5){
            [self alarmCountdownEnded];}
       
        //if (selectDurationView.handleSelected == SelectDurationNoHandle)
        //   [selectDurationView setDate:[alarmInfo objectForKey:@"date"]];
        
        [countdownView updateWithDate:[alarmInfo objectForKey:@"date"]];
    } else {
        [countdownView updateWithDate:[NSDate date]];
    }
    
    if (isTimerMode)
        [timerView updateWithDate:[alarmInfo objectForKey:@"timerDateBegan"]];
}

- (CGRect) currRestedSelecDurRect {
    if (isSet)
        return alarmSetDurRect;
    else if (isTimerMode)
        return timerModeDurRect;
    else
        return selectDurRect;
}

#pragma mark - SelectSongViewDelegate
-(id) getDelegateMusicPlayer {
    return [delegate getMusicPlayer];
}
-(BOOL) expandSelectSongView {
    if (pickingAction || isSnoozing || countdownEnded)
        return NO;
    
    pickingSong = YES;
        
    CGSize screenSize = [[UIScreen mainScreen] applicationFrame].size;
    
    CGRect newSelectSongRect = CGRectMake(Spacing, selectSongRect.origin.y, screenSize.width, self.frame.size.height);
    CGRect selectDurPushedRect = CGRectOffset(selectDurationView.frame, selectSongView.frame.size.width, 0);
    CGRect selectActionPushedRect = CGRectOffset(selectActionView.frame, 90, 0);
    CGRect countdownPushedRect = CGRectOffset(countdownView.frame, selectSongView.frame.size.width, 0);
    CGRect timerPushedRect = CGRectOffset(timerRect, selectSongView.frame.size.width, 0);

    
    [UIView animateWithDuration:.2 animations:^{
        [self menuOpenWithPercent:1];
        
        [selectSongView setFrame:newSelectSongRect];
        
        [selectDurationView setFrame:selectDurPushedRect];
        [selectDurationView setAlpha:.6];
        
        [selectedTimeView setCenter:selectDurationView.center];
        [selectedTimeView setAlpha:.6];
        
        [selectActionView setFrame:selectActionPushedRect];
        [selectActionView setAlpha:.6];
        
        [countdownView setFrame:countdownPushedRect];
        [countdownView setAlpha:isSet?.6:0];
        
        [timerView setFrame:timerPushedRect];
        [timerView setAlpha:isTimerMode?.6:0];
    }];
        
    return YES;
}
-(void) compressSelectSong {
    pickingSong = NO;

    // compress the songSelectView
    [UIView animateWithDuration:.2 animations:^{
        [self menuCloseWithPercent:1];
        [selectSongView setFrame:selectSongRect];
        
        [selectDurationView setFrame:[self currRestedSelecDurRect]];
        [selectDurationView setAlpha:1];
        
        [selectedTimeView setCenter:selectDurationView.center];
        [selectedTimeView setAlpha:1];
        
        [selectActionView setFrame:selectActionRect];
        [selectActionView setAlpha:1];
        
        [countdownView setFrame:countdownRect];
        [countdownView setAlpha:isSet?1:0];
        
        [timerView setFrame:timerRect];
        [timerView setAlpha:isTimerMode?1:0];
    }];
}
     
-(void) songSelected:(NSNumber *)persistentMediaItemID withArtwork:(UIImage *)artwork theme:(NSNumber *)themeID {    
    // save the song ID
    [alarmInfo setObject:persistentMediaItemID forKey:@"songID"];
    [alarmInfo setObject:themeID forKey:@"themeID"];
    
    [self updateThemeWithArtwork:artwork];
}

#pragma mark - SelectActionViewDelegate
-(BOOL) expandSelectActionView {
    if (pickingAction || isSnoozing || countdownEnded)
        return NO;
    
    pickingAction = YES;
    
    CGRect newSelectActionRect = CGRectMake(75+Spacing, 0, [[UIScreen mainScreen] applicationFrame].size.width-75, self.frame.size.height);
    CGRect selectDurPushedRect = CGRectOffset(selectDurationView.frame, -newSelectActionRect.size.width, 0);
    CGRect selectSongPushedRect = CGRectOffset(selectSongView.frame, -selectSongView.frame.size.width + Spacing, 0);
    CGRect countdownPushedRect = CGRectOffset(countdownView.frame, -newSelectActionRect.size.width, 0);
    CGRect timerPushedRect = CGRectOffset(timerRect, -newSelectActionRect.size.width, 0);

    
    [UIView animateWithDuration:.2 animations:^{
        [self menuOpenWithPercent:1];
        [selectActionView setFrame:newSelectActionRect];
        
        [selectDurationView setFrame:selectDurPushedRect];
        [selectDurationView setAlpha:.9];
        
        [selectedTimeView setCenter:selectDurationView.center];
        [selectedTimeView setAlpha:9];
        
        [selectSongView setFrame:selectSongPushedRect];
        [selectSongView setAlpha:.9];
        
        [countdownView setFrame:countdownPushedRect];
        [countdownView setAlpha:isSet?.6:0];
        
        [timerView setFrame:timerPushedRect];
        [timerView setAlpha:isTimerMode?.6:0];
    }];
    
    
    
    return YES;
}

-(void) actionSelected:(NSNumber *)actionID {
    pickingAction = NO;
    
    // save the song ID
    [alarmInfo setObject:actionID forKey:@"actionID"];
    
    // compress the selectActionView
    [UIView animateWithDuration:.2 animations:^{
        [self menuCloseWithPercent:1];
        [selectActionView setFrame:selectActionRect];
        
        [selectDurationView setFrame:[self currRestedSelecDurRect]];
        [selectDurationView setAlpha:1];
        
        [selectedTimeView setCenter:selectDurationView.center];
        [selectedTimeView setAlpha:1];
        
        [selectSongView setFrame:selectSongRect];
        [selectSongView setAlpha:1];
        
        [countdownView setFrame:countdownRect];
        [countdownView setAlpha:isSet?1:0];
        
        [timerView setFrame:timerRect];
        [timerView setAlpha:isTimerMode?1:0];
    }];
}

#pragma mark - SelectDurationViewDelegate
-(void) durationDidChange:(SelectDurationView *)selectDuration {    
    // update selected time
    [selectedTimeView updateDate:[selectDuration getDate] part:selectDuration.handleSelected];
}

-(void) durationDidBeginChanging:(SelectDurationView *)selectDuration {
    CGRect newSelectedTimeRect = CGRectMake(selectedTimeView.frame.origin.x, -30, selectedTimeView.frame.size.width, selectedTimeView.frame.size.height);
    CGRect belowSelectedTimeRect = CGRectOffset(newSelectedTimeRect, 0, 15);
    
    // animate selectedTimeView to toolbar
    [UIView animateWithDuration:.1 animations:^{
        [selectedTimeView setAlpha:0];
    } completion:^(BOOL finished) {
        [selectedTimeView setFrame:belowSelectedTimeRect];
        [UIView animateWithDuration:.07 animations:^{
            [selectedTimeView setFrame:newSelectedTimeRect];
            [selectedTimeView setAlpha:1];
            if ([selectDuration handleSelected] != SelectDurationNoHandle) {
                [selectSongView setAlpha:.3];
                [selectActionView setAlpha:.3];
                [radialGradientView setAlpha:.6];
            }
        }];
    }];
    [selectedTimeView updateDate:[selectDuration getDate] part:selectDuration.handleSelected];
}

-(void) durationDidEndChanging:(SelectDurationView *)selectDuration {
     // save the time selected
     NSDate *dateSelected = [selectDuration getDate];
    
    NSTimeInterval time = round([dateSelected timeIntervalSinceReferenceDate] / 60.0) * 60.0;
    dateSelected = [NSDate dateWithTimeIntervalSinceReferenceDate:time];

    [alarmInfo setObject:dateSelected forKey:@"date"];
    
    // update selectedTime View
    [selectedTimeView updateDate:[selectDuration getDate] part:selectDuration.handleSelected];
    
    // animate selectedTimeView back to durationView
    [UIView animateWithDuration:.07 animations:^{
        CGRect belowSelectedTimeRect = CGRectOffset([selectedTimeView frame], 0, 15);
        
        [selectedTimeView setAlpha:0];
        [selectedTimeView setFrame:belowSelectedTimeRect];
        
        [selectSongView setAlpha:1];
        [selectActionView setAlpha:1];
        [radialGradientView setAlpha:1];
    } completion:^(BOOL finished) {
        [selectedTimeView setCenter:selectDurationView.center];
        [UIView animateWithDuration:.1 animations:^{
             [selectedTimeView setAlpha:1];
        }];
    }];
    if ([delegate respondsToSelector:@selector(alarmViewUpdated)])
        [delegate alarmViewUpdated];
}

-(void) durationViewTapped:(SelectDurationView *)selectDuration {
    // if selecting song/action, compress the song
    if (pickingSong)
        [selectSongView quickSelectCell];
    if (pickingAction)
        [selectActionView quickSelectCell];
    
    if (countdownEnded) {
        countdownEnded = NO;
        isSnoozing = YES;
        NSTimeInterval snoozeTime = [[[NSUserDefaults standardUserDefaults] objectForKey:@"snoozeTime"] intValue] * 60.0f;
        NSDate *snoozeDate = [[NSDate alloc] initWithTimeIntervalSinceNow:snoozeTime];
        [alarmInfo setObject:snoozeDate forKey:@"date"];
        [selectDuration setDate:snoozeDate];
        [selectedTimeView updateDate:snoozeDate part:SelectDurationNoHandle];
        [[delegate getMusicPlayer] stop];
    }
}

-(BOOL) durationViewSwiped:(UISwipeGestureRecognizerDirection)direction {
    if (pickingSong && direction == UISwipeGestureRecognizerDirectionLeft)
        [selectSongView quickSelectCell];
    else if (pickingAction && direction == UISwipeGestureRecognizerDirectionRight)
        [selectActionView quickSelectCell];
    else
        return NO;
    return YES;
}


-(void) durationViewDraggedWithYVel:(float)yVel {
    if (pickingSong || pickingAction)
        return;
    
    CGRect newDurRect = selectDurRect;
    CGRect proposedFrame = CGRectOffset(selectDurationView.frame, 0, yVel);
        
    if ((proposedFrame.origin.y >= selectDurRect.origin.y && isSet)
        || (proposedFrame.origin.y <= selectDurRect.origin.y && isTimerMode))
        newDurRect = selectDurRect;
    else if (proposedFrame.origin.y >= timerModeDurRect.origin.y)
        newDurRect = timerModeDurRect;
    else if (proposedFrame.origin.y <= alarmSetDurRect.origin.y)
        newDurRect = alarmSetDurRect;
    else
        newDurRect = proposedFrame;
    
    if (fabsf(yVel) > 15) {
        if (yVel < 0) {
            if (isTimerMode)
                shouldSet = AlarmViewShouldUnSet;
            else
                shouldSet = AlarmViewShouldSet;
        } else {
            if (isSet)
                shouldSet = AlarmViewShouldUnSet;
            else
                shouldSet = AlarmViewShouldTimer;
        }
        
    } else if ((shouldSet == AlarmViewShouldSet && yVel > 0) || (shouldSet == AlarmViewShouldUnSet && yVel < 0) || (shouldSet == AlarmViewShouldTimer && yVel < 0))
        shouldSet = AlarmViewShouldNone;
    
    [selectDurationView setFrame:newDurRect];
    [selectedTimeView setCenter:selectDurationView.center];
    
    if ([delegate respondsToSelector:@selector(durationViewWithIndex:draggedWithPercent:)]) {
        float percentDragged = (selectDurationView.frame.origin.y - selectDurRect.origin.y) / 150;
        [delegate durationViewWithIndex:index draggedWithPercent:-percentDragged];
        // fade in countdowntimer
        [countdownView setAlpha:-percentDragged];
        [selectedTimeView setAlpha:1-percentDragged];
        [selectSongView setAlpha:1-percentDragged];
        [selectActionView setAlpha:1-percentDragged];
        [timerView setAlpha:percentDragged];
    }
}

-(void) durationViewStoppedDraggingWithY:(float)y {
    // future: put this is own method
    
    if (pickingSong || pickingAction)
        return;
    
    bool set = NO;
    bool timer = NO;
    if (shouldSet == AlarmViewShouldSet
        || selectDurationView.frame.origin.y < (selectDurRect.origin.y + alarmSetDurRect.origin.y )/2)
        set = YES;
    else if (shouldSet == AlarmViewShouldUnSet) {
        set = NO;
//when the user turns off the alarm*************************************************
        if (countdownEnded || isSnoozing) { // stop and launch countdown aciton
            countdownEnded = NO;
            isSnoozing = NO;
            
            NSURL *openURL = [NSURL URLWithString:[[selectActionView.actions objectAtIndex:[[alarmInfo objectForKey:@"actionID"] intValue] ] objectForKey:@"url"]];
            
            [[delegate getMusicPlayer] stop];
            [[UIApplication sharedApplication] openURL:openURL];
            [selectedTimeView updateDate:[alarmInfo objectForKey:@"date"] part:SelectDurationNoHandle];
        }
    } else if (shouldSet == AlarmViewShouldTimer
             || selectDurationView.frame.origin.y > (selectDurRect.origin.y + timerModeDurRect.origin.y )/2) {
        set = NO;
        timer = YES;
    }
    
    // reset the timer if it is new
    if (!isTimerMode && timer) {
        [alarmInfo setObject:[NSDate date] forKey:@"timerDateBegan"];
        [selectDurationView performSelectorInBackground:@selector(setTimerMode:) 
                                             withObject:[NSNumber numberWithBool:YES]];
    } else if (!timer && isTimerMode) {
        // zero out the timer
        [alarmInfo setObject:[NSDate date] forKey:@"timerDateBegan"];
        [self updateProperties];
        [selectDurationView performSelectorInBackground:@selector(setTimerMode:) 
                                             withObject:[NSNumber numberWithBool:NO]];
    }

    isSet = set;
    isTimerMode = timer;
        
    // save the set bool
    [alarmInfo setObject:[NSNumber numberWithBool:isSet] forKey:@"isSet"];
    [alarmInfo setObject:[NSNumber numberWithBool:isTimerMode] forKey:@"isTimerMode"];
    
    shouldSet = AlarmViewShouldNone;
    [self animateSelectDurToRest];
    if ([delegate respondsToSelector:@selector(alarmViewUpdated)])
        [delegate alarmViewUpdated];
}

-(bool) shouldLockPicker {
    return (isSet || isTimerMode || ![self canMove]);
}

#pragma mark - Animation
- (void) animateSelectDurToRest {
    
    CGRect newFrame = [self currRestedSelecDurRect];
    
    if ([delegate respondsToSelector:@selector(durationViewWithIndex:draggedWithPercent:)])
        [delegate durationViewWithIndex:index draggedWithPercent:(isSet?1:isTimerMode?-1:0)];
    
    float alpha1 = (isSet?1:0);
    float alpha2 = (isTimerMode)?0:1;
    
    [UIView animateWithDuration:.2 animations:^{
        [selectDurationView setFrame:newFrame];
        [selectedTimeView setCenter:selectDurationView.center];
        // animate fade of countdowntimer & such
        [countdownView setAlpha:alpha1];
        [timerView setAlpha:1-alpha2];
        [selectedTimeView setAlpha:alpha2];
        [selectSongView setAlpha:alpha2];
        [selectActionView setAlpha:alpha2];
    }];  
}

#pragma mark - Utilities

CGRect CGRectExtendFromPoint(CGPoint p1, float dx, float dy) {
    return CGRectMake(p1.x-dx, p1.y-dy, dx*2, dy*2);
}

CGPoint CGRectCenter(CGRect rect) {
    return CGPointMake(rect.origin.x + rect.size.width/2, rect.origin.y + rect.size.height/2);
}

@end
