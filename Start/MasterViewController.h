//
//  ViewController.h
//  Start
//
//  Created by Nick Place on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlarmView.h"
#import "SelectAlarmView.h"
#import "PListModel.h"

enum SwitchAlarmDirection {
    SwitchAlarmNext = -1,
    SwitchAlarmNone,
    SwitchAlarmPrev
};

@interface MasterViewController : UIViewController <SelectAlarmViewDelegate, AlarmViewDelegate> {
    NSMutableArray *alarms;
    
    CGRect prevAlarmRect;
    CGRect currAlarmRect;
    CGRect nextAlarmRect;
    
    int currAlarmIndex;
    
    int shouldSwitch;
}

@property (nonatomic, strong) SelectAlarmView *selectAlarmView;
@property (nonatomic, strong) PListModel *pListModel;

- (void) saveAlarms;

- (void) alarmAdded;
- (void) alarmView:(AlarmView *)alarmView draggedWithXVel:(float)xVel;
- (void) alarmView:(AlarmView *)alarmView stoppedDraggingWithX:(float)x;



@end
