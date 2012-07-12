//
//  MusicLibrary.m
//  Start
//
//  Created by Nick Place on 6/21/12.
//  Copyright (c) 2012 TackMobile. All rights reserved.
//

#import "MusicManager.h"

@implementation MusicManager

- (id) init {
    self = [super init];
    if (self) {
        pListModel = [[PListModel alloc] init];
    }
    return self;
}

#pragma mark - themes

- (NSDictionary *)getThemeForSongID:(NSNumber *)songID {
    NSArray *themes = [pListModel getThemes];
    return [self formatTheme:[themes objectAtIndex:1]];
}

- (NSDictionary *)getThemeWithID:(int)themeID {
    NSArray *themes = [pListModel getThemes];
    return [self formatTheme:[themes objectAtIndex:themeID]];
}

- (NSDictionary *)formatTheme:(NSDictionary *)pListTheme {
    NSMutableDictionary *theme = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                [UIColor blackColor],@"outerRingColor",
                                [UIColor blackColor],@"innerRingColor",
                                [UIColor blackColor],@"outerColor",
                                [UIColor blackColor],@"innerColor",
                                [UIColor blackColor],@"centerColor",
                                [UIColor blackColor],@"outerHandleColor",
                                [UIColor blackColor],@"innerHandleColor",
                                [UIImage imageNamed:@"squares"], @"bgImg",
                                nil];
    NSLog(@"%@", pListTheme);
    
    float opacity = 1.0;
    
    opacity = [(NSNumber *)[pListTheme objectForKey:@"outerRingOpacity"] floatValue];
    [theme setObject:[UIColor colorWithHexString:[pListTheme objectForKey:@"outerRingColor"] andAlpha:opacity] 
              forKey:@"outerRingColor"];
    opacity = [(NSNumber *)[pListTheme objectForKey:@"innerRingOpacity"] floatValue];
    [theme setObject:[UIColor colorWithHexString:[pListTheme objectForKey:@"innerRingColor"] andAlpha:opacity] 
              forKey:@"innerRingColor"];
    
    opacity = [(NSNumber *)[pListTheme objectForKey:@"outerOpacity"] floatValue];
    [theme setObject:[UIColor colorWithHexString:[pListTheme objectForKey:@"outerColor"] andAlpha:opacity]
              forKey:@"outerColor"];
    opacity = [(NSNumber *)[pListTheme objectForKey:@"innerOpacity"] floatValue];
    [theme setObject:[UIColor colorWithHexString:[pListTheme objectForKey:@"innerColor"] andAlpha:opacity]
              forKey:@"innerColor"];
    opacity = [(NSNumber *)[pListTheme objectForKey:@"centerOpacity"] floatValue];
    [theme setObject:[UIColor colorWithHexString:[pListTheme objectForKey:@"centerColor"] andAlpha:opacity]
              forKey:@"centerColor"];
    
    [theme setObject:[UIColor colorWithHexString:[pListTheme objectForKey:@"innerHandleColor"] andAlpha:1] 
              forKey:@"innerHandleColor"];
    [theme setObject:[UIColor colorWithHexString:[pListTheme objectForKey:@"outerHandleColor"] andAlpha:1]
              forKey:@"outerHandleColor"];
    
    [theme setObject:[UIImage imageNamed:(NSString *)[pListTheme objectForKey:@"bgFilename"]] forKey:@"bgImg"];
    
    return theme;
}

#pragma mark - library querying

- (NSArray *) getLibrarySongs {
    MPMediaQuery *songQuery = [[MPMediaQuery alloc] init];
    librarySongs = [songQuery items];
    return librarySongs;
}

- (UIImage *) getBackgroundImageForSongID:(NSNumber *)songID {
    // query the song
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:songID forProperty:MPMediaItemPropertyPersistentID];
    [query addFilterPredicate:predicate];
    NSArray *songs = [query items];
    
    MPMediaItem *song;
    if ([songs count] > 0)
        song = [songs objectAtIndex:0];
    else
        return [self getRandomImage];
    
    CGRect screenBounds = [[UIScreen mainScreen] applicationFrame];
    
    // get the madia artwork
    MPMediaItemArtwork *mediaArtwork = [song valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *mediaArtworkImage;
    // get random image if media has no artwork
    if (CGSizeEqualToSize(CGSizeMake(0, 0), mediaArtwork.bounds.size)) {
        mediaArtworkImage = [self getRandomImage];
    } else {
        mediaArtworkImage = [mediaArtwork imageWithSize:CGSizeMake(screenBounds.size.height, screenBounds.size.height)];
        // convert to correct colorspace
        if (CGImageGetColorSpace(mediaArtworkImage.CGImage) != CGColorSpaceCreateDeviceRGB())
            mediaArtworkImage = [mediaArtworkImage normalize];
        
        // blur image
        mediaArtworkImage = [mediaArtworkImage stackBlur:5];
    }
    
    return mediaArtworkImage;
}

- (UIImage *) getRandomImage {
    // testing
    return [UIImage imageNamed:@"noAlbumImage"];
}
@end

@implementation UIColor (ColorWithHex)

+(UIColor*)colorWithHexValue:(uint)hexValue andAlpha:(float)alpha {
    return [UIColor  
            colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0 
            green:((float)((hexValue & 0xFF00) >> 8))/255.0 
            blue:((float)(hexValue & 0xFF))/255.0 
            alpha:alpha];
}

+(UIColor*)colorWithHexString:(NSString*)hexString andAlpha:(float)alpha {
    UIColor *col;
    hexString = [hexString stringByReplacingOccurrencesOfString:@"#" 
                                                     withString:@"0x"];
    uint hexValue;
    if ([[NSScanner scannerWithString:hexString] scanHexInt:&hexValue]) {
        col = [self colorWithHexValue:hexValue andAlpha:alpha];
    } else {
        // invalid hex string         
        col = [self blackColor];
    }
    return col;
}

@end