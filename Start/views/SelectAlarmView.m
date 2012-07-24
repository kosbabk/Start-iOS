//
//  SelectAlarmView.m
//  Start
//
//  Created by Nick Place on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SelectAlarmView.h"

int MAX_ALARMS = 6;
int ALARM_SPACING = 5;

@implementation SelectAlarmView
@synthesize delegate;
@synthesize alarmContainer, plusButton;

const float setAlarmY = 15;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {       
        alarmButtons = [[NSMutableArray alloc] init];
        
        
        // views
        CGRect plusRect = CGRectMake(7, 7, 38, 38);
        CGRect alarmContainerRect = CGRectMake(plusRect.origin.x + plusRect.size.width + ALARM_SPACING, plusRect.origin.y, self.frame.size.width - plusRect.origin.x - plusRect.size.width - ALARM_SPACING, plusRect.size.height);
                
        plusButton = [[UIButton alloc] initWithFrame:plusRect];
        alarmContainer = [[UIView alloc] initWithFrame:alarmContainerRect];
        
        [plusButton addTarget:self action:@selector(plusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:plusButton];
        [self addSubview:alarmContainer];
        
        // init
        restedY = alarmContainer.frame.size.height/2 - 1;
        [plusButton setImage:[UIImage imageNamed:@"plusButton"] forState:UIControlStateNormal];
                
        //TESTING
        [self setBackgroundColor:[UIColor colorWithWhite:0 alpha:.5]];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame delegate:(id<SelectAlarmViewDelegate>)aDelegate {
    delegate = aDelegate;
    return [self initWithFrame:frame];
}

#pragma mark - Actions
- (void) plusButtonTapped:(id)button {
    TFLog(@"plus button tapped");
    // return if there are already max_alarms
    if (numAlarms == MAX_ALARMS)
        return;
    
    TFLog(@"attempting to add");

    if ([delegate respondsToSelector:@selector(alarmAdded)])
        [delegate alarmAdded];
}

- (void) deleteAlarm:(int)index {
    numAlarms--;
    [self animateRemoveAlarmAtIndex:numAlarms - index];
    return;
}
- (void) addAlarmAnimated:(bool)animated {        
    numAlarms++;

    // position new alarmbutton
    CGRect newAlarmRect = CGRectMake(0, restedY, 0, 2);
    UIView *newAlarm = [[UIView alloc] initWithFrame:newAlarmRect];
    [newAlarm setBackgroundColor:[UIColor whiteColor]];
    [alarmContainer addSubview:newAlarm];
    [alarmButtons insertObject:newAlarm atIndex:0];
    
    // animate the insert of new alarm button
    if (animated)
        [self animateArrangeButtons];
    else
        [self arrangeButtons];
    
}
- (void) makeAlarmActiveAtIndex:(int)index {
    NSLog(@"alarms: %i, buttons: %i, switchTO: %i", numAlarms, [alarmButtons count], index);
    
    int buttonIndex = numAlarms - 1 - index;
    
    for (UIView *alarmButton in alarmButtons)
        [alarmButton setAlpha:.7];
    [[alarmButtons objectAtIndex:buttonIndex] setAlpha:1];
}

- (void) makeAlarmSetAtIndex:(int)index percent:(float)percent {
    int buttonIndex = numAlarms - 1 - index;
    UIView *alarmButton = [alarmButtons objectAtIndex:buttonIndex];
    CGRect alarmButtonSetRect = CGRectMake(alarmButton.frame.origin.x, restedY - (percent * setAlarmY), alarmButton.frame.size.width, alarmButton.frame.size.height);
    
    if (percent == 1 || percent == 0)
        [UIView animateWithDuration:.2 animations:^{
            [alarmButton setFrame:alarmButtonSetRect];
        }];
    else 
        [alarmButton setFrame:alarmButtonSetRect];
}

#pragma mark - Animations
- (void) animateArrangeButtons {
    //float buttonWidth = (alarmContainer.frame.size.width - ALARM_SPACING*numAlarms) / numAlarms;
    
    [UIView animateWithDuration:.1 animations:^{
        [self arrangeButtons];
    }];
}
- (void) animateRemoveAlarmAtIndex:(int)index {
    float buttonWidth = (alarmContainer.frame.size.width - ALARM_SPACING*numAlarms) / numAlarms;
    
    [UIView animateWithDuration:.1 animations:^{
        for (int i=[alarmButtons count]-1; i>=0; i--) { // faster than iterating upwards
            UIView *alarmButton = [alarmButtons objectAtIndex:i];
            CGRect newButtonFrame;
            
            if (i == index)
                newButtonFrame = CGRectMake((buttonWidth+ALARM_SPACING)*i, alarmButton.frame.origin.y, 0, alarmButton.frame.size.height);
            else if (i > index)
                newButtonFrame = CGRectMake((buttonWidth+ALARM_SPACING)*(i-1), alarmButton.frame.origin.y, buttonWidth, alarmButton.frame.size.height);
            else 
                newButtonFrame = CGRectMake((buttonWidth+ALARM_SPACING)*i, alarmButton.frame.origin.y, buttonWidth, alarmButton.frame.size.height);
            
            [[alarmButtons objectAtIndex:i] setFrame:newButtonFrame];
        }
    } completion:^(BOOL finished) {
        [alarmButtons removeObjectAtIndex:index];
        int switchIndex = index==0?0:index-1;
        if ([delegate respondsToSelector:@selector(switchAlarmWithIndex:)])
            [delegate switchAlarmWithIndex:numAlarms - 1 - switchIndex];
    }];
}

#pragma mark - Touches
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (numAlarms == 0)
        return;
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLoc = [touch locationInView:alarmContainer];
    
    int touchIndex = numAlarms - 1 - floorf(touchLoc.x/ (alarmContainer.frame.size.width/numAlarms));
    
    if ([delegate respondsToSelector:@selector(switchAlarmWithIndex:)])
        [delegate switchAlarmWithIndex:touchIndex];
}


#pragma mark - Drawing

- (void) arrangeButtons {
    float buttonWidth = (alarmContainer.frame.size.width - ALARM_SPACING*numAlarms) / numAlarms;
    
    for (int i=[alarmButtons count]-1; i>=0; i--) { // faster than iterating upwards
        UIView *alarmButton = [alarmButtons objectAtIndex:i];
        CGRect newButtonFrame = CGRectMake((buttonWidth+ALARM_SPACING)*i, alarmButton.frame.origin.y, buttonWidth, alarmButton.frame.size.height);
        [[alarmButtons objectAtIndex:i] setFrame:newButtonFrame];
    }
}



- (void) positionAlarm:(int)index percent:(float)percent {
    
}


/* Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{    
    // draw the plus sign
    float weight = 2;
    float sideLength = 18;
    float spaceWidth = 5;
    
    CGPoint firstPoint = CGPointMake(spaceWidth+sideLength, 2);
    
    UIBezierPath *plusButton = [UIBezierPath bezierPath];
    [plusButton moveToPoint:firstPoint];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x + weight, firstPoint.y)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x + weight, firstPoint.y + sideLength)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x + weight + sideLength, firstPoint.y + sideLength)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x + weight + sideLength, firstPoint.y + sideLength + weight)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x + weight, firstPoint.y + sideLength + weight)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x + weight, firstPoint.y + sideLength + weight + sideLength)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x, firstPoint.y + sideLength + weight + sideLength)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x, firstPoint.y + sideLength + weight)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x - sideLength, firstPoint.y + sideLength + weight)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x - sideLength, firstPoint.y + sideLength)];
    [plusButton addLineToPoint:CGPointMake(firstPoint.x, firstPoint.y + sideLength)];
    [plusButton closePath];
    
    [[UIColor whiteColor] setFill];  [plusButton fill];
}*/


@end
