//
//  ViewController.m
//  Start
//
//  Created by Nick Place on 6/15/12.
//  Copyright (c) 2012 TackMobile. All rights reserved.
//

#import "MasterViewController.h"
#import "MusicPlayer.h"
#import "LocalizedStrings.h"
#import "Constants.h"

typedef NS_ENUM (NSInteger, SwitchAlarmDirection) {
  SwitchAlarmNext = -1,
  SwitchAlarmNone,
  SwitchAlarmPrev
};

@interface MasterViewController ()

@property (nonatomic, strong) NSArray *userAlarms;
@property (nonatomic) float asideOffset;
@property (nonatomic) SwitchAlarmDirection shouldSwitch;
@property (nonatomic) CGRect prevAlarmRect;
@property (nonatomic) CGRect currAlarmRect;
@property (nonatomic) NSInteger currAlarmIndex;
@property (nonatomic, strong) SettingsView *settingsView;
@property (nonatomic, strong) MusicPlayer *musicPlayer;
@property (nonatomic, strong) SelectAlarmView *selectAlarmView;
@property (nonatomic, strong) PListModel *pListModel;
@property (nonatomic, strong) NSTimer *tickTimer;
@property (nonatomic, strong) UIButton *addButton;

@end

@implementation MasterViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.alarms = [[NSMutableArray alloc] init];
  
  // Get the saved alarm index
  self.currAlarmIndex = 1;
  int savedCurrIndex = 1;
  if ([[NSUserDefaults standardUserDefaults] objectForKey:StartUserDefaultKey.currentAlarmIndex]) {
    savedCurrIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:StartUserDefaultKey.currentAlarmIndex] intValue];
  }
  _shouldSwitch = SwitchAlarmNone;
  self.pListModel = [[PListModel alloc] init];
  
  // Views
  CGSize plusSize = CGSizeMake(38, 38);
  
  CGRect frameRect = [[UIScreen mainScreen] applicationFrame];
  CGRect selectAlarmRect = CGRectMake(0, frameRect.size.height-50, frameRect.size.width, 50);
  CGRect plusRect = CGRectMake(5, frameRect.size.height - plusSize.height - 5, plusSize.width, plusSize.height);
  
  _currAlarmRect = CGRectMake(-Spacing, 0, frameRect.size.width+(Spacing*2), frameRect.size.height);
  _prevAlarmRect = CGRectOffset(_currAlarmRect, -frameRect.size.width-Spacing, 0);
  _asideOffset = frameRect.size.width+Spacing;
  
  // Get the user alarms first so that we know wether to hide the plus button or not
  _userAlarms = [self.pListModel getAlarms];
  
  self.selectAlarmView = [[SelectAlarmView alloc] initWithFrame:selectAlarmRect delegate:self];
  self.musicPlayer = [[MusicPlayer alloc] init];
  [self.musicPlayer addTargetForSampling:self selector:@selector(songPlayingTick:)];
  self.addButton = [[UIButton alloc] initWithFrame:plusRect];
  
  self.settingsView = [[SettingsView alloc] initWithDelegate:self frame:CGRectOffset(frameRect, 0, -frameRect.origin.y)];
  
  [self.view addSubview:self.settingsView];
  [self.view addSubview:self.selectAlarmView];
  [self.view addSubview:self.addButton];
  
  [self.addButton setBackgroundImage:[UIImage imageNamed:@"plusButton"] forState:UIControlStateNormal];
  
  // Init the alams that were stored
  if ([_userAlarms count]>0) {
    for (NSDictionary *alarmInfo in _userAlarms) {
      [self.selectAlarmView addAlarmAnimated:NO];
      [self addAlarmWithInfo:alarmInfo switchTo:NO];
    }
  }
  
  [self switchAlarmWithIndex:savedCurrIndex];
  [self.addButton addTarget:self.selectAlarmView action:@selector(plusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
  [self beginTick];
}

- (void)plusButtonTappedForFirstVisit {
  // If it's the first visit, when the user presses the plus button, switchAlarmWithIndex is called and the first alarm appears on screen
  [self switchAlarmWithIndex:self.currAlarmIndex - 1];
  
  // Add this selector for the plus button so when user presses it adds new alarms
  [self.addButton addTarget:self.selectAlarmView action:@selector(plusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)beginTick {
  self.tickTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateAlarmViews:) userInfo:nil repeats:YES];
  [[NSRunLoop mainRunLoop] addTimer:self.tickTimer forMode:NSDefaultRunLoopMode];
}
- (void)pauseTick {
  [self.tickTimer invalidate];
}

- (void)saveAlarms {
  // Save alarms
  NSMutableArray *alarmsData = [[NSMutableArray alloc] init];
  for (AlarmView *alarm in self.alarms)
  [alarmsData addObject:[NSDictionary dictionaryWithDictionary:alarm.alarmInfo]];
  [self.pListModel saveAlarms:alarmsData];
  [[NSUserDefaults standardUserDefaults] setObject:@(self.currAlarmIndex) forKey:StartUserDefaultKey.currentAlarmIndex];
}

- (void)updateAlarmViews:(NSTimer *)timer {
  for (AlarmView *alarmView in self.alarms) {
    [alarmView updateProperties];
  }
}

- (void)scheduleLocalNotificationsForActiveState:(bool)isActive {
  for (AlarmView *alarmView in self.alarms) {
    NSDictionary *alarmInfo = [alarmView alarmInfo];
    if ([(NSNumber *)[alarmInfo objectForKey:@"isSet"] boolValue]) {
      
      NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@(alarmView.alarmIndex), @"alarmIndex", nil];
      
      // If the app was kept in the foreground and a song was selected, then we should let the song play instead of a notification
      if (isActive && ([[alarmInfo objectForKey:@"songID"] intValue] > 6 || [[alarmInfo objectForKey:@"songID"] intValue] < 0)) {
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        notif.fireDate = [alarmView getDate];
        notif.userInfo = userInfo;
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
        
      } else {
        
        // Otherwise, schedule a bunch of them 20 seconds apart
        
        int notifCount = 15;
        NSDate *fireDate = [alarmView getDate];
        
        while (notifCount > 0) {
          UILocalNotification *notif = [[UILocalNotification alloc] init];
          notif.userInfo = userInfo;
          notif.fireDate = fireDate;
          
          // If the user selects one of the default tones for their alarm...the local notification will play that tone as its sound
          switch ([[alarmInfo objectForKey:@"songID"] intValue]) {
            case 0:
            notif.soundName = @"chamaeleon2.wav";
            break;
            case 1:
            notif.soundName = @"epsilon2.wav";
            break;
            case 2:
            notif.soundName = @"hydrus2.wav";
            break;
            case 3:
            notif.soundName = @"galaxy.wav";
            break;
            case 4:
            notif.soundName = @"phoenix2.wav";
            break;
            case 5:
            notif.soundName = @"lynx2.wav";
            break;
            case 6:
            notif.soundName = @"galaxy.wav";
            break;
            default:
            // If it's an iPod song, galaxy will be default tone for local notification
            notif.soundName = @"galaxy.wav";
            break;
          }
          
          if (alarmView.isTimerMode) {
            notif.alertBody = [LocalizedStrings timerFinished];
          } else {
            notif.alertBody = [LocalizedStrings alarmTriggered];
          }
          
          [[UIApplication sharedApplication] scheduleLocalNotification:notif];
          
          // Decide the duration of the notif
          NSString *resName = [[notif.soundName componentsSeparatedByString:@"."] objectAtIndex:0];
          NSError *setURLError;
          NSString *playerPath = [[NSBundle mainBundle] pathForResource:resName ofType:@"wav"];
          AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:playerPath] error:&setURLError];
          
          // Advance the date and decriment the count
          fireDate = [fireDate dateByAddingTimeInterval:audioPlayer.duration];
          notifCount--;
        }
      }
    }
  }
}

- (void)respondedToLocalNot {
  [[UIApplication sharedApplication] cancelAllLocalNotifications]; //removes all the notifications from the notificaiton center
  AlarmView *alarmView;
  int indexOfTrippedAlarm = -1;
  self.userAlarms = [self.pListModel getAlarms];
  if (self.userAlarms.count>0) { //tries to find out which of the saved alarms just went off
    for (NSDictionary *alarmInfo in self.userAlarms) {
      indexOfTrippedAlarm++;
      if (floorf([[alarmView getDate] timeIntervalSinceNow] < 0) || floorf([[alarmInfo objectForKey:@"snoozeAlarm"] timeIntervalSinceNow] < 0)) {
        alarmView = [self.alarms objectAtIndex:indexOfTrippedAlarm]; //saves that instance as alarmView
      }
    }
  }
}

- (void)addAlarmWithInfo:(NSDictionary *)alarmInfo switchTo:(BOOL)switchToAlarm {
  self.currAlarmIndex = self.alarms.count;
  AlarmView *newAlarm = [[AlarmView alloc] initWithFrame:self.prevAlarmRect index:self.currAlarmIndex delegate:self alarmInfo:alarmInfo];
  [self.alarms addObject:newAlarm];
  [self.view insertSubview:newAlarm atIndex:1];
  if (switchToAlarm) {
    [self switchAlarmWithIndex:self.currAlarmIndex];
  }
  [newAlarm viewWillAppear];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Used when deleting an alarm
- (void)updateAlarmIndexes {
  for (NSInteger i=self.alarms.count-1; i>=0; i--)
  [[self.alarms objectAtIndex:i] setAlarmIndex:i];
}

#pragma mark - Touches

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  if (self.currAlarmIndex < self.alarms.count) {
    return;
  }
  
  UITouch *touch = [touches anyObject];
  CGPoint loc = [touch locationInView:self.view];
  CGPoint prevLoc = [touch previousLocationInView:self.view];
  CGSize velocity = CGSizeMake(loc.x-prevLoc.x, loc.y-prevLoc.y);
  if (velocity.width < -10) {
    [self switchAlarmWithIndex:self.alarms.count-1];
  }
}

#pragma mark - SettingsViewDelegate

- (void)hidePlus {
  if (self.userAlarms.count == 0) {
    [UIView animateWithDuration:.2 animations:^{
      self.addButton.alpha = 0;
    }];
  }
}

- (void)showPlus {
  [UIView animateWithDuration:.2 animations:^{
    self.addButton.alpha=1;
  }];
}

#pragma mark - Positioning & SelectAlarmViewDelegate

- (void)switchAlarmWithIndex:(NSInteger)index {
  self.shouldSwitch = SwitchAlarmNone;
  
  if (index < 0 || index > [self.alarms count]) {
    index = self.currAlarmIndex;
  }
  
  float currOffset;
  if (self.currAlarmIndex < self.alarms.count) {
    AlarmView *currAlarm = self.alarms[self.currAlarmIndex];
    currOffset = currAlarm.frame.origin.x + Spacing;
  } else {
    currOffset = 0;
  }
  
  float screenWidth = [[UIScreen mainScreen] applicationFrame].size.width;
  
  float animOffset = (index-self.currAlarmIndex)*(self.asideOffset) - currOffset;
  
  for (AlarmView *alarmView in self.alarms) {
    CGRect newAlarmRect = CGRectOffset(self.currAlarmRect, ((self.currAlarmIndex - alarmView.alarmIndex)*(self.asideOffset) + currOffset) , 0);
    CGRect animateToRect = CGRectOffset(newAlarmRect, animOffset, 0);
    
    [alarmView setFrame:newAlarmRect];
    [alarmView setNewRect:animateToRect];
    
    [alarmView shiftedFromActiveByPercent:(newAlarmRect.origin.x+Spacing)/screenWidth];
  }
  
  self.currAlarmIndex = index;
  [[NSUserDefaults standardUserDefaults] setObject:@(self.currAlarmIndex) forKey:StartUserDefaultKey.currentAlarmIndex];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if (index < self.alarms.count) {
    [self.selectAlarmView makeAlarmActiveAtIndex:self.currAlarmIndex];
  }
  [self animateAlarmsToNewRect];
  [self saveAlarms];
}

- (void)animateAlarmsToNewRect {
  float screenWidth = [[UIScreen mainScreen] applicationFrame].size.width;
  
  CGRect footerRect;
  if (self.currAlarmIndex == self.alarms.count) {
    footerRect = CGRectMake([(AlarmView *)self.alarms[self.alarms.count-1] newRect].origin.x, self.selectAlarmView.frame.origin.y, self.selectAlarmView.frame.size.width, self.selectAlarmView.frame.size.height);
    
  } else {
    footerRect = CGRectMake(0, self.selectAlarmView.frame.origin.y, self.selectAlarmView.frame.size.width,self.selectAlarmView.frame.size.height);
    
  }
  [UIView animateWithDuration:.15 animations:^{
    self.selectAlarmView.frame = footerRect;
    for (AlarmView *alarmView in self.alarms) {
      alarmView.frame = alarmView.newRect;
      [alarmView shiftedFromActiveByPercent:(alarmView.newRect.origin.x+Spacing)/screenWidth];
    }
  }];
}

#pragma mark - AlarmViewDelegate

- (PListModel *)getPListModel {
  return self.pListModel;
}

- (MusicPlayer *)getMusicPlayer {
  return self.musicPlayer;
}

- (void)alarmView:(AlarmView *)alarmView draggedWithXVel:(float)xVel {
  if (![alarmView canMove]) {
    return;
  }
  
  NSInteger alarmIndex = alarmView.alarmIndex;
  
  if (fabsf(xVel) > 15) {
    self.shouldSwitch = xVel < 0 ? SwitchAlarmNext : SwitchAlarmPrev;
    
  } else if ((xVel < 0 && self.shouldSwitch == SwitchAlarmPrev) || (xVel > 0 && self.shouldSwitch == SwitchAlarmNext)) {
    self.shouldSwitch = SwitchAlarmNone;
  }
  
  CGRect alarmRect = CGRectOffset(alarmView.frame, xVel, 0);
  
  // Reduce vel if on edges
  if ((alarmRect.origin.x > 0 && self.currAlarmIndex==-1) || (alarmRect.origin.x < 0 && self.currAlarmIndex == 0)) {
    alarmRect = CGRectOffset(alarmRect, -xVel, 0);
  }
  
  CGRect leftAlarmRect = CGRectOffset(alarmRect, -self.asideOffset, 0);
  CGRect rightAlarmRect = CGRectOffset(alarmRect, self.asideOffset, 0);
  
  float screenWidth = [[UIScreen mainScreen] applicationFrame].size.width;
  
  if (alarmIndex > 0) {
    [self.alarms[alarmIndex-1] setFrame:rightAlarmRect];
    [self.alarms[alarmIndex-1] shiftedFromActiveByPercent:(rightAlarmRect.origin.x+Spacing)/screenWidth];
  }
  if (alarmIndex < self.alarms.count-1) {
    [self.alarms[alarmIndex+1] setFrame:leftAlarmRect];
    [self.alarms[alarmIndex+1] shiftedFromActiveByPercent:(leftAlarmRect.origin.x+Spacing)/screenWidth];
  }
  
  // make selectalarmview float off with alarm
  float xOrigin = 0;
  if (alarmView.alarmIndex == self.alarms.count-1 && alarmRect.origin.x > 0) {
    xOrigin = alarmRect.origin.x;
  }
  
  CGRect footerRect = CGRectMake(xOrigin, self.selectAlarmView.frame.origin.y, self.selectAlarmView.frame.size.width, self.selectAlarmView.frame.size.height);
  self.selectAlarmView.frame = footerRect;
  
  alarmView.frame = alarmRect;
  [alarmView shiftedFromActiveByPercent:(alarmRect.origin.x+Spacing)/screenWidth];
}

- (void)alarmView:(AlarmView *)alarmView stoppedDraggingWithX:(float)x {
  
  NSInteger alarmIndex = alarmView.alarmIndex;
  
  if (fabsf(x) > self.currAlarmRect.size.width / 2) {
    [self switchAlarmWithIndex:alarmIndex + (x < 0 ? -1 : 1)];
  } else if (self.shouldSwitch != SwitchAlarmNone) {
    [self switchAlarmWithIndex:alarmIndex + self.shouldSwitch];
    
  } else {
    [self switchAlarmWithIndex:self.currAlarmIndex];
  }
}

- (void)durationViewWithIndex:(NSInteger)index draggedWithPercent:(float)percent {
  [self.selectAlarmView makeAlarmSetAtIndex:index percent:percent];
}

- (void)alarmViewOpeningMenuWithPercent:(float)percent {
  self.selectAlarmView.alpha = 1-percent;
  self.addButton.alpha = 1-percent;
}

- (void)alarmViewClosingMenuWithPercent:(float)percent {
  self.selectAlarmView.alpha = percent;
  self.addButton.alpha = percent;
}

- (bool)alarmViewPinched:(AlarmView *)alarmView {
  if (self.alarms.count < 2) {
    return false;
  }
  
  [self.alarms removeObject:alarmView];
  [alarmView setIsSet:NO];
  [self.selectAlarmView deleteAlarm:alarmView.alarmIndex];
  [self updateAlarmIndexes];
  
  [UIView animateWithDuration:.15 animations:^{
    [alarmView setAlpha:0];
  } completion:^(BOOL finished) {
    [alarmView removeFromSuperview];
  }];
  [self saveAlarms];
  return true;
}

- (void)alarmViewUpdated {
  [self saveAlarms];
}

- (void)alarmCountdownEnded:(AlarmView *)alarmView {
  [self switchAlarmWithIndex:alarmView.alarmIndex];
  if ([[alarmView.alarmInfo objectForKey:@"songID"] intValue] > 6 || [[alarmView.alarmInfo objectForKey:@"songID"] intValue] < 0 ) {
    [self.musicPlayer playSongWithID:[alarmView.alarmInfo objectForKey:@"songID"] vibrate:YES];
  }
}

- (void)songPlayingTick:(NSTimer *)timer {
  for (AlarmView *alarm in self.alarms)
  [alarm.selectSongView songPlayingTick:self.musicPlayer];
}

#pragma mark - SelectAlarmViewDelegate

- (void)alarmAdded {
  [self.selectAlarmView addAlarmAnimated:YES];
  [self addAlarmWithInfo:nil switchTo:YES];
}

@end
