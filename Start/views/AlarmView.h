//
//  AlarmView.h
//  Start
//
//  Created by Nick Place on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "SelectSongView.h"
#import "SelectActionView.h"
#import "SelectDurationView.h"
#import "CountdownTimer.h"
#import "SelectedTimeView.h"
#import "PListModel.h"
#import "CountdownView.h"
#import "MusicManager.h"

//testing
#import "MusicPlayer.h"

@class AlarmView;

@protocol AlarmViewDelegate <NSObject>

-(PListModel *)getPListModel;
-(void) alarmView:(AlarmView *)alarmView draggedWithXVel:(float)xVel;
-(void) alarmView:(AlarmView *)alarmView stoppedDraggingWithX:(float)x;
-(void) alarmViewOpeningMenuWithPercent:(float)percent;
-(void) alarmViewClosingMenuWithPercent:(float)percent;

-(void) durationViewWithIndex:(int)index draggedWithPercent:(float)percent;

-(bool)alarmViewPinched:(AlarmView *)alarmView;
@end

enum AlarmViewShouldSet {
    AlarmViewShouldSet = 0,
    AlarmViewShouldUnSet,
    AlarmViewShouldTimer,
    AlarmViewShouldNone
};

@interface AlarmView : UIView <CountdownTimerDelegate, SelectDurationViewDelegate, SelectSongViewDelegate, SelectActionViewDelegate> {    
    CGRect selectedTimeRect;
    CGRect selectDurRect;
    CGRect selectSongRect;
    CGRect selectActionRect;
    CGRect alarmSetDurRect;
    CGRect timerModeDurRect;
    CGRect countdownRect;
    CGRect bgImageRect;
    
    MusicManager *musicManager;
    
    int shouldSet;
    
    bool pickingSong;
    bool pickingAction;
    bool cancelTouch;
        
    UIImageView *durImageView;
}
@property (nonatomic, strong) id<AlarmViewDelegate> delegate;
@property CGRect newRect;
@property bool isSet;
@property bool isTimerMode;
@property int index;

@property (nonatomic, strong) NSMutableDictionary *alarmInfo;

@property (nonatomic, strong) UIImageView *backgroundImage;
@property (nonatomic, strong) UIImageView *toolbarImage;

@property (nonatomic, strong) SelectSongView *selectSongView;
@property (nonatomic, strong) SelectActionView *selectActionView;
@property (nonatomic, strong) SelectDurationView *selectDurationView;
@property (nonatomic, strong) SelectedTimeView *selectedTimeView;
@property (nonatomic, strong) CountdownView *countdownView;
@property (nonatomic, strong) UIView *selectAlarmBg;
@property (nonatomic, strong) UILabel *deleteLabel;

@property (nonatomic, strong) CountdownTimer *countdownTimer;

- (void) shiftedFromActiveByPercent:(float)percent;
- (void) updateProperties;

- (void) viewWillAppear;
- (bool) canMove;
- (id) initWithFrame:(CGRect)frame index:(int)aIndex delegate:(id<AlarmViewDelegate>)aDelegate alarmInfo:(NSDictionary *)theAlarmInfo;

@end
