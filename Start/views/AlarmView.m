//
//  AlarmView.m
//  Start
//
//  Created by Nick Place on 6/15/12.
//  Copyright (c) 2012 TackMobile. All rights reserved.
//

#import "AlarmView.h"

@implementation AlarmView

@synthesize delegate, index, isSet, isTiming, isStopwatchMode, isTimerMode, newRect, isSnoozing;
@synthesize alarmInfo, countdownEnded;
@synthesize radialGradientView, /*backgroundImage,*/ patternOverlay, toolbarImage;
@synthesize selectSongView, selectActionView, selectDurationView, selectedTimeView, deleteLabel;
@synthesize countdownView, selectAlarmBg, stopwatchViewController;

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
        radialRect = CGRectMake((self.frame.size.width-bgImageSize.width)/2, 0, bgImageSize.width, frameRect.size.height);
        //radialRect = CGRectMake([UIScreen mainScreen].bounds.origin.x, [UIScreen mainScreen].bounds.origin.y, [UIScreen mainScreen].bounds.size.width , [UIScreen mainScreen].bounds.size.height);
        
        CGRect toolBarRect = CGRectMake(0, 0, self.frame.size.width, 135);
        selectSongRect = CGRectMake(Spacing-16, 0, frameRect.size.width-65, 80);
        selectActionRect = CGRectMake(Spacing+frameRect.size.width-50, 0, 50, 70);
        selectDurRect = CGRectMake(Spacing, [UIScreen mainScreen].applicationFrame.size.height/2 - frameRect.size.width/2, frameRect.size.width, frameRect.size.width);
        alarmSetDurRect = CGRectOffset(selectDurRect, 0, -120);
        stopwatchModeDurRect = CGRectOffset(selectDurRect, 0, 150);

        stopwatchRect = (CGRect){CGPointZero, self.frame.size};
        selectedTimeRect = CGRectExtendFromPoint(CGRectCenter(selectDurRect), 65, 65);
        CGRect durationMaskRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        countdownRect = CGRectMake(Spacing, alarmSetDurRect.origin.y+alarmSetDurRect.size.height, frameRect.size.width, self.frame.size.height - (alarmSetDurRect.origin.y+alarmSetDurRect.size.height) - 65); //alarm clock countdown label
        CGRect deleteLabelRect = CGRectMake(Spacing, 0, frameRect.size.width, 70);
        CGRect selectAlarmRect = CGRectMake(0, self.frame.size.height-50, self.frame.size.width, 50);
        
        // backgroundImage = [[UIImageView alloc] initWithFrame:bgImageRect];
        radialGradientView = [[RadialGradientView alloc] initWithFrame:radialRect]; //radial background
        
        
        
        //patternOverlay = [[UIImageView alloc] initWithFrame:radialGradientRect];
        toolbarImage = [[UIImageView alloc] initWithFrame:toolBarRect];
        selectSongView = [[SelectSongView alloc] initWithFrame:selectSongRect delegate:self presetSongs:[pListModel getPresetSongs]];
        selectActionView = [[SelectActionView alloc] initWithFrame:selectActionRect delegate:self actions:[pListModel getActions]];
        selectDurationView = [[SelectDurationView alloc] initWithFrame:selectDurRect delegate:self]; //dial
        durImageView = [[UIImageView alloc] init];
        selectedTimeView = [[SelectedTimeView alloc] initWithFrame:selectedTimeRect]; //clock in middle of dial
        countdownView = [[CountdownView alloc] initWithFrame:countdownRect];
        UIView *durationMaskView = [[UIView alloc] initWithFrame:durationMaskRect];
        stopwatchViewController = [[StopwatchViewController alloc] init];
        [stopwatchViewController.view setFrame:stopwatchRect];
        deleteLabel = [[UILabel alloc] initWithFrame:deleteLabelRect];
        selectAlarmBg = [[UIImageView alloc] initWithFrame:selectAlarmRect];
        
        [selectAlarmBg setImage:[UIImage imageNamed:@"bottom-fade"]];
        
        //[self addSubview:backgroundImage];
        [self addSubview:radialGradientView];
        //[self addSubview:patternOverlay];
        //[self addSubview:selectAlarmBg];
        [self addSubview:countdownView];
        [self addSubview:stopwatchViewController.view];
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
        [deleteLabel setTextAlignment:NSTextAlignmentCenter];
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
        [stopwatchViewController.view setAlpha:0];
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
        NSArray *infoKeys = [[NSArray alloc] initWithObjects:
                             @"date",
                             @"songID",
                             @"actionID",
                             @"isSet",
                             @"isTiming",
                             @"themeID",
                             @"isTimerMode",
                             @"timerDateBegan",
                             @"timerDuration",
                             @"isStopwatchMode",
                             @"StopwatchDateBegan",nil];
        
        NSArray *infoObjects = [[NSArray alloc] initWithObjects:
                                [NSDate dateWithTimeIntervalSinceNow:77777],
                                [NSNumber numberWithInt:0],
                                [NSNumber numberWithInt:0],
                                [NSNumber numberWithBool:NO],
                                [NSNumber numberWithBool:NO],
                                [NSNumber numberWithInt:-1],
                                [NSNumber numberWithBool:NO],
                                [NSDate date],
                                [NSNumber numberWithFloat:0],
                                [NSNumber numberWithBool:NO],
                                [NSDate date], nil];
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
            isStopwatchMode = NO;
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
        NSLog(@"showSnooze");
    }
}

#pragma mark - functionality
- (void) enterTimerMode {
    isTimerMode = YES;
    [self flashTimerMessage];
    [selectDurationView enterTimerMode];
    [selectedTimeView enterTimerMode];
    [selectDurationView setDuration:[(NSNumber *)[alarmInfo objectForKey:@"timerDuration"] floatValue]];
    
    [self durationDidEndChanging:selectDurationView];
}

- (void) exitTimerMode {
    isTimerMode = NO;
    [self flashAlarmMessage];
    [selectDurationView exitTimerMode];
    [selectedTimeView exitTimerMode];
    [selectDurationView setDate:[alarmInfo objectForKey:@"date"]];
    
    [self durationDidEndChanging:selectDurationView];
    
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
        } completion:^(BOOL finished) {
            [selectSongView removeFromSuperview];
            [selectActionView removeFromSuperview];
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
        if (!isStopwatchMode) {
            [self addSubview:selectSongView];
            [self addSubview:selectActionView];
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
- (void) flashTimerMessage {
    [selectSongView setAlpha:0];
    [selectSongView removeFromSuperview];
    [selectActionView setAlpha:0];
    [selectActionView removeFromSuperview];
    
    // flash timer message
    [self displayToastWithText:@"Timer Mode"];
    
}

- (void) flashAlarmMessage {
    if (!isTimerMode) {
        if (![[self subviews] containsObject:selectSongView])
            [self addSubview:selectSongView];
        if (![[self subviews] containsObject:selectActionView])
            [self addSubview:selectActionView];
    }
    
    // flash alarm message
    [self displayToastWithText:@"Alarm Mode"];
}

// parallax
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
    CGRect shiftedStopwatchRect = CGRectOffset(stopwatchRect, countDownOffset, 0);
    CGRect shiftedSongRect = CGRectOffset(selectSongRect, songPickOffset, 0);
    CGRect shiftedActionRect = CGRectOffset(selectActionRect, actionPickOffset, 0);
    CGRect shiftedRadialRect = CGRectOffset(radialRect, backgroundOffset, 0);
    
    [selectDurationView setFrame:shiftedDurRect];
    [selectedTimeView setCenter:selectDurationView.center];
    [countdownView setFrame:shiftedCountdownRect];
    [stopwatchViewController.view setFrame:shiftedStopwatchRect];
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
        
       
        if (isSet && floorf([[alarmInfo objectForKey:@"date"] timeIntervalSinceNow]) < .5)
            [self alarmCountdownEnded];
        
        if (isSnoozing) { //display and trigger an unsaved alarm
            [countdownView updateWithDate:[alarmInfo objectForKey:@"snoozeAlarm"]];
            if (floorf([[alarmInfo objectForKey:@"snoozeAlarm"] timeIntervalSinceNow] < .5))
                [self alarmCountdownEnded];
        } else if (isTimerMode) {
            NSDate *timerEndsDate;
            
            if (isTiming) {
               timerEndsDate = [(NSDate *)[alarmInfo objectForKey:@"timerDateBegan"] dateByAddingTimeInterval:[(NSNumber *)[alarmInfo objectForKey:@"timerDuration"] floatValue]];
            
            } else {
                timerEndsDate = [[NSDate date] dateByAddingTimeInterval:[(NSNumber *)[alarmInfo objectForKey:@"timerDuration"] floatValue]];

            }
            [countdownView updateWithDate:timerEndsDate];

        } else {
            [countdownView updateWithDate:[alarmInfo objectForKey:@"date"]]; //if it isn't snoozing then countdown will display from regular saved alarm
        }
        
        //if (selectDurationView.handleSelected == SelectDurationNoHandle)
        //   [selectDurationView setDate:[alarmInfo objectForKey:@"date"]];
        
        
    } else {
        [countdownView updateWithDate:[NSDate date]];
    }
    
    if (isStopwatchMode)
        [stopwatchViewController.timerView updateWithDate:[alarmInfo objectForKey:@"timerDateBegan"]];
}

- (CGRect) currRestedSelecDurRect {
    if (isSet || isTiming)
        return alarmSetDurRect;
    else if (isStopwatchMode)
        return stopwatchModeDurRect;
    else
        return selectDurRect;
}

- (void) displayToastWithText:(NSString *)text {
    // flash timer message
    UILabel *toast = [[UILabel alloc] initWithFrame:(CGRect){(CGPoint){0,10}, {self.frame.size.width, 50}}];
    [toast setTextAlignment:NSTextAlignmentCenter];
    [toast setText:text];
    [toast setAlpha:0];
    [self addSubview:toast];
    
    [UIView animateWithDuration:.2 animations:^{
        [toast setAlpha:.8];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 delay:.5 options:0 animations:^{
            [toast setAlpha:0];
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }];

}

#pragma mark - SelectSongViewDelegate
-(id) getDelegateMusicPlayer {
    return [delegate getMusicPlayer];
}
-(BOOL) expandSelectSongView {
    if (pickingAction /*|| isSnoozing */ || countdownEnded) //does not allow user to press and expand select sound view when the alarm is going off to prevent accidental touch when the user is trying to press snooze
    {
        return NO;}
    
    pickingSong = YES;
        
    CGSize screenSize = [[UIScreen mainScreen] applicationFrame].size;
    
    CGRect newSelectSongRect = CGRectMake(Spacing, selectSongRect.origin.y, screenSize.width, self.frame.size.height);
    CGRect selectDurPushedRect = CGRectOffset(selectDurationView.frame, selectSongView.frame.size.width, 0);
    CGRect selectActionPushedRect = CGRectOffset(selectActionView.frame, 90, 0);
    CGRect countdownPushedRect = CGRectOffset(countdownView.frame, selectSongView.frame.size.width, 0);
    CGRect timerPushedRect = CGRectOffset(stopwatchRect, selectSongView.frame.size.width, 0);

    
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
        
        [stopwatchViewController.view setFrame:timerPushedRect];
        [stopwatchViewController.view setAlpha:isStopwatchMode?.6:0];
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
        
        [stopwatchViewController.view setFrame:stopwatchRect];
        [stopwatchViewController.view setAlpha:isStopwatchMode?1:0];
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
    if (pickingAction /*|| isSnoozing*/ || countdownEnded) //does not allow you to press and expand select action view while the alarm is going off to prevent accidental touches if the user is trying to press snooze
        return NO;
    
    pickingAction = YES;
    
    CGRect newSelectActionRect = CGRectMake(75+Spacing, 0, [[UIScreen mainScreen] applicationFrame].size.width-75, self.frame.size.height);
    CGRect selectDurPushedRect = CGRectOffset(selectDurationView.frame, -newSelectActionRect.size.width, 0);
    CGRect selectSongPushedRect = CGRectOffset(selectSongView.frame, -selectSongView.frame.size.width + Spacing, 0);
    CGRect countdownPushedRect = CGRectOffset(countdownView.frame, -newSelectActionRect.size.width, 0);
    CGRect stopwatchPushedRect = CGRectOffset(stopwatchRect, -newSelectActionRect.size.width, 0);

    
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
        
        [stopwatchViewController.view setFrame:stopwatchPushedRect];
        [stopwatchViewController.view setAlpha:isStopwatchMode?.6:0];
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
        
        [stopwatchViewController.view setFrame:stopwatchRect];
        [stopwatchViewController.view setAlpha:isStopwatchMode?1:0];
    }];
}

#pragma mark - SelectDurationViewDelegate
-(void) durationDidChange:(SelectDurationView *)selectDuration {    
    // update selected time label
    if (!isTimerMode)
        [selectedTimeView updateDate:[selectDuration getDate] part:selectDuration.handleSelected];
    else
        [selectedTimeView updateDuration:[selectDuration getDuration] part:selectDuration.handleSelected];
}

-(void) durationDidBeginChanging:(SelectDurationView *)selectDuration {
    CGRect belowSelectedTimeRect;
    CGRect newSelectedTimeRect;
    if ([[UIScreen mainScreen] applicationFrame].size.height > 500) {
         newSelectedTimeRect = CGRectMake(selectedTimeView.frame.origin.x, 0, selectedTimeView.frame.size.width, selectedTimeView.frame.size.height);
         belowSelectedTimeRect = CGRectOffset(newSelectedTimeRect, 0, 15);
    }else{
         newSelectedTimeRect = CGRectMake(selectedTimeView.frame.origin.x, -30, selectedTimeView.frame.size.width, selectedTimeView.frame.size.height);
         belowSelectedTimeRect = CGRectOffset(newSelectedTimeRect, 0, 15);

    }
        
    // animate selectedTimeView to toolbar
    [UIView animateWithDuration:.1 animations:^{
        [selectedTimeView setAlpha:0];
    } completion:^(BOOL finished) {
        [selectedTimeView setFrame:belowSelectedTimeRect];
        [UIView animateWithDuration:.07 animations:^{
            [selectedTimeView setFrame:newSelectedTimeRect];
            [selectedTimeView setAlpha:1];
            if ([selectDuration handleSelected] != SelectDurationNoHandle) {
                [selectSongView setAlpha:.2];
                [selectActionView setAlpha:.2];
                [radialGradientView setAlpha:.6];
            }
        }];
    }];
    
    if (isTimerMode)
        [selectedTimeView updateDuration:[selectDuration getDuration] part:selectDuration.handleSelected];
    else
        [selectedTimeView updateDate:[selectDuration getDate] part:selectDuration.handleSelected];
}

-(void) durationDidEndChanging:(SelectDurationView *)selectDuration {
    if (isTimerMode) {
        NSTimeInterval intervalSelected = [selectDuration getDuration];
        [alarmInfo setObject:[NSNumber numberWithFloat:intervalSelected] forKey:@"timerDuration"];
        
        // update selectedTime View
        [selectedTimeView updateDuration:intervalSelected part:selectDuration.handleSelected];
    } else {
        // save the time selected
        NSDate *dateSelected = [selectDuration getDate];

        NSTimeInterval time = round([dateSelected timeIntervalSinceReferenceDate] / 60.0) * 60.0;
        dateSelected = [NSDate dateWithTimeIntervalSinceReferenceDate:time];

        [alarmInfo setObject:dateSelected forKey:@"date"];
   
    
        // update selectedTime View
        [selectedTimeView updateDate:[selectDuration getDate] part:selectDuration.handleSelected];
    }
    
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
    if (!isTimerMode)
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
        NSLog(@"snoozeTapped");
        countdownEnded = NO;
        isSnoozing = YES;
        NSTimeInterval snoozeTime = [[[NSUserDefaults standardUserDefaults] objectForKey:@"snoozeTime"] intValue] * 60.0f;
        //NSTimeInterval testSnoozeTime = 1 * 60.0f;
        NSDate *snoozeDate = [[NSDate alloc] initWithTimeIntervalSinceNow:snoozeTime];
        [alarmInfo setObject:snoozeDate forKey:@"snoozeAlarm"];
        [selectDuration setDate:snoozeDate];
        [selectedTimeView updateDate:snoozeDate part:SelectDurationNoHandle];
        [[delegate getMusicPlayer] stop];
    }
}

-(void) durationViewCoreTapped:(SelectDurationView *)selectDuration {
    if (!pickingAction && !pickingSong && !isSet && !isTimerMode) {
        // go into timer mode
        [self enterTimerMode];
    } else if (isTimerMode && !isTiming) {
        [self exitTimerMode];
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
    
    // make the picker stop in the middle if it was in timer mode OR if it was set.
    if ((proposedFrame.origin.y >= selectDurRect.origin.y && isSet)
        || (proposedFrame.origin.y <= selectDurRect.origin.y && isStopwatchMode))
        newDurRect = selectDurRect;
    // cant go any lower than the stopwatch mode rect
    else if (proposedFrame.origin.y >= stopwatchModeDurRect.origin.y)
        newDurRect = stopwatchModeDurRect;
    // cent go any higher than the alarmSet rect
    else if (proposedFrame.origin.y <= alarmSetDurRect.origin.y)
        newDurRect = alarmSetDurRect;
    // cant go low if timer mode
    else if (isTimerMode && proposedFrame.origin.y >= selectDurRect.origin.y)
        newDurRect = selectDurRect;
    else
        newDurRect = proposedFrame;
    
    // checking for a swipe
    if (fabsf(yVel) > 15) {
        if (yVel < 0) {
            if (isStopwatchMode){
                shouldSet = AlarmViewShouldUnSet;
            }
            else{
                
                shouldSet = AlarmViewShouldSet;
            }
        } else {
            if (isSet){
                shouldSet = AlarmViewShouldUnSet;
            }
            else if (!isTimerMode) {
                shouldSet = AlarmViewShouldStopwatch;
            }
        }
        
    } else if ((shouldSet == AlarmViewShouldSet && yVel > 0) || (shouldSet == AlarmViewShouldUnSet && yVel < 0) || (shouldSet == AlarmViewShouldStopwatch && yVel < 0))
        shouldSet = AlarmViewShouldNone;
    
    // compress the durationSelector if duration selector is below original position
    if (newDurRect.origin.y > selectDurRect.origin.y) {
        float currDist = stopwatchModeDurRect.origin.y - newDurRect.origin.y;
        float fullDist = stopwatchModeDurRect.origin.y - selectDurRect.origin.y;
        [selectDurationView compressByRatio:currDist/fullDist];
    }
    
    [selectDurationView setFrame:newDurRect];
    // keep the inner text centered with time picker
    [selectedTimeView setCenter:selectDurationView.center];
    
    if (!isTimerMode) {
        if (![[self subviews] containsObject:selectSongView])
            [self addSubview:selectSongView];
        if (![[self subviews] containsObject:selectActionView])
            [self addSubview:selectActionView];
    }
    
    if ([delegate respondsToSelector:@selector(durationViewWithIndex:draggedWithPercent:)]) {
        float percentDragged = (selectDurationView.frame.origin.y - selectDurRect.origin.y) / 150;
        [delegate durationViewWithIndex:index draggedWithPercent:-percentDragged];
        // fade in stopwatch, fade out alarm functions
        [countdownView setAlpha:-percentDragged];
        [selectedTimeView setAlpha:1-percentDragged];
        [selectSongView setAlpha:1-percentDragged];
        [selectActionView setAlpha:1-percentDragged];
        [selectSongView.showCell.artistLabel setAlpha:1.3+percentDragged];
        
        [stopwatchViewController.view setAlpha:percentDragged];
    }
}

-(void) durationViewStoppedDraggingWithY:(float)y { // this is when the dial is finished moving up or down.
    // future: put this is own method
   // [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

    if (pickingSong || pickingAction)
        return;
    
    bool setAlarm = NO;
    bool startStopwatchMode = NO;
    if (shouldSet == AlarmViewShouldSet
        || selectDurationView.frame.origin.y < (selectDurRect.origin.y + alarmSetDurRect.origin.y )/2) {
        setAlarm = YES;
        [selectSongView.showCell.artistLabel setAlpha:0.3];
    }
    else if (shouldSet == AlarmViewShouldUnSet) {
        setAlarm = NO;
        [selectSongView.cell.artistLabel setAlpha:1];
        // when the user turns off the alarm when the alarm is sounding
        if (countdownEnded || isSnoozing) { // stop and launch countdown aciton
            countdownEnded = NO;
            isSnoozing = NO;
            NSURL *openURL = [NSURL URLWithString:[[selectActionView.actions objectAtIndex:[[alarmInfo objectForKey:@"actionID"] intValue] ] objectForKey:@"url"]]; //gets URL of selected action from alarmInfo dictionary.
            [selectDurationView setDate:[alarmInfo objectForKey:@"date"]];
            [[delegate getMusicPlayer] stop];
            [[UIApplication sharedApplication] openURL:openURL]; //opens the url
            [selectedTimeView updateDate:[alarmInfo objectForKey:@"date"] part:SelectDurationNoHandle];
        }
    } else if (shouldSet == AlarmViewShouldStopwatch
             || selectDurationView.frame.origin.y > (selectDurRect.origin.y + stopwatchModeDurRect.origin.y )/2) {
        setAlarm = NO;
        startStopwatchMode = YES;
    }
    
    // reset the timer if it is new
    if (!isStopwatchMode && startStopwatchMode) {
        [alarmInfo setObject:[NSDate date] forKey:@"timerDateBegan"];
        
        // compress/expand time picker
        [selectDurationView animateCompressByRatio:startStopwatchMode?0:1];
    } else if (!startStopwatchMode && isStopwatchMode) {
        // zero out the timer
        [alarmInfo setObject:[NSDate date] forKey:@"timerDateBegan"];
        [self updateProperties];
        
        // compress/expand time picker
        [selectDurationView animateCompressByRatio:startStopwatchMode?0:1];
    }
    if (isTimerMode)
        isTiming = setAlarm;
    else
        isSet = setAlarm;
    
    isStopwatchMode = startStopwatchMode;
    
    if (isTiming) {
        [alarmInfo setObject:[NSDate date] forKey:@"timerDateBegan"];
    }
    
    // save the set bool
    [alarmInfo setObject:[NSNumber numberWithBool:isSet] forKey:@"isSet"];
    [alarmInfo setObject:[NSNumber numberWithBool:isTiming] forKey:@"isTiming"];
    [alarmInfo setObject:[NSNumber numberWithBool:isStopwatchMode] forKey:@"isTimerMode"];
    
    shouldSet = AlarmViewShouldNone;
    [self animateSelectDurToRest];
    if ([delegate respondsToSelector:@selector(alarmViewUpdated)])
        [delegate alarmViewUpdated];
}

-(bool) shouldLockPicker {
    return (isSet || isTiming || isStopwatchMode || ![self canMove]);
}

#pragma mark - Animation
- (void) animateSelectDurToRest {
    
    CGRect newFrame = [self currRestedSelecDurRect];
    
    if ([delegate respondsToSelector:@selector(durationViewWithIndex:draggedWithPercent:)])
        [delegate durationViewWithIndex:index draggedWithPercent:((isSet||isTiming)?1:isStopwatchMode?-1:0)];
    
    float alpha1;
    if (isTimerMode)
        alpha1 = (isTiming?1:0);
    else
        alpha1 = (isSet?1:0);
    
    float alpha2 = (isStopwatchMode)?0:1;
    
    if (alpha2 == 1 && !isTimerMode) {
        if (![[self subviews] containsObject:selectSongView])
            [self addSubview:selectSongView];
        if (![[self subviews] containsObject:selectActionView])
            [self addSubview:selectActionView];
    }
    
    [UIView animateWithDuration:.2 animations:^{
        NSLog(@"animating");
        [selectDurationView setFrame:newFrame];
        [selectedTimeView setCenter:selectDurationView.center];
        // animate fade of countdowntimer & such
        [countdownView setAlpha:alpha1];
        [stopwatchViewController.view setAlpha:1-alpha2];
        [selectedTimeView setAlpha:alpha2];
        [selectSongView setAlpha:alpha2];
        [selectActionView setAlpha:alpha2];
    } completion:^(BOOL finished) {
        if (alpha2 == 0) {
            [selectActionView removeFromSuperview];
            [selectSongView removeFromSuperview];
        }
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
