//
//  SelectSongView.h
//  Start
//
//  Created by Nick Place on 6/15/12.
//  Copyright (c) 2012 TackMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicManager.h"
#import "SongCell.h"
#import "SearchSongCell.h"
#import "LeftHeaderView.h"
#import "ReturnButtonView.h"

@protocol SelectSongViewDelegate <NSObject>
-(BOOL) expandSelectSongView;
-(void) songSelected:(NSNumber *)persistentMediaItemID withArtwork:(UIImage *)artwork theme:(NSNumber *)themeID;
-(void) compressSelectSong;
// - (void) song selected with album artwork:

@end


@interface SelectSongView : UIView <UITableViewDataSource, UITableViewDelegate, SearchSongCellDelegate> {
    bool isOpen;
    bool isSearching;
    bool artworkPresent;
    NSIndexPath *selectedIndexPath;
    
    CGRect compressedFrame;
    NSArray *librarySongs;
    NSArray *searchedSongs;
    NSArray *presetSongs;
    
    NSMutableArray *headerViews;
    
}
@property (nonatomic, strong) id<SelectSongViewDelegate> delegate;

@property (nonatomic, strong) MusicManager *musicManager;

@property (nonatomic, strong) UITableView *songTableView;

- (void) quickSelectCell;
- (void) selectCellWithID:(NSNumber *)cellNumID ;
- (id) initWithFrame:(CGRect)frame delegate:(id<SelectSongViewDelegate>)aDelegate presetSongs:(NSArray *)thePresetSongs;

@end

@interface DUTableView : UITableView

- (void) reloadDataWithCompletion:( void (^) (void) )completionBlock;

@end