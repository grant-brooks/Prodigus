//
//  PopularVideoViewController.h
//  Prodigus II
//
//  Created by Grant Goodman on 6/3/15.
//  Copyright © 2015 Macster Software Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

//Custom Header Imports
#import "YTPlayerView.h"

@class VideoViewController;

@interface PopularVideoViewController : UIViewController


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                  Interface Builder UI Elements                                                  */

/*! The player's web view overlay. Acts as a UIWebView in which a video that is restricted from playback on/in other applications besides ones verified by YouTube can be displayed. */
@property (strong, nonatomic) IBOutlet UIWebView *playerWebViewOverlay;


/*! A gesture recognizer that responds to a single tap on the media player's overlay. */
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapPlayerGestureRecognizer;


/*! A table view that contains YouTube videos. */
@property (strong, nonatomic) IBOutlet UITableView *videoTableView;


/*! A text view that displays the description of a YouTube video.*/
@property (strong, nonatomic) IBOutlet UITextView *videoDescription;


/*! A custom view that displays a YouTube video */
@property (strong, nonatomic) IBOutlet YTPlayerView *playerView;


/*! The video's publisher's ID label. */
@property (strong, nonatomic) IBOutlet UILabel      *channelID;
/*! A label which displays the amount of dislikes on a video. */
@property (strong, nonatomic) IBOutlet UILabel      *dislikeCount;
/*! A label which displays the amount of likes on a video. */
@property (strong, nonatomic) IBOutlet UILabel      *likeCount;
/*! A label which displays the title of a video. */
@property (strong, nonatomic) IBOutlet UILabel      *videoTitle;
/*! A label on the player's control view that displays the current time in the video. */
@property (weak, nonatomic)   IBOutlet UILabel      *currentTimeLabel;
/*! A label that displays the date that a video was published. */
@property (weak, nonatomic)   IBOutlet UILabel      *publishedAt;
/*! A label on the player's control view that displays the time remaining in the video. */
@property (weak, nonatomic)   IBOutlet UILabel      *timeRemainingLabel;


/*! A UIView that contains the media player's custom controls. */
@property (weak, nonatomic)   IBOutlet UIView *controlView;
/* A view that contains the aspects of a YouTube video. */
@property (strong, nonatomic) IBOutlet UIView *detailsView;
/*! A UIView that acts as an overlay over the media player, effectively disabling user interaction with the actual media player. */
@property (weak, nonatomic)   IBOutlet UIView *playerOverlay;


/*! A button which allows a video to be favorited or unfavorited. */
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
/*! A button which pauses a video. */
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
/*! A button which plays a video. */
@property (weak, nonatomic) IBOutlet UIButton *playButton;


/*! A slider on the player's control view that updates to represent the video's current time, and allows the user to adjust the current video's time. */
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;

 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                      Interface Builder Actions                                                  */


/*! An action that favorites or unfavorites a video. */
- (IBAction)favoriteButton:(id)sender;
/*! An action that responds to a tap on the player view. */
- (IBAction)tapPlayerGestureRecognizer:(id)sender;


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                  Non-Interface Builder UI Elements                                              */


/*! A refresh control that refreshes the table view of videos. */
@property (strong, nonatomic) UIRefreshControl       *refreshControl;
/*! A search controller that handles the searching for videos. */
@property (strong, nonatomic) UISearchController     *searchController;
/*! A navigation controller that encompasses the video's view controller. */
@property (strong, nonatomic) UINavigationController *videoNavigationController;


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                         View Controllers                                                        */


/*! A view controller that encompasses the video's user interface aspects. */
@property (strong, nonatomic) VideoViewController *videoViewController;


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                                  Strings                                                        */

 
/*! The current time of the video as a string. */
@property (strong, nonatomic) NSString       *timeAsString;
/*! The current video's identifier. */
@property (strong, nonatomic) NSString       *videoID;
/*! The title of the current video. */
@property (strong, nonatomic) NSString       *videoTitleString;


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                              Arrays                                                             */

 
/*! A mutable array that contains a backup of the current list of videos. */
@property (strong, nonatomic) NSMutableArray *backupVideoList;
/*! A mutable array that contains the titles of the videos that have been favorited. */
@property (strong, nonatomic) NSMutableArray *favoritesArray;
/*! A mutable array that contains the index paths of the videos that have been favorited. */
@property (strong, nonatomic) NSMutableArray *favoritesIndexPathArray;
/*! A mutable array that contains the links to the videos that have been favorited. */
@property (strong, nonatomic) NSMutableArray *favoritesLinkArray;
/*! A mutable array that contains the durations of the videos that have been favorited. */
@property (strong, nonatomic) NSMutableArray *favoritesTimeArray;
/*! A mutable array that contains a list of some of YouTube's most recent popular videos. */
@property (strong, nonatomic) NSMutableArray *popularVideoList;
/* A mutable that contains a list of YouTube videos. */
@property (strong, nonatomic) NSMutableArray *videoList;


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                           Boolean Values														   */

/*! A boolean value that specifies whether or not the enter/exit fullscreen method(s) have been called. */
@property BOOL calledOnce;
/*! A boolean value that specifies whether or not the device is in landscape mode. */
@property BOOL deviceInLandscape;
/*! A boolean value that specifies whether or not a method has been called from the favoriting method. */
@property BOOL fromFavorite;
/*! A boolean value that specifies whether or not a favorited video has been selected. */
@property BOOL hasBeenPressed;
/*! A boolean value that specifies whether or not a method has already been called. */
@property BOOL hasCalled;
/*! A boolean value that specifies whether or not the playback alert has already been shown. */
@property BOOL hasShown;
/*! A boolean value that specifies whether or not a video is buffering. */
@property BOOL isBuffering;
/*! A boolean value that specifies whether or not something is hidden. */
@property BOOL isHidden;
/*! A boolean value that specifies whether or not the device is in landscape mode. */
@property BOOL isLandscape;
/*! A boolean value that specifies whether or not a video is paused. */
@property BOOL isPaused;
/*! A boolean value that specifies whether or not a video is playing. */
@property BOOL isPlaying;
/*! A boolean value that specifies whether or not the search controller is active. */
@property BOOL isSearch;
/*! A boolean value that specifies whether or not the media player is currently being shown on the super view. */
@property BOOL mpRemoved;
/*! A boolean value that specifies whether or not the user has selected for the playback warning not to be displayed again. */
@property BOOL noShowAgain;
/*! A boolean value that specifies whether or not the status bar should be shown in a certain situation. */
@property BOOL statusBarNeeded;

 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                Other Non-Interface Builder Elements                                             */
 
 
/*! A timer that waits five seconds before hiding the player controls. Depends on multiple factors. */
@property (strong, nonatomic) NSTimer *hideControlTimer;
/*! A timer that updates every second for every second in a video. */
@property (strong, nonatomic) NSTimer *videoTimer;


/*! An index path that describes where in a table view of videos that there exists a favorited video. */
@property (strong, nonatomic) NSIndexPath *indexPathForFavorite;


/*! The remaining time in a video. */
@property (nonatomic, assign) float remainingTime;
/*! The time in seconds in a video. */
@property (nonatomic, assign) float unformattedVideoTime;
/*! The total time in a video. */
@property (nonatomic, assign) float videoTime;


/*! A dictionary that contains the JSON of a YouTube video list. */
@property (retain, nonatomic) NSDictionary *videoListJSON;


/*! The amount of rows in a table view. */
@property (nonatomic) int rowCount;
/*! The amount of times the search bar has ended editing. */
@property (nonatomic) int endedCount;
/*! The amount of times the video has entered fullscreen mode. */
@property (nonatomic) int fullCount;


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


@end
