//
//  PopularVideoViewController.m
//  Prodigus II
//
//  Created by Grant Goodman on 6/3/15.
//  Copyright © 2015 Macster Software Corporation. All rights reserved.
//

#import "PopularVideoViewController.h"

//Custom Header Imports
#import "CustomVideoCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ProgressHUD.h"
#import "UIImageView+AFNetworking.h"
#import "YouTubeTools.h"
#import "YouTubeVideo.h"
#import "YTPlayerView.h"

@interface PopularVideoViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, YTPlayerViewDelegate, UIScrollViewDelegate, UIWebViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

@end

@implementation PopularVideoViewController


#pragma System Methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    //Set the bar button items for the navigationItems.
    if (self)
    {
        UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(backToPopular)];
        
        [leftBarButtonItem setTintColor:[UIColor blackColor]];
        [self.navigationItem setLeftBarButtonItem:leftBarButtonItem];
        [self.navigationItem.leftBarButtonItem setEnabled:NO];
        
        UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Search"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(searchIconButtonClicked)];
        
        [rightBarButtonItem setTintColor:[UIColor blackColor]];
        [self.navigationItem setRightBarButtonItem:rightBarButtonItem];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Return the status of the device's orientation, and set up the control view accordingly.
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        self.isLandscape = NO;
    }
    else
    {
        [self.controlView setUserInteractionEnabled:NO];
        [self.controlView setAlpha:0];
        self.isHidden = YES;
        self.isLandscape = YES;
    }
    
    
    //Hide the detail view.
    [self.detailsView setHidden:YES];
    
    //Hide the status bar.
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    self.statusBarNeeded = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    
    //Retrieve the user defaults.
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger noShowInt = [defaults integerForKey:@"noShowAgain"];
    
    if (noShowInt == 1)
    {
        self.noShowAgain = YES;
    }
    else
    {
        self.noShowAgain = NO;
    }
    
    //Initialize various notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(youTubeStarted:) name:UIWindowDidBecomeVisibleNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(youTubeFinished:) name:UIWindowDidBecomeHiddenNotification object:nil];
    
    //Hide and disable the video control view.
    [self.controlView setUserInteractionEnabled:NO];
    [self.controlView setAlpha:0];
    
    //Hide and disable the player view's web view overlay.
    [self.playerWebViewOverlay setUserInteractionEnabled:NO];
    [self.playerWebViewOverlay setHidden:YES];
    [self.playerWebViewOverlay setAlpha:0];
    
    //Set the seperator style of the UITableViewCell.
    [self.videoTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    //Initialize the various arrays.
    self.favoritesArray = [[NSMutableArray alloc] init];
    self.favoritesLinkArray = [[NSMutableArray alloc] init];
    self.favoritesTimeArray = [[NSMutableArray alloc] init];
    self.favoritesIndexPathArray = [[NSMutableArray alloc] init];
    self.videoList = [[NSMutableArray alloc] init];
    self.popularVideoList = [[NSMutableArray alloc] init];
    self.backupVideoList = [[NSMutableArray alloc] init];
    
    //Initialize the searchController.
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    [self.searchController setDimsBackgroundDuringPresentation:YES];
    [self.searchController setHidesNavigationBarDuringPresentation:NO];
    [self.searchController.searchBar sizeToFit];
    [self.searchController.searchBar setDelegate:self];
    [self.searchController.searchBar setPlaceholder:@""];
    [self.searchController.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    
    //Set the delegates of various objects.
    [self.videoTableView setDelegate:self];
    [self.playerView setDelegate:self];
    
    //Set the data source of videoTableView.
    [self.videoTableView setDataSource:self];
    
    //Set the tableHeaderView for videoTableView.
    [self.videoTableView setTableHeaderView:self.searchController.searchBar];
    
    //Hide the navigation bar in the view.
    [self.navigationController.navigationBar setHidden:YES];
    
    //Initialize refreshControl.
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(getPopularVideoList:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTag:100];
    [self.videoTableView addSubview:self.refreshControl];
    
    //Add and initialize various UISwipeGestureRecognizers.
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp:)];
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    
    [swipeDown setDelegate:self];
    
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    [self.playerOverlay addGestureRecognizer:swipeDown];
    [self.playerView addGestureRecognizer:swipeUp];
    [self.playerView addGestureRecognizer:swipeLeft];
    
    //Get the list of popular videos.
    [self getPopularVideoList:nil];
    
    //Layout the various views.
    [self.view setFrame:[[UIScreen mainScreen] bounds]];
    
    CGRect playerViewRect = CGRectMake(self.view.frame.size.width+10,
                                       self.view.frame.size.height,
                                       self.view.frame.size.width,
                                       self.view.frame.size.width / 16 * 9 + 20);
    
    [self.playerView setFrame:playerViewRect];
    
    //Set the frame of various views according to the type of device that the user is on.
    if (self.view.frame.size.width == 320)
    {
        if (self.view.frame.size.height == 568)
        {
            [self.detailsView setFrame:CGRectMake(0, 252.875, 320, 369.125)];
        }
        else
        {
            [self.detailsView setFrame:CGRectMake(0, 252.875, 320, 281.125)];
        }
        
        [self.timeSlider setFrame: CGRectMake(self.timeSlider.frame.origin.x, self.timeSlider.frame.origin.y, 200, self.timeSlider.frame.size.height)];
        [self.timeRemainingLabel setFrame: CGRectMake(self.timeSlider.frame.origin.x + 170, self.timeSlider.frame.origin.y, 100, self.timeSlider.frame.size.height)];
        
        CGRect controlViewRect = CGRectMake(0,
                                            160,
                                            320,
                                            40);
        
        [self.controlView setFrame:controlViewRect];
    }
    else if (self.view.frame.size.width == 414)
    {
        [self.detailsView setFrame:CGRectMake(0, 252.875, 414, 481.125)];
    }
    else if (self.view.frame.size.width == 375)
    {
        [self.timeSlider setFrame: CGRectMake(self.timeSlider.frame.origin.x, self.timeSlider.frame.origin.y, 250, self.timeSlider.frame.size.height)];
        [self.timeRemainingLabel setFrame: CGRectMake(self.timeSlider.frame.origin.x + 220, self.timeSlider.frame.origin.y, 100, self.timeSlider.frame.size.height)];
        
        [self.detailsView setFrame:CGRectMake(0, 252.875, 375, 441.125)];
        
        CGRect controlViewRect = CGRectMake(0,
                                            190,
                                            375,
                                            40);
        
        [self.controlView setFrame:controlViewRect];
    }
    else
    {
        NSLog(@"Device's Width: '%f'.", self.view.frame.size.width);
    }
    
    [self.playerOverlay setFrame:playerViewRect];
    [self.playerWebViewOverlay setFrame:playerViewRect];
    [self.videoTableView setFrame:self.view.bounds];
    
    //Set various boolean values.
    self.mpRemoved = YES;
    self.hasCalled = NO;
    self.calledOnce = NO;
}


///Function that describes what actions should be performed in the event that the YouTube media player has entered fullscreen mode. Triggered by an NSNotification.
-(void)youTubeStarted:(NSNotification *)notification
{
    //Upon having the YouTube player enter fullscreen mode, log it to the console.
    //NSLog(@"The player has entered fullscreen mode.");
    
    //Increase the fullCount integer value by one.
    self.fullCount ++;
    
    //If the fullCount integer is greater than one and the calledOnce boolean value is set to 'NO', set the calledOnce boolean value.
    if (self.fullCount > 1 && self.calledOnce == NO)
    {
        //Set the calledOnce boolean value.
        self.calledOnce = YES;
    }
}

///Function that describes what actions should be performed in the event that the YouTube media player has exited fullscreen mode. Triggered by an NSNotification.
-(void)youTubeFinished:(NSNotification *)notification
{
    //Upon having the YouTube player exit fullscreen mode, log it to the console, and set up the view as needed.
    //NSLog(@"The player has exited fullscreen mode.");
    
    //Increase the fullCount integer value by one.
    self.fullCount ++;
    
    //If the fullCount integer is greater than one and the calledOnce boolean value is set to 'NO', perform various actions.
    if (self.fullCount > 1 && self.calledOnce == NO)
    {
        //Call the 'setUpViewForAlternateDisplay' function, which sets up the view for an alternate display method, as the video most likely is protected from playback on/in other applications.
        [self setUpViewForAlternateDisplay];
        
        //If the device's orientation is not in portrait mode, make it that way.
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (!orientation == 0)
        {
            [[UIDevice currentDevice] setValue:
             [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
                                        forKey:@"orientation"];
        }
        
        //Set the calledOnce boolean value.
        self.calledOnce = YES;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Add a notifier to notify us when the device's orientation changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    //Removes the clear text button on the UISearchBar.
    [self removeClearButtonFromView:self.searchController.searchBar];
}

///Function that removes the clear text button on the UISearchBar.
- (void)removeClearButtonFromView:(UIView *)view
{
    //If the object is not a view, do nothing.
    if (!view)
    {
        return;
    }
    
    //For every UIView in the sub-view of the view that was passed, run the function.
    for (UIView *subview in view.subviews)
    {
        [self removeClearButtonFromView:subview];
    }
    
    //If the view responds to UITextInput protocol, disable the clear button on the view everywhere except for when editing.
    if ([view conformsToProtocol:@protocol(UITextInputTraits)])
    {
        UITextField *textView = (UITextField *)view;
        if ([textView respondsToSelector:@selector(setClearButtonMode:)])
        {
            [textView setClearButtonMode:UITextFieldViewModeWhileEditing];
        }
    }
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //Remove the orientation notifier when the view disappears.
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}


#pragma Orientation Methods


- (CGFloat) orientationMultiplier
{
    //Return the status of the device's orientation.
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        return 2;
    }
    
    else
        return 4;
}

- (void)orientationChanged:(NSNotification *)notification
{
    //Upon an orientation change, adjust the views accordingly.
    [self adjustViewsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    //Return the status of the device's orientation.
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    //If the device's orientation is in portrait mode, determine how the player controls should be displayed, and set up the view accordingly.
    //Otherwise, determine how the player controls should be displayed, and set up the view accordingly.
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        //NSLog(@"The device's orientation has changed to portrait.");
        self.isLandscape = NO;
        
        //Make sure that the detail view is visible to the user.
        if ((![self mpIsMinimized] && self.isPlaying) || self.isBuffering || self.isPaused)
        {
            [self.detailsView setHidden:NO];
            [self.detailsView setAlpha:1];
            [self.detailsView setUserInteractionEnabled:YES];
            [self.view bringSubviewToFront:self.detailsView];
        }
        
        //If the video is playing or is paused, set up the controls on the view accordingly.
        if (self.isPlaying == YES || self.isPaused == YES)
        {
            //Show the player controls.
            [self.controlView setUserInteractionEnabled:YES];
            [self.controlView setAlpha:0.55];
            
            //Show the player's overlay.
            [self.playerOverlay setFrame:self.playerView.frame];
            [self.playerOverlay setHidden:NO];
            [self.playerOverlay setUserInteractionEnabled:YES];
            [self.playerOverlay setAlpha:1];
            
            //Bring the player's overlay followed by the player controls to the front of the view.
            [self.view bringSubviewToFront:self.playerOverlay];
            [self.view bringSubviewToFront:self.controlView];
            
            //Set the isHidden boolean value.
            self.isHidden = NO;
            
            //Hide the play button, unhide the pause button, add a control event method to the slier, and run the function 'dealWithTimer'.
            [self.playButton setHidden:YES];
            [self.pauseButton setHidden:NO];
            [self.timeSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            [self dealWithTimer];
        }
    }
    
    else
    {
        //NSLog(@"The device's orientation has changed to landscape.");
        
        //If the video is playing or is paused, set up the controls on the view accordingly.
        if (self.isPlaying == YES || self.isPaused == YES)
        {
            //Hide the player controls.
            [self.controlView setUserInteractionEnabled:NO];
            [self.controlView setAlpha:0];
            
            //Hide the player overlay.
            [self.playerOverlay setHidden:YES];
            [self.playerOverlay setUserInteractionEnabled:NO];
            [self.playerOverlay setAlpha:0];
            
            //Set various boolean values.
            self.isHidden = YES;
            self.isLandscape = YES;
        }
    }
    
}

- (void) adjustViewsForOrientation:(UIInterfaceOrientation) orientation
{
    //Adjust the views to fit the current orientation.
    CGFloat orientationMiltiplier = [self orientationMultiplier];
    
    CGFloat mpWidth = self.view.frame.size.width / orientationMiltiplier;
    CGFloat mpHeight = self.view.frame.size.width / 16 * 9 / orientationMiltiplier;
    
    CGFloat x = self.view.bounds.size.width-mpWidth - 20;
    CGFloat y = self.view.bounds.size.height-mpHeight - 20;
    
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            if (self.playerView.frame.origin.x == 0)
            {
                //NSLog(@"Portrait Orientation");
                
                //Define the 'playerViewRect' frame.
                CGRect playerViewRect = CGRectMake(0,
                                                   0,
                                                   self.view.frame.size.width,
                                                   self.view.frame.size.width / 16 * 9 + 20 );
                
                //Set the player view's frame.
                [self.playerView setFrame:playerViewRect];
                
                //CGRect detailsViewRect = CGRectMake(playerViewRect.origin.x,
                //                                    playerViewRect.size.height-1,
                //                                    playerViewRect.size.width,
                //                                    self.view.frame.size.height - playerViewRect.size.height);
                
                //If the calledOnce boolean value is set to 'NO', with an animation, set the frame of the detail view.
                //Otherwise, with an animation, set the frame of the detail view in a different way.
                if (self.calledOnce == NO)
                {
                    //With an animation, set the frame of the detail view.
                    [UIView animateWithDuration:0.5 animations:^
                     {
                         //If the device is an iPhone 4s/4/3GS/3G, set the detail view to a different frame.
                         //Otherwise, treat the device as if it is an iPhone 6 Plus, and set up the detail view accordingly.
                         if (self.view.frame.size.width == 320)
                         {
                             if (self.view.frame.size.height == 568)
                             {
                                 //Set the frame of the detail view.
                                 [self.detailsView setFrame:CGRectMake(0, 153.875, 320, 430)];
                             }
                             else
                             {
                                 //Set the frame of the detail view.
                                 [self.detailsView setFrame:CGRectMake(0, 153.875, 320, 330)];
                             }
                         }
                         else if (self.view.frame.size.width == 375)
                         {
                             [self.detailsView setFrame:CGRectMake(0, 153.875, 375, 515)];
                         }
                         else if (self.view.frame.size.width == 414)
                         {
                             //Set the frame of the detail view.
                             [self.detailsView setFrame:CGRectMake(0, 153.875, 414, 582.125)];
                         }
                     }];
                }
                else
                {
                    //With an animation, set the frame of the detail view.
                    [UIView animateWithDuration:0.5 animations:^
                     {
                         //If the device is an iPhone 4s/4/3GS/3G, set the detail view to a different frame.
                         //Otherwise, treat the device as if it is an iPhone 6 Plus, and set up the detail view accordingly.
                         if (self.view.frame.size.width == 320)
                         {
                             if (self.view.frame.size.height == 568)
                             {
                                 [self.detailsView setFrame:CGRectMake(0, 252.875, 320, 369.125)];
                             }
                             else
                             {
                                 [self.detailsView setFrame:CGRectMake(0, 252.875, 320, 281.125)];
                             }
                         }
                         else if (self.view.frame.size.width == 375)
                         {
                             [self.detailsView setFrame:CGRectMake(0, 252.875, 375, 441.125)];
                         }
                         else if (self.view.frame.size.width == 414)
                         {
                             //Set the frame of the detail view.
                             [self.detailsView setFrame:CGRectMake(0, 252.875, 414, 481.125)];
                         }
                     }];
                }
            }
            else if (!self.mpRemoved)
            {
                //Define the 'containerFrame' frame.
                CGRect containerFrame = CGRectMake(x, y, mpWidth, mpHeight);
                
                //With an animation, set the frame of the player view.
                [UIView animateWithDuration:0.5 animations:^
                 {
                     [self.playerView setFrame:containerFrame];
                 }];
                
            }
            
            //Set the frame of the video table view.
            [self.videoTableView setFrame:self.view.frame];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            if (self.playerView.frame.origin.x == 0)
            {
                //Define the 'playerViewRect' frame.
                CGRect playerViewRect = CGRectMake(0,
                                                   0,
                                                   self.view.frame.size.width,
                                                   self.view.frame.size.height);
                
                //Set the frame of the player view.
                [self.playerView setFrame:playerViewRect];
                
                //Make sure that the video controls are hidden to the user.
                [self.controlView setUserInteractionEnabled:NO];
                [self.controlView setAlpha:0];
                self.isHidden = YES;
            }
            else if (!self.mpRemoved)
            {
                //Define the 'containerFrame' frame.
                CGRect containerFrame = CGRectMake(x, y, mpWidth, mpHeight);
                
                //With an animation, set the framr of the player view, and make sure that the video controls are hidden to the user.
                [UIView animateWithDuration:0.5 animations:^
                 {
                     [self.playerView setFrame:containerFrame];
                     [self.controlView setUserInteractionEnabled:NO];
                     [self.controlView setAlpha:0];
                     self.isHidden = YES;
                 }];
            }
            
            //Set the frame of the video table view.
            [self.videoTableView setFrame:self.view.frame];
        }
            break;
        case UIInterfaceOrientationUnknown:break;
    }
}


#pragma Network Methods

///Gets a list of popular videos.
- (void)getPopularVideoList:(UIRefreshControl *)sender;
{
    if (sender.tag != 100)
    {
        [ProgressHUD show:nil];
        [self.videoTableView setUserInteractionEnabled:NO];
        
        //Get the list of popular videos.
        self.popularVideoList = [YouTubeTools popularVideoArrayWithMaxResults:@"25"
                                                        withCompletitionBlock:^()
                                 {
                                     [ProgressHUD dismiss];
                                     [self.videoTableView setUserInteractionEnabled:YES];
                                     
                                     //Set the isSearch boolean value.
                                     self.isSearch = NO;
                                     
                                     //Reload the video table view.
                                     [self.videoTableView reloadData];
                                     
                                     //Stop refreshing the view.
                                     [self.refreshControl endRefreshing];
                                     
                                     //Set the title of the navigation bar.
                                     [self.navigationItem setTitle:@"Featured"];
                                     
                                     //If the popular video list contains anything, set the backup video list to it's contents.
                                     //Otherwise, log the fact that the popular video list does not contain anything.
                                     if (self.popularVideoList != nil)
                                     {
                                         self.backupVideoList = self.popularVideoList;
                                     }
                                     else
                                     {
                                         //NSLog(@"Nothing is contained within 'popularVideoList'.");
                                     }
                                 }];;
        
        //Set the isSearch boolean value
        self.isSearch = NO;
    }
    else
    {
        if (self.searchController.searchBar.text != nil)
        {
            [self searchBarSearchButtonClicked:self.searchController.searchBar];
        }
        else
        {
            //Get the list of popular videos.
            self.popularVideoList = [YouTubeTools popularVideoArrayWithMaxResults:@"25"
                                                            withCompletitionBlock:^()
                                     {
                                         [ProgressHUD dismiss];
                                         [self.videoTableView setUserInteractionEnabled:YES];
                                         
                                         //Set the isSearch boolean value.
                                         self.isSearch = NO;
                                         
                                         //Reload the video table view.
                                         [self.videoTableView reloadData];
                                         
                                         //Stop refreshing the view.
                                         [self.refreshControl endRefreshing];
                                         
                                         //Set the title of the navigation bar.
                                         [self.navigationItem setTitle:@"Featured"];
                                         
                                         //If the popular video list contains anything, set the backup video list to it's contents.
                                         //Otherwise, log the fact that the popular video list does not contain anything.
                                         if (self.popularVideoList != nil)
                                         {
                                             self.backupVideoList = self.popularVideoList;
                                         }
                                         else
                                         {
                                             //NSLog(@"Nothing is contained within 'popularVideoList'.");
                                         }
                                     }];;
            
            //Set the isSearch boolean value
            self.isSearch = NO;
        }
    }
}

///Function that handles the action for a refresh of the table view.
- (void) handleRefresh
{
    //If the search controller is not active, get the popular video list, and display it on the view.
    if (!self.isSearch)
        [self getPopularVideoList:nil];
}

///Function that handles the actions that are triggered when the user taps on the search bar button.
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [ProgressHUD show:nil];
    [self.videoTableView setUserInteractionEnabled:NO];
    
    //Layout the view when the search bar button is tapped.
    self.videoList = [YouTubeTools findVideoArrayWithString:self.searchController.searchBar.text
                                                 maxResults:@"50"
                                      withCompletitionBlock:^
                      {
                          [ProgressHUD dismiss];
                          [self.videoTableView setUserInteractionEnabled:YES];
                          
                          //Set the isSearch boolean value.
                          self.isSearch = YES;
                          
                          //Enable the left bar button item on the navigation bar.
                          [self.navigationItem.leftBarButtonItem setEnabled:YES];
                          
                          //Reload the table view.
                          [self.videoTableView reloadData];
                          
                          //Set the navigation bar's title.
                          [self.navigationItem setTitle:@"Search"];
                      }];
    
    //End editing of the view.
    [self.view endEditing:YES];
}

#pragma UITableView Methods

///Returns the number of sections in UITableView.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

///Return the number of rows in the sections of the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //If the search controller is active, return the count of the video list array.
    //Otherwise, find an array that contains the required objects, and return its count, instead.
    if (self.isSearch)
        return [self.videoList count];
    else
        //If the popular video list contains anything, return its count.
        //Otherwise, return the count of the backup video list.
        if (self.popularVideoList != nil)
        {
            return [self.popularVideoList count];
        }
        else
        {
            return [self.backupVideoList count];
        }
}

///Function that handles a scroll on a UIScrollView.
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //Hide and show the status bar according to how far the table view has scrolled.
    float scrollOffset = scrollView.contentOffset.y;
    
    //If the table view's offset is equal to 0 or is equal to -20, show the status bar with an animation.
    //Otherwise, if the table view's offset is not equal to zero or it is not equal to -20, hide the status bar with an animation.
    if (scrollOffset == 0 || scrollOffset == -20)
    {
        //With an animation, show the status bar.
        [UIView animateWithDuration:0.2 animations:^
         {
             self.statusBarNeeded = YES;
             [self setNeedsStatusBarAppearanceUpdate];
         }];
    }
#warning This statement may cause some problems with the '||', (or), statement.
    else if (!scrollOffset == 0 || scrollOffset != -20)
    {
        //With an animatiom, hide the status bar.
        [UIView animateWithDuration:0.1 animations:^
         {
             self.statusBarNeeded = NO;
             [self setNeedsStatusBarAppearanceUpdate];
         }];
    }
}

///Perform actions to update the table view's cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Hide the status bar.
    self.statusBarNeeded = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    
    //Set the cell's identifier, depending on whether the view is searching, or displaying popular videos.
    static NSString *cellIdentifier = @"Cell";
    CustomVideoCell *cell = (CustomVideoCell *)[self.videoTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        NSString *nibName;
        if (self.isSearch)
            nibName = @"SearchCustomCell";
        else
            nibName = @"CustomVideoCell";
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    //Populate the video results according to the view the device is presenting.
    YouTubeVideo *youTubeVideo;
    if (self.isSearch)
        youTubeVideo = self.videoList[indexPath.row];
    else
        //If the popular video list contains anything, return its count.
        //Otherwise, return the count of the backup video list.
        if (self.popularVideoList != nil)
        {
            youTubeVideo = self.backupVideoList[indexPath.row];
        }
        else
        {
            youTubeVideo = self.backupVideoList[indexPath.row];
        }
    
    
    //Set the cell's image to that of the YouTube video's thumbnail.
    [cell.previewImage setImageWithURL: [NSURL URLWithString: youTubeVideo.previewUrl]];
    [cell.previewImage setImageWithURL: [NSURL URLWithString: youTubeVideo.previewUrl]];
    
    //Set the cell's title to that of the YouTube video's.
    [cell.title setText:youTubeVideo.title];
    
    //If the favorites array contains the current video, set the star icon to appear on the cell's view.
    if ([self.favoritesArray indexOfObject:self.videoTitle.text] != NSNotFound && [self.favoritesLinkArray indexOfObject:self.videoID] != NSNotFound && [self.favoritesIndexPathArray indexOfObject:indexPath] != NSNotFound)
    {
        //Set the favorite button's image.
        //UIImage *image = [UIImage imageNamed:@"Star Filled-50.png"];
        //[self.favoriteButton setImage:image forState:UIControlStateNormal];
        
        //Unhide the favorite button.
        [cell.favoriteButton setHidden:NO];
    }
    
    //If the favorites array does not contain the current video, do not disply the star icon on the cell's view.
    if ([self.favoritesArray indexOfObject:self.videoTitle.text] == NSNotFound && [self.favoritesLinkArray indexOfObject:self.videoID] == NSNotFound && [self.favoritesIndexPathArray indexOfObject:indexPath] == NSNotFound)
    {
        //Set the favorite button's image.
        //UIImage *image = [UIImage imageNamed:@"Star-50.png"];
        //[self.favoriteButton setImage:image forState:UIControlStateNormal];
        
        //Hide the favorite button.
        [cell.favoriteButton setHidden:YES];
    }
    
#warning I am not sure what this code does, compared to the previous two lines. Please fix or comment this.
    if ([self.favoritesArray indexOfObject:youTubeVideo.title] != NSNotFound && [self.favoritesLinkArray indexOfObject:youTubeVideo.videoID] != NSNotFound && [self.favoritesIndexPathArray indexOfObject:indexPath] != NSNotFound)
    {
        //NSLog(@"The video currently being loaded into the table view, '%@', has been favorited, and in turn, will have a star displayed on it.", youTubeVideo.title);
        
        [cell.favoriteButton setHidden:NO];
    }
    else
    {
        [cell.favoriteButton setHidden:YES];
    }
    
    //Set the cell's like count label to that of the YouTube video's, after formatting the text.
    NSNumber *likeCount = @([youTubeVideo.likesCount integerValue]);
    NSString *formattedLikes = [NSNumberFormatter localizedStringFromNumber:likeCount numberStyle:NSNumberFormatterDecimalStyle];
    [cell.likeCount setText: formattedLikes];
    
    //Set the cell's dislike count label to that of the YouTube video's, after formatting the text.
    NSNumber *dislikeCount = @([youTubeVideo.dislikesCount integerValue]);
    NSString *formattedDislikes = [NSNumberFormatter localizedStringFromNumber:dislikeCount numberStyle:NSNumberFormatterDecimalStyle];
    [cell.dislikeCount setText:formattedDislikes];
    
    //Set the cell's channel title label to that of the YouTube video's.
    [cell.channelTitle setText:youTubeVideo.channelTitle];
    
    //Set the cell's view count label to that of the YouTube video's, after formatting the text.
    NSNumber *viewCount = @([youTubeVideo.viewsCount integerValue]);
    NSString *formattedViews = [NSNumberFormatter localizedStringFromNumber:viewCount numberStyle:NSNumberFormatterDecimalStyle];
    [cell.viewCount setText:[NSString stringWithFormat:@"%@ views", formattedViews]];
    
    //Set the cell's duration label to that of the YouTube video's.
    [cell.time setText:youTubeVideo.duration];
    
    //Set the cell's published date label to that of the YouTube video's, after formatting the text.
    NSDateFormatter *initialDateFormatter = [[NSDateFormatter alloc] init];
    [initialDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *initialDate = [initialDateFormatter dateFromString:youTubeVideo.publishedAt];
    
    NSDateFormatter *finalDateFormatter = [[NSDateFormatter alloc] init];
    [finalDateFormatter setDateFormat:@"MMM. d, yyyy"];
    NSString *dateString = [finalDateFormatter stringFromDate:initialDate];
    
    [cell.publishedAt setText:dateString];
    
    return cell;
    
}

///Set the actions to be performed after tapping on a cell.
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Unhide the detail view.
    [self.detailsView setHidden:NO];
    
    //Scroll the table view as to hide the status bar.
    NSIndexPath *indexPath2 = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    [tableView scrollToRowAtIndexPath:indexPath2
                     atScrollPosition:UITableViewScrollPositionTop
                             animated:YES];
    
    
    //Enable the player's overlay, and make sure that the video controls are hidden to the user.
    [self.playerOverlay setUserInteractionEnabled:YES];
    [self.controlView setUserInteractionEnabled:NO];
    [self.controlView setAlpha:0];
    self.isHidden = YES;
    
    //If the device is in portrait orientation mode, enable the video controls.
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == 0)
    {
        [[UIDevice currentDevice] setValue:
         [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
                                    forKey:@"orientation"];
        if (self.isLandscape == NO)
        {
            [self.controlView setUserInteractionEnabled:YES];
            [self.view bringSubviewToFront:self.controlView];
        }
    }
    
    //Hide the status bar.
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
    [UIView animateWithDuration:0.1 animations:^
     {
         self.statusBarNeeded = NO;
         [self setNeedsStatusBarAppearanceUpdate];
     }];
    
    //Populate the video results according to the view the device is presenting.
    YouTubeVideo *youTubeVideo;
    if (self.isSearch)
        youTubeVideo = self.videoList[indexPath.row];
    else
        if (self.popularVideoList != nil)
        {
            youTubeVideo = self.popularVideoList[indexPath.row];
        }
        else
        {
            youTubeVideo = self.backupVideoList[indexPath.row];
        }
    
    //Set the mpRemoved boolean value.
    self.mpRemoved = NO;
    
    //Set the video ID to that of the YouTube video's.
    self.videoID = youTubeVideo.videoID;
    
    //Take the duration of the YouTube video, in seconds, and convert it to a float value.
    CGFloat durationFloat = (CGFloat)[youTubeVideo.unformattedDuration floatValue];
    self.unformattedVideoTime = durationFloat;
    //NSLog(@"Time as Float: '%@'.", youTubeVideo.unformattedDuration);
    
    //If the video that was selected has been favorited, start the video at the time it was favorited at.
    //Otherwise, start it from the beginning.
    if (self.hasBeenPressed == YES && [self.favoritesArray indexOfObject:youTubeVideo.title] != NSNotFound && [self.favoritesLinkArray indexOfObject:youTubeVideo.videoID] != NSNotFound)
    {
        //NSLog(@"The video that was selected, '%@', has been favorited, and will start at its last recorded time of '%@'.", youTubeVideo.title, [self.favoritesTimeArray objectAtIndex:indexPath.row]);
        
        NSDictionary *playerVars = @{
                                     @"playsinline" : @"1",
                                     @"autoplay" :@1,
                                     @"showinfo" :@0,
                                     @"controls" :@0,
                                     @"enablejsapi" :@1,
                                     @"modestbranding" :@1,
                                     @"rel": @0,
                                     @"fs": @1,
                                     @"theme" :@"light",
                                     @"disablekb": @0,
                                     @"iv_load_policy": @3,
                                     @"start" :[self.favoritesTimeArray objectAtIndex:indexPath.row]
                                     };
        
        [self.playerView loadWithVideoId:youTubeVideo.videoID playerVars:playerVars];
    }
    else
    {
        NSDictionary *playerVars = @{
                                     @"playsinline" : @"1",
                                     @"autoplay" :@1,
                                     @"showinfo" :@0,
                                     @"controls" :@0,
                                     @"enablejsapi" :@1,
                                     @"modestbranding" :@1,
                                     @"rel": @0,
                                     @"fs": @1,
                                     @"theme" :@"light",
                                     @"disablekb": @0,
                                     @"iv_load_policy": @3
                                     };
        
        [self.playerView loadWithVideoId:youTubeVideo.videoID playerVars:playerVars];
    }
    
    //Begin playback of the YouTube video.
    [self.playerView playVideo];
    
    //Set the title and the description of the video according to that of what we retrieved from the selected YouTube video.
    [self.videoTitle setText:youTubeVideo.title];
    [self.videoDescription setText:youTubeVideo.videoDescription];
    
    //Set the cell's like count label to that of the YouTube video's, after formatting the text.
    NSNumber *likeCount = @([youTubeVideo.likesCount integerValue]);
    NSString *formattedLikes = [NSNumberFormatter localizedStringFromNumber:likeCount numberStyle:NSNumberFormatterDecimalStyle];
    [self.likeCount setText:formattedLikes];
    
    //Set the cell's dislike count label to that of the YouTube video's, after formatting the text.
    NSNumber *dislikeCount = @([youTubeVideo.dislikesCount integerValue]);
    NSString *formattedDislikes = [NSNumberFormatter localizedStringFromNumber:dislikeCount numberStyle:NSNumberFormatterDecimalStyle];
    [self.dislikeCount setText:formattedDislikes];
    
    //Set the channel ID of the vide according to that of what we retrieved from the selected YouTube video.
    [self.channelID setText:youTubeVideo.channelTitle];
    
    //Set the cell's published date label to that of the YouTube video's, after formatting the text.
    NSDateFormatter *initialDateFormatter = [[NSDateFormatter alloc] init];
    [initialDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *initialDate = [initialDateFormatter dateFromString:youTubeVideo.publishedAt];
    
    NSDateFormatter *finalDateFormatter = [[NSDateFormatter alloc] init];
    [finalDateFormatter setDateFormat:@"MMM. d, yyyy"];
    NSString *dateString = [finalDateFormatter stringFromDate:initialDate];
    
    [self.publishedAt setText:dateString];
    
    //Hide the navigation bar.
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    //Hide the status bar.
    self.statusBarNeeded = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    
    //Stop the search controller from performing any actions, or being active.
    [self.searchController setActive: NO];
    [self.view endEditing:YES];
    
    //With an animation, initialize the views for the YouTube video.
    [UIView animateWithDuration:0.2 animations:^
     {
         CGRect playerViewRect = self.playerView.frame;
         CGRect detailsViewRect = self.detailsView.frame;
         
         playerViewRect.origin.x = 0;
         playerViewRect.origin.y = 0;
         playerViewRect.size.width = self.view.bounds.size.width;
         playerViewRect.size.height = playerViewRect.size.width / 16 * 9 + 20;
         
         self.playerView.frame = playerViewRect;
         self.playerOverlay.frame = playerViewRect;
         self.playerWebViewOverlay.frame = playerViewRect;
         
         [self.view bringSubviewToFront:self.playerWebViewOverlay];
         [self.view bringSubviewToFront:self.playerOverlay];
         [self.view bringSubviewToFront:self.controlView];
         
         detailsViewRect.origin.x = 0;
         detailsViewRect.origin.y = playerViewRect.size.height;
         self.detailsView.frame = detailsViewRect;
         self.detailsView.alpha = 1.0;
         
         [[UIApplication sharedApplication] setStatusBarHidden:NO];
         //[self.playerView setSizeOfIFrameToWidth:160 Height:90];
     }];
    
    //Set the index path for the favoriting of the video to that of the current index path.
    self.indexPathForFavorite = indexPath;
}

///Set the height of the row at the currenr index path.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //If the device is currently searching, set the height to 88 pixels. Otherwise, set it to 208 pixels.
    if (self.isSearch)
        return 88;
    else
        return 208;
}

#pragma mark Gesture Recognizers

///Perform actions upon the user swiping left, as to remove the YouTube video from the view in its minimized state.
-(void)swipeLeft:(UIGestureRecognizer *)gr
{
    //Do not do anything if the the view is not minimized.
    if (![self mpIsMinimized])
        return;
    
    //Halt the video's playback.
    [self.playerView stopVideo];
    
    //Initialize the frame of the player.
    CGRect playerFrame = self.playerView.frame;
    playerFrame.origin.x = -self.playerView.frame.size.width;
    
    //With an animation, set the frame of the player.
    [UIView animateWithDuration:0.1 animations:^
     {
         self.playerView.frame = playerFrame;
     }
                     completion:^(BOOL finished)
     {
         self.playerView.frame = CGRectMake(self.view.frame.size.width, 0, 0, 0);
     }];
    
    //Set the mpRemoved boolean value.
    self.mpRemoved = YES;
    
    //If the hasBeenPressed boolean value is set to 'YES', record the current time of the YouTube video's playback at te time of removal from the view.
    if (self.hasBeenPressed == YES)
    {
        //NSLog(@"The video has been favorited, and the 'hasBeenPressed' boolean value is now set to 'YES'.");
        
        //Record the current video's time.
        self.videoTime = self.playerView.currentTime;
        self.timeAsString = [[NSNumber numberWithFloat:self.videoTime] stringValue];
        
        //Convert the float value to an integer value, perhaps a bit unconventionally.
        //If there is no decimal value in the float, and the time string does not exist, set it to a placeholder value of '0'.
        //Otherwise, remove the decimal value from the float, and convert it to an integer.
        if ([self.timeAsString rangeOfString:@"."].location == NSNotFound)
        {
            self.timeAsString = self.timeAsString;
        }
        else if (self.timeAsString == nil)
        {
            self.timeAsString = @"0";
        }
        else
        {
            NSString *subString = [self.timeAsString substringWithRange: NSMakeRange(0, [self.timeAsString rangeOfString: @"."].location)];
            self.timeAsString = subString;
        }
        
        //Add the time to the favorites time array.
        [self.favoritesTimeArray addObject:self.timeAsString];
        
        //NSLog(@"The time recorded at the end of '%@' was '%@'.", self.videoTitle.text, self.timeAsString);
    }
    
}

///Perform actions upon the user swiping down, as to minimize the YouTube video.
- (void)swipeDown:(UIGestureRecognizer *)gr
{
    //Record the current time of the video at minimize time.
    self.videoTime = self.playerView.currentTime;
    self.timeAsString = [[NSNumber numberWithFloat:self.videoTime] stringValue];
    if ([self.timeAsString rangeOfString:@"."].location == NSNotFound)
    {
        self.timeAsString = self.timeAsString;
    }
    else
    {
        NSString *subString = [self.timeAsString substringWithRange: NSMakeRange(0, [self.timeAsString rangeOfString: @"."].location)];
        self.timeAsString = subString;
    }
    
    //Minimize the player and its subsequent subviews.
    [self minimizeMp:YES animated:YES];
}

///Perform actions upon the user swiping up, as to maximize the YouTube video when in its minimized state.
- (void)swipeUp:(UIGestureRecognizer *)gr
{
    //Maximize the player and its subsequent subviews.
    [self minimizeMp:NO animated:YES];
    
    //Enable user interaction on the player's overlay.
    [self.playerOverlay setUserInteractionEnabled:YES];
    
    //Make sure that the video controls are now visible, if the device is not in landscape orientation mode.
    if (self.isLandscape == NO)
    {
        [self.controlView setHidden:NO];
        self.isHidden = NO;
        [self.view bringSubviewToFront:self.controlView];
    }
    
    //Unhide the detail view.
    [self.detailsView setHidden:NO];
}

///Boolean value telling the view controller whether or not to automatically rotate.
- (BOOL)shouldAutorotate
{
    return YES;
}

///Boolean value telling the view controller whether or not to automatically forward appearance and rotation methods to its child view controllers.
- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers
{
    return NO;
}

///Boolean value telling the view controller whether or not to automatically rotate to the view's currwent interface orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

///Perform actions upon the web view finishing loading.
- (void)webViewDidFinishLoad:(UIWebView*)webView
{
    //Add a listener to the player view, listening for an entrence and exit from the fullscreen view.
    [self.playerView.webView stringByEvaluatingJavaScriptFromString:@" for (var i = 0, videos = document.getElementsByTagName('video'); i < videos.length; i++) {"
     @"      videos[i].addEventListener('webkitbeginfullscreen', function(){ "
     @"           window.location = 'videohandler://begin-fullscreen';"
     @"      }, false);"
     @""
     @"      videos[i].addEventListener('webkitendfullscreen', function(){ "
     @"           window.location = 'videohandler://end-fullscreen';"
     @"      }, false);"
     @" }"
     ];
    
    //Set the player's web view overlay's content offset to 47, as to hide the bar at the top of the page.
    self.playerWebViewOverlay.scrollView.contentOffset = CGPointMake(0, 47);
    
    //Disable scrolling on the player's web view overlay.
    [self.playerWebViewOverlay.scrollView setScrollEnabled:NO];
    
    //Disabe user action being required to initialize the playback of media, and allow inline playback of said media.
    [self.playerWebViewOverlay setAllowsInlineMediaPlayback:YES];
    [self.playerWebViewOverlay setMediaPlaybackRequiresUserAction:NO];
}

///Boolean value that defines actions to be performed when a web view starts to load a URL request
- (BOOL)webView:(UIWebView *)thewebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //If the host of the web view is equal to various sites, disable the loading of them.
    //NSString *host = [request.URL host];
    //if ([host isEqualToString:@"m.youtube.com"] || [host isEqualToString:@"m.facebook.com"] || [host isEqualToString:@"twitter.com"] || [host isEqualToString:@"accounts.google.com"] || [host isEqualToString:@"youtube.com"] )
    //{
    //  return NO;
    //}
    
    //If the string of the request is equal to 'ytplayer://onStateChange?data=3', disable the loading of the web view.
    if ([request.URL.absoluteString isEqualToString:@"ytplayer://onStateChange?data=3"])
    {
        return NO;
    }
    
    //If the string of the request is equal to 'ytplayer://onStateChange?data=2', disable the loading of the web view.
    if ([request.URL.absoluteString isEqualToString:@"ytplayer://onStateChange?data=2"])
    {
        return NO;
    }
    
    return YES;
}


#pragma mark Minimization Methods

///Boolean value to perform actions when the media player is minimized.
-(BOOL)mpIsMinimized
{
    return self.playerView.frame.origin.y > 50;
}

///Function to minimize the media player.
- (void)minimizeMp:(BOOL)minimized animated:(BOOL)animated
{
    //If the media player is not already minimized, set the view up accordingly.
    //Set up the view in a different way if the media player is minimized.
    if (minimized == NO)
    {
        //NSLog(@"Not Minimmized.");
        
        //Declare variables for various frames and a float value which will contain information about the view.
        CGRect tallContainerFrame, containerFrame;
        CGFloat tallContainerAlpha;
        
        //Set the orientation multiplier to a float value.
        CGFloat orientationMultiplier = [self orientationMultiplier];
        
        //If the view is actually minimized, set up the view accordingly.
        //Set up the view in a different way if the media player is minimized.
        if (minimized)
        {
            //Initialize the media player's width and height values.
            CGFloat mpWidth = self.playerView.frame.size.width / orientationMultiplier;
            CGFloat mpHeight = self.playerView.frame.size.height / orientationMultiplier;
            
            //Initialize the media player's X and Y values.
            CGFloat x = self.view.bounds.size.width-mpWidth - 20;
            CGFloat y = self.view.bounds.size.height-mpHeight - 20;
            
            //Initialize the 'tallContainerFrame' frame.
            tallContainerFrame = CGRectMake(0, self.view.frame.size.height,
                                            self.detailsView.frame.size.width, self.detailsView.frame.size.height);
            
            //Initialize the 'containerFrame' frame.
            containerFrame = CGRectMake(x, y, mpWidth, mpHeight);
            
            //Set the alpha of the tall container.
            tallContainerAlpha = 0.0;
            
            //Stop the search controller from performing any actions, or being active.
            [self.searchController setActive: NO];
            [self.view endEditing:YES];
            
            //Hide the status bar.
            self.statusBarNeeded = NO;
            [self setNeedsStatusBarAppearanceUpdate];
        }
        else
        {
            //Remove the player's wbe view overlay from the super-view.
            [self.playerWebViewOverlay removeFromSuperview];
            
            //Initialize the 'containerFrame' frame.
            containerFrame.origin.x = 0;
            containerFrame.origin.y = 0;
            containerFrame.size.width = self.view.bounds.size.width;
            containerFrame.size.height = containerFrame.size.width / 16 * 9 + 20;
            
            //Initialize the 'tallContainerFrame' frame.
            tallContainerFrame = self.detailsView.frame;
            tallContainerFrame.origin.y = containerFrame.size.height;
            tallContainerAlpha = 1.0;
            
            //Hide the status bar.
            self.statusBarNeeded = NO;
            [self setNeedsStatusBarAppearanceUpdate];
            
            //Hide the navigation bar.
            [[self navigationController] setNavigationBarHidden:YES animated:YES];
        }
        
        //Set the 'duration' NSTimeInterval.
        NSTimeInterval duration = (animated)? 0.2 : 0.0;
        
        //With an animation, set up the maximized view.
        [UIView animateWithDuration:duration animations:^
         {
             //self.youTubePlayer.frame = containerFrame;
             self.playerView.frame = containerFrame;
             self.playerOverlay.frame = containerFrame;
             self.playerWebViewOverlay.frame = containerFrame;
             [self.playerOverlay setUserInteractionEnabled:NO];
             [self.controlView setHidden:NO];
             self.isHidden = NO;
             [self.view bringSubviewToFront:self.controlView];
             //self.playerView.webView.frame = CGRectMake(0, 0, containerFrame.size.width, containerFrame.size.height);
             self.detailsView.frame = tallContainerFrame;
             self.detailsView.alpha = tallContainerAlpha;
         }];
        
        //Hide the navigation bar.
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
        
        //Set the player variables, and load the YouTube video.
        NSDictionary *playerVars = @{
                                     @"playsinline" : @"1",
                                     
                                     
                                     @"autoplay" :@1,
                                     @"showinfo" :@0,
                                     @"controls" :@0,
                                     @"enablejsapi" :@1,
                                     @"modestbranding" :@1,
                                     @"rel": @0,
                                     @"fs": @1,
                                     @"theme" :@"light",
                                     @"disablekb": @0,
                                     @"iv_load_policy": @3,
                                     @"start" :self.timeAsString
                                     };
        
        [self.playerView loadWithVideoId:self.videoID playerVars:playerVars];
        
        //Play the YouTube view.
        [self.playerView playVideo];
    }
    else
    {
        //Remove the player's web view overlay from the super-view.
        [self.playerWebViewOverlay removeFromSuperview];
        
        //Set the player variables, and load the YouTube video.
        NSDictionary *playerVars = @{
                                     @"playsinline" : @"1",
                                     @"autoplay" :@1,
                                     @"showinfo" :@0,
                                     @"controls" :@0,
                                     @"enablejsapi" :@1,
                                     @"modestbranding" :@1,
                                     @"rel": @0,
                                     @"fs": @1,
                                     @"theme" :@"light",
                                     @"disablekb": @0,
                                     @"iv_load_policy": @3,
                                     @"start" :self.timeAsString
                                     };
        
        [self.playerView loadWithVideoId:self.videoID playerVars:playerVars];
        
        //Play the YouTube view.
        [self.playerView playVideo];
        
        //Hide the status bar.
        self.statusBarNeeded = NO;
        [self setNeedsStatusBarAppearanceUpdate];
        
        //NSLog(@"X: %f Y: %f", self.playerView.frame.origin.x, self.playerView.frame.origin.y);
        
        //Do nothing if the media player is minimized.
        if ([self mpIsMinimized] == minimized) return;
        
        //Declare variables for various frames and a float value which will contain information about the view.
        CGRect tallContainerFrame, containerFrame;
        CGFloat tallContainerAlpha;
        
        //Set the orientation multiplier to a float value.
        CGFloat orientationMultiplier = [self orientationMultiplier];
        
        //If the view is actually minimized, set up the view accordingly.
        //Set up the view in a different way if the media player is minimized.
        if (minimized)
        {
            //Initialize the media player's width and height values.
            CGFloat mpWidth = self.playerView.frame.size.width / orientationMultiplier;
            CGFloat mpHeight = self.playerView.frame.size.height / orientationMultiplier;
            
            //Initialize the media player's X and Y values.
            CGFloat x = self.view.bounds.size.width-mpWidth - 20;
            CGFloat y = self.view.bounds.size.height-mpHeight - 20;
            
            //Initialize the 'tallContainerFrame' frame.
            tallContainerFrame = CGRectMake(0, self.view.frame.size.height,
                                            self.detailsView.frame.size.width, self.detailsView.frame.size.height);
            
            //Initialize the 'containerFrame' frame.
            containerFrame = CGRectMake(x, y, mpWidth, mpHeight);
            
            //Set the alpha of the tall container.
            tallContainerAlpha = 0.0;
            
            //Stop the search controller from performing any actions, or being active.
            [self.searchController setActive:NO];
            [self.view endEditing:YES];
            
            
            //Hie the status bar.
            self.statusBarNeeded = NO;
            [self setNeedsStatusBarAppearanceUpdate];
        }
        else
        {
            //Remove the player's web view overlay from the super-view.
            [self.playerWebViewOverlay removeFromSuperview];
            
            //Initialize the 'containerFrame' frame.
            containerFrame.origin.x = 0;
            containerFrame.origin.y = 0;
            containerFrame.size.width = self.view.bounds.size.width;
            containerFrame.size.height = containerFrame.size.width / 16 * 9 + 20;
            
            //Initialize the 'tallContainerFrame' frame.
            tallContainerFrame = self.detailsView.frame;
            tallContainerFrame.origin.y = containerFrame.size.height;
            tallContainerAlpha = 1.0;
            
            //Hide the status bar.
            self.statusBarNeeded = NO;
            [self setNeedsStatusBarAppearanceUpdate];
            
            //Hide the navigation bar.
            [[self navigationController] setNavigationBarHidden:YES animated:YES];
        }
        
        //Set the 'duration' NSTimeInterval.
        NSTimeInterval duration = (animated)? 0.2 : 0.0;
        
        //With an animation, set up the minimized view.
        [UIView animateWithDuration:duration animations:^
         {
             //self.youTubePlayer.frame = containerFrame;
             self.playerView.frame = containerFrame;
             self.playerOverlay.frame = containerFrame;
             self.playerWebViewOverlay.frame = containerFrame;
             [self.playerOverlay setUserInteractionEnabled:NO];
             [self.view bringSubviewToFront:self.controlView];
             [self.controlView setAlpha:0];
             self.isHidden = YES;
             //self.playerView.webView.frame = CGRectMake(0, 0, containerFrame.size.width, containerFrame.size.height);
             self.detailsView.frame = tallContainerFrame;
             self.detailsView.alpha = tallContainerAlpha;
         }];
    }
}

#pragma mark Search Methods

///Perform actions upon the search icon being tapped.
- (void)searchIconButtonClicked
{
    /*
     if (self.searchController.active || (self.videoTableView.contentOffset.y < 44))
     {
     if (self.searchController.active)
     {
     self.searchController.searchBar.text = nil;
     [self.searchController setActive:YES];
     /[self.videoTableView reloadData];
     }
     [self hideSearchBar];
     }
     else
     {
     [self.videoTableView scrollRectToVisible:CGRectMake(100, 0, 1, 1) animated:YES];
     //CGRect searchBarFrame = self.searchController.searchBar.frame;
     //[self.tableView scrollRectToVisible:searchBarFrame animated:NO];
     }
     */
    
    //If the search controller is active, deactivate it.
    //Ohterwise, activate it, and set its frame in the view.
    if (self.searchController.isActive)
        [self.searchController setActive: NO];
    else
    {
        CGRect searchBarFrame = self.searchController.searchBar.frame;
        [self.videoTableView scrollRectToVisible:searchBarFrame animated:NO];
        [self.searchController setActive: YES];
    }
}

///Perform actions upon the YouTube player becoming ready to play the video.
- (void)playerViewDidBecomeReady:(YTPlayerView *)playerView
{
    //Play the YouTube video.
    [self.playerView playVideo];
}

///Perform actions upon the search bar's cancel button being tapped.
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    //Stop the search controller from performing any actions, or being active.
    [self.view endEditing:YES];
    //[self.searchController setActive: NO];
}

#pragma mark Other Methods

///Boolean value that tells the view controller whether or not it perfers to have the status bar hidden, when possible.
- (BOOL)prefersStatusBarHidden
{
    //Return a value based on the status of the status bar.
    return !self.statusBarNeeded;
    return self.navigationController.isNavigationBarHidden;
}

///Perform actions to hide the search bar.
- (void)hideSearchBar
{
    //NSLog(@"Hiding SearchBar");
    //[self.videoTableView setContentOffset:CGPointMake(0,44)];
    
    //With an animation, hide the search bar by setting its frame.
    [UIView animateWithDuration:0.5 animations:^
     {
         /*
          CGRect rect = self.searchController.searchBar.frame;
          rect.size.height = 0;
          self.searchController.searchBar.frame = rect;
          self.searchController.searchBar.alpha = 0.0;
          */
         
         CGRect rect2 = self.videoTableView.frame;
         rect2.origin.y = -44;
         self.videoTableView.frame = rect2;
     }];
}

///Perform actions upon the view going back to the default 'popular videos' page.
-(void)backToPopular
{
    //Disable the left bar button item on the navigation bar.
    [self.navigationItem.leftBarButtonItem setEnabled:NO];
    
    //Set the isSearch boolean value.
    self.isSearch = NO;
    
    //Set the navigation bar's title.
    [self.navigationItem setTitle:@"Featured"];
    
    //Reload the table view.
    [self.videoTableView reloadData];
}

//Perform actions upon the favorites button being tapped.
- (IBAction)favoriteButton:(id)sender
{
    //If the current video is found, remove it from favorites.
    //Otherwise, favorite the current video.
    if ([self.favoritesArray indexOfObject:self.videoTitle.text] != NSNotFound && [self.favoritesLinkArray indexOfObject:self.videoID] != NSNotFound && [self.favoritesIndexPathArray indexOfObject:self.indexPathForFavorite] != NSNotFound)
    {
        //NSLog(@"'%@', with a last recorded time of '%@' has now been removed from favorites.", self.videoTitle.text, self.timeAsString);
        
        //Set the fromFavorite boolean value.
        self.fromFavorite = NO;
        
        //Set the image of the favorite button.
        //UIImage *image = [UIImage imageNamed:@"Star-50.png"];
        //[self.favoriteButton setImage:image forState:UIControlStateNormal];
        
        //Remove some of the current video's attributes from the arrays in which they were previously contained.
        [self.favoritesArray removeObject:self.videoTitle.text];
        [self.favoritesLinkArray removeObject:self.videoID];
        [self.favoritesIndexPathArray removeObject:self.indexPathForFavorite];
        
        //Set the hasBeenPressed boolean value.
        self.hasBeenPressed = NO;
        
        //Reload the table view.
        [self.videoTableView reloadData];
    }
    else if ([self.favoritesArray indexOfObject:self.videoTitle.text] == NSNotFound && [self.favoritesLinkArray indexOfObject:self.videoID] == NSNotFound && [self.favoritesIndexPathArray indexOfObject:self.indexPathForFavorite] == NSNotFound)
    {
        //Record the current video's time.
        self.videoTime = self.playerView.currentTime;
        self.timeAsString = [[NSNumber numberWithFloat:self.videoTime] stringValue];
        
        //Convert the float value to an integer value, perhaps a bit unconventionally.
        //If there is no decimal value in the float, and the time string does not exist, set it to a placeholder value of '0'.
        //Otherwise, remove the decimal value from the float, and convert it to an integer.
        if ([self.timeAsString rangeOfString:@"."].location == NSNotFound)
        {
            self.timeAsString = self.timeAsString;
        }
        else if (self.timeAsString == nil)
        {
            self.timeAsString = @"0";
        }
        else
        {
            NSString *subString = [self.timeAsString substringWithRange: NSMakeRange(0, [self.timeAsString rangeOfString: @"."].location)];
            self.timeAsString = subString;
        }
        
        //NSLog(@"'%@', with a current time of '%@', is now favorited.", self.videoTitle.text, self.timeAsString);
        
        //Set the fromFavorite boolean value.
        self.fromFavorite = YES;
        
        //Set the image of the favorite button.
        //UIImage *image = [UIImage imageNamed:@"Star Filled-50.png"];
        //[self.favoriteButton setImage:image forState:UIControlStateNormal];
        
        //Add some of the current video's attributes to the arrays in which they will now be contained.
        [self.favoritesArray addObject:self.videoTitle.text];
        [self.favoritesLinkArray addObject:self.videoID];
        [self.favoritesTimeArray addObject:self.timeAsString];
        [self.favoritesIndexPathArray addObject:self.indexPathForFavorite];
        
        //Set the hasBeenPressed boolean value.
        self.hasBeenPressed = YES;
        
        //Reload the table view.
        [self.videoTableView reloadData];
    }
    else
    {
        //NSLog(@"'%@', with a last recorded time of '%@' has now been removed from favorites.", self.videoTitle.text, self.timeAsString);
        
        //Set the fromFavorite boolean value.
        //self.fromFavorite = NO;
        
        //Set the image of the favorite button.
        //UIImage *image = [UIImage imageNamed:@"Star-50.png"];
        //[self.favoriteButton setImage:image forState:UIControlStateNormal];
        
        //Remove some of the current video's attributes from the arrays in which they were previously contained.
        [self.favoritesArray removeObject:self.videoTitle.text];
        [self.favoritesLinkArray removeObject:self.videoID];
        [self.favoritesTimeArray removeObject:self.timeAsString];
        [self.favoritesIndexPathArray removeObject:self.indexPathForFavorite];
        
        //Set the hasBeenPressed boolean value.
        self.hasBeenPressed = NO;
        
        //Reload the table view.
        [self.videoTableView reloadData];
    }
    
}

///Boolean value that performs various actions when the search bar ends editing.
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    //Increase the endedCount integer value by one.
    self.endedCount++;
    
    //If the endedCount integer value is greater than three, perform various actions upon the end of the search bar's editing.
    if (self.endedCount > 3)
    {
        //NSLog(@"The search bar, with text of '%@', has ended editing.", self.searchController.searchBar.text);
        
        //Set the searchBarString string to the text of the search controller's search bar.
        NSString *searchBarString = self.searchController.searchBar.text;
        
        //Stop the search controller from performing any actions, or being active.
        [self.searchController setActive: NO];
        [self.view endEditing:YES];
        
        //Set the text of ths search controller's search bar to the searchBarString string.
        [self.searchController.searchBar setText:searchBarString];
        
        //Reset the endedCount integer value.
        self.endedCount = 0;
    }
    
    return YES;
}

//Perform actions when the player has been tapped on.
- (IBAction)tapPlayerGestureRecognizer:(id)sender
{
    //If the player's view is not hidden, and it is not buffering, either, perform various actions.
    //Otherwise. if the player is hidden, and it is not buffering, either, perform various actions.
    if (self.isHidden == NO && self.isBuffering == NO)
    {
        //If the player is playing or it is paused, perform various actions.
        if (self.isPlaying == YES || self.isPaused == YES)
        {
            //With an animation, hide the player controls.
            [UIView animateWithDuration:0.3 animations:^
             {
                 self.controlView.alpha = 0;
                 
             } completion: ^(BOOL finished)
             {
                 [self.controlView setUserInteractionEnabled:NO];
                 self.isHidden = YES;
             }];
        }
    }
    else if (self.isHidden == YES && self.isBuffering == NO)
    {
        //If the player is playing or it is paused, perform various actions.
        if (self.isPlaying == YES || self.isPaused == YES)
        {
            //With an animation, show the player's controls, if the device is not in landscape orientation mode.
            [UIView animateWithDuration:0.3 animations:^
             {
                 if (self.isLandscape == NO)
                 {
                     self.controlView.alpha = 0.55;
                 }
                 
             } completion: ^(BOOL finished)
             {
                 if (self.isLandscape == NO)
                 {
                     [self.controlView setUserInteractionEnabled:YES];
                     self.isHidden = NO;
                     [self.hideControlTimer invalidate];
                     self.hideControlTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                              target:self
                                                                            selector:@selector(hideControls)
                                                                            userInfo:nil
                                                                             repeats:NO];
                 }
                 
             }];
        }
    }
}

///Boolean value telling the view controller whether or not it should allow gesture recognizers to act upon touches on the view.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

///Boolean value telling the view controller whether or not it should allow gesture recognizers to act upon multiple touches on the view.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#warning Not sure what this does.
- (void)getTime
{
    //NSLog(@"Button has been pressed.");
    [self tableView:self.videoTableView didSelectRowAtIndexPath:self.indexPathForFavorite];
}

///Function to set up various aspects of the player controls.
- (void)dealWithTimer
{
    if (self.isLandscape == NO)
    {
        //Initialize the videoTimer timer.
        self.videoTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(updateTime)
                                                         userInfo:nil
                                                          repeats:YES];
        
        //Set the maximum valur of the time slider to the amount of seconds in the current YouTube video.
        self.timeSlider.maximumValue = self.unformattedVideoTime;
        
        //Set the tint color of the thumb on the slider to clear, as a means of hiding it.
        self.timeSlider.thumbTintColor = [UIColor clearColor];
    }
}

///Function to hide the player controls.
- (void)hideControls
{
    //If the player's view is not hidden, the video is not buffering, it is playing, and it is not paused, perform various actions.
    if (self.isHidden == NO && self.isBuffering == NO && self.isPlaying == YES && self.isPaused == NO)
    {
        //With an animation, hide the player controls.
        [UIView animateWithDuration:0.3 animations:^
         {
             self.controlView.alpha = 0;
             
         } completion: ^(BOOL finished)
         {
             [self.controlView setUserInteractionEnabled:NO];
             self.isHidden = YES;
         }];
    }
}

///Function to be called when the 'videoTimer' timer is called and runs.
- (void)updateTime
{
    //If the YouTube video is playing, perform various actions.
    if (self.isPlaying == YES)
    {
        //NSLog(@"Current Video Time: '%f'.", self.playerView.currentTime);
        
        //With an animation, update the video's time slider value to the amount of seconds the video has been running.
        [UIView animateWithDuration:1.0 animations:^
         {
             //Set the video's time slider value to the amount of seconds that the video has been running or scrubbed to.
             self.timeSlider.value = self.playerView.currentTime;
             
             //Define the 'remainingTimeTemp' float value as the whole video's time in seconds minus the current video time.
             float remainingTimeTemp = self.unformattedVideoTime - self.playerView.currentTime;
             
             //Set the remainingTime value to the previously defined float value.
             self.remainingTime = remainingTimeTemp;
             
             
             //NSLog(@"Remaining Time: '%f'.", self.remainingTime);
             
             //If the 'hideControlTimer' is not valid, validate it by declaring a new instance of it.
             if (![self.hideControlTimer isValid])
             {
                 //Validate the 'hideControlTimer' by declaring a new instance of it.
                 self.hideControlTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                          target:self
                                                                        selector:@selector(hideControls)
                                                                        userInfo:nil
                                                                         repeats:NO];
             }
             
             //Declare integers for total video time and current video time.
             int formatInt = (int)roundf(self.remainingTime);
             int seconds = formatInt % 60;
             int minutes = (formatInt / 60) % 60;
             
             int currentFormatInt = (int)roundf(self.playerView.currentTime);
             int currentSeconds = currentFormatInt % 60;
             int currentMinutes = (currentFormatInt / 60) % 60;
             
             //If the 'formatInt' integer is greater than or equal to 3600, (the amount of seconds in an hour), set up the text on the view to include this value.
             //Otherwise, if the 'formatInt' integer is less than 3600, (the amount of seconds in an hour), set up the text on the view not to include this value.
             if (formatInt >= 3600)
             {
                 //Set up the text to be displayed on the view, which will comprise the amount of time currently remaining in the video.
                 int hours = formatInt / 3600;
                 int currentHours = currentFormatInt / 3600;
                 NSString *finalString = [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
                 NSString *trimmedString = [finalString stringByReplacingOccurrencesOfString:@" " withString:@""];
                 NSString *realFinalString = [@"-" stringByAppendingString:trimmedString];
                 
                 NSString *currentFinalString = [NSString stringWithFormat:@"%02d:%02d:%02d",currentHours, currentMinutes, currentSeconds];
                 NSString *currentTrimmedString = [currentFinalString stringByReplacingOccurrencesOfString:@" " withString:@""];
                 
                 //NSLog(@"Formatted Remaining Time: '%@'.", realFinalString);
                 
                 [self.timeRemainingLabel setText:realFinalString];
                 [self.currentTimeLabel setText:currentTrimmedString];
             }
             else
             {
                 //Set up the text to be displayed on the view, which will comprise the amount of time currently remaining in the video.
                 NSString *finalString = [NSString stringWithFormat:@"%2d:%02d", minutes, seconds];
                 NSString *trimmedString = [finalString stringByReplacingOccurrencesOfString:@" " withString:@""];
                 NSString *realFinalString = [@"-" stringByAppendingString:trimmedString];
                 
                 NSString *currentFinalString = [NSString stringWithFormat:@"%2d:%02d", currentMinutes, currentSeconds];
                 NSString *currentTrimmedString = [currentFinalString stringByReplacingOccurrencesOfString:@" " withString:@""];
                 
                 //NSLog(@"Formatted Remaining Time: '%@'.", realFinalString);
                 
                 [self.timeRemainingLabel setText:realFinalString];
                 [self.currentTimeLabel setText:currentTrimmedString];
             }
         }];
    }
}

///Function to perform actions on the state change of the YouTube video's player.
- (void)playerView:(YTPlayerView *)playerView didChangeToState:(YTPlayerState)state
{
    switch (state)
    {
            //Perform actions upon the player (re)starting playback.
        case kYTPlayerStatePlaying:
            
            NSLog(@"Playback has started.");
            
            //Call the setControls function.
            [self setControls];
            
            //If the media player has been removed from the view, stop the video, as it should not be playing (any longer).
            //Otherwise, if the player is not removed from the view, perform various actions.
            if (self.mpRemoved == YES)
            {
                //Halt the video's playback.
                [self.playerView stopVideo];
                
                NSLog(@"A video which was removed has been halted from playing in the playing state method.");
            }
            else
            {
                //If the media player is not minimized, show the player controls.
                if (![self mpIsMinimized])
                {
                    //With an animation, show the player controls.
                    [UIView animateWithDuration:0.5 animations:^
                     {
                         if (self.isLandscape == NO)
                         {
                             self.controlView.alpha = 0.55;
                         }
                         
                     } completion: ^(BOOL finished)
                     {
                         if (self.isLandscape == NO)
                         {
                             [self.controlView setUserInteractionEnabled:YES];
                             self.isHidden = NO;
                         }
                     }];
                }
                
                //Set various boolean values.
                self.isPlaying = YES;
                self.isBuffering = NO;
                self.isPaused = NO;
                
                //Hide the play button, unhide the pause button, add a control event method to the slier, and run the function 'dealWithTimer'.
                [self.playButton setHidden:YES];
                [self.pauseButton setHidden:NO];
                [self.timeSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
                [self dealWithTimer];
            }
            
            break;
            
            //Perform actions upon the player pausing playback.
        case kYTPlayerStatePaused:
            
            NSLog(@"Playback has been paused.");
            
            //Invalidate the 'hideControlTimer' timer, which would wait five seconds before hiding the player controls.
            [self.hideControlTimer invalidate];
            
            //Set various boolean values.
            self.isPlaying = NO;
            self.isPaused = YES;
            
            //Unhide the play button, and hide the pause button.
            [self.playButton setHidden:NO];
            [self.pauseButton setHidden:YES];
            
            break;
            
            //Perform actions upon the player buffering.
        case kYTPlayerStateBuffering:
            
            NSLog(@"Player is currently buffering.");
            
            //Call the setControls function.
            [self setControls];
            
            //If the media player has been removed from the view, stop the video, as it should not be buffering (any longer).
            if (self.mpRemoved == YES)
            {
                //Halt the video's playback.
                [self.playerView stopVideo];
                
                NSLog(@"A video which was removed has been halted from buffering in the buffering state method.");
            }
            
            //Set the isBuffering boolean value.
            self.isBuffering = YES;
            
            break;
            
            //Perform actions upon playback of the video ending.
        case kYTPlayerStateEnded:
            
            NSLog(@"Video playback has ended.");
            
            break;
            
            //Perform actions when playback of the vidoe has not yet started.
        case kYTPlayerStateUnstarted:
            
            //If the media player is not removed from the view and it is not minimized, set up the view for an alternate display method, as the video most likely is protected from playback on/in other applications.
            if (!self.mpRemoved == YES && ![self mpIsMinimized])
            {
                NSLog(@"The video is most likely disabled. Setting view up for alternate display method.");
                
                //Call the 'setUpViewForAlternateDisplay' function, which sets up the view for an alternate display method, as the video most likely is protected from playback on/in other applications.
                [self setUpViewForAlternateDisplay];
            }
            
            break;
            
            //The default value for a player state change.
        default:
            
            break;
    }
}

///Function that sets up the view for an alternate video display method, as the current video most likely is protected from playback on/in other applications.
- (void)setUpViewForAlternateDisplay
{
    //Set the calledOnce boolean value.
    //self.calledOnce = NO;
    
    //If the modified playback alert has not been shown before, and the user has not asked for it not to be displayed in the future, display the alert.
    if (self.noShowAgain == NO && self.hasShown == NO)
    {
        UIAlertView *modifiedPlaybackAlert = [[UIAlertView alloc] initWithTitle:@"Modified Playback" message:@"Due to contraints regarding YouTube's playback policy, this video will play differently than others, and may display an advertisement." delegate:self cancelButtonTitle:@"Don't Show Again" otherButtonTitles:@"OK", nil];
        [modifiedPlaybackAlert show];
    }
    
    //If the player's web view overlay is not on the superview, add it.
    //Otherwise, log it's current frame.
    if (!self.playerWebViewOverlay.superview)
    {
        //If the device is an iPhone 4s/4/3GS/3G, set the detail view to a different frame.
        //Otherwise, treat the device as if it is an iPhone 6 Plus, and set up the detail view accordingly.
        if (self.view.frame.size.width == 320)
        {
            //Add the player's web view overlay to the superview.
            self.playerWebViewOverlay = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 252.875)];
        }
        else if (self.view.frame.size.width == 414)
        {
            //Add the player's web view overlay to the superview.
            self.playerWebViewOverlay = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 414, 252.875)];
        }
        
        [self.view addSubview:self.playerWebViewOverlay];
        
        //NSLog(@"Frame of webView: '%@'.", NSStringFromCGRect(self.playerWebViewOverlay.frame));
    }
    else
    {
        //NSLog(@"Frame of webView: '%@'.", NSStringFromCGRect(self.playerWebViewOverlay.frame));
    }
    
    //Hide and disable multiple aspects of the video's playback.
    [self.playerView setHidden:YES];
    [self.playerView setUserInteractionEnabled:NO];
    [self.playerView setAlpha:0];
    
    [self.playerOverlay setHidden:YES];
    [self.playerOverlay setUserInteractionEnabled:NO];
    [self.playerOverlay setAlpha:0];
    
    [self.playerWebViewOverlay setHidden:NO];
    [self.playerWebViewOverlay setUserInteractionEnabled:YES];
    [self.playerWebViewOverlay setAlpha:1];
    
    
    //Add a gesture recognizer to the player's web view overlay to detect when the user swipes down on it.
    UISwipeGestureRecognizer *swipeDownForWebView = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDownForWebView)];
    [swipeDownForWebView setDelegate:self];
    [swipeDownForWebView setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.playerWebViewOverlay addGestureRecognizer:swipeDownForWebView];
    
    //Set the delegate of the player's web view overlay.
    [self.playerWebViewOverlay setDelegate:self];
    
    //Load the YouTube video into the player's web view overlay.
    NSString *stringForURL = [NSString stringWithFormat:@"https://m.youtube.com/watch?v=%@#", self.videoID];
    NSURL *url = [NSURL URLWithString:stringForURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.playerWebViewOverlay setScalesPageToFit:YES];
    [self.playerWebViewOverlay loadRequest:request];
    
    //Initialize and set the frame of the detail view.
    //CGRect playerViewRect = self.playerView.frame;
    //playerViewRect.size.height = playerViewRect.size.width / 16 * 9 + 20;
    //
    //CGRect detailsViewRect = self.detailsView.frame;
    //detailsViewRect.origin.x = 0;
    //detailsViewRect.origin.y = playerViewRect.size.height - 99;
    //detailsViewRect.size.height = self.detailsView.frame.size.height + 99;
    //[self.detailsView setFrame:detailsViewRect];
    
    //With an animation, set the frame of the detail view.
    [UIView animateWithDuration:0.5 animations:^
     {
         //If the device is an iPhone 4s/4/3GS/3G, set the detail view to a different frame.
         //Otherwise, treat the device as if it is an iPhone 6 Plus, and set up the detail view accordingly.
         if (self.view.frame.size.width == 320)
         {
             if (self.view.frame.size.height == 568)
             {
                 //Set the frame of the detail view.
                 [self.detailsView setFrame:CGRectMake(0, 153.875, 320, 430)];
             }
             else
             {
                 //Set the frame of the detail view.
                 [self.detailsView setFrame:CGRectMake(0, 153.875, 320, 330)];
             }
         }
         else if (self.view.frame.size.width == 375)
         {
             [self.detailsView setFrame:CGRectMake(0, 153.875, 375, 515)];
         }
         else if (self.view.frame.size.width == 414)
         {
             //Set the frame of the detail view.
             [self.detailsView setFrame:CGRectMake(0, 153.875, 414, 582.125)];
         }
     }];
    
    //Set the alpha of the detail view.
    self.detailsView.alpha = 1.0;
    
    //Bring thre detail view to the front of the view.
    [self.view bringSubviewToFront:self.detailsView];
    
    //Reload the player's web view (overlay).
    [self.playerWebViewOverlay loadRequest:request];
}

///Function that determines whether the player controls should be on the view, and sets up the view accordingly.
- (void)setControls
{
    //Return the status of the device's orientation.
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    //If the device's orientation is in portrait mode, set the isLandscape boolean value.
    //Otherwise, perform various actions.
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        self.isLandscape = NO;
    }
    
    else
    {
        //Hide the player controls.
        [self.controlView setUserInteractionEnabled:NO];
        [self.controlView setAlpha:0];
        
        //Hide the player overlay.
        [self.playerOverlay setHidden:YES];
        [self.playerOverlay setUserInteractionEnabled:NO];
        [self.playerOverlay setAlpha:0];
        
        //Set various boolean values.
        self.isHidden = YES;
        self.isLandscape = YES;
    }
}

///Function that calls for the view to be reset when the player's web view overlay is swiped down upon.
- (void)swipeDownForWebView
{
    //NSLog(@"Swipe down for web view method called!");
    
    //Reset the view, subsequently setting it up for a regular video to be displayed upon it.
    [self resetView];
}

///Function that resets the view subsequently setting it up for a regular video to be displayed on it.
- (void)resetView
{
    //With an animation, set the frame of the detail view.
    [UIView animateWithDuration:0.5 animations:^
     {
         //If the device is an iPhone 4s/4/3GS/3G, set the detail view to a different frame.
         //Otherwise, treat the device as if it is an iPhone 6 Plus, and set up the detail view accordingly.
         if (self.view.frame.size.width == 320)
         {
             if (self.view.frame.size.height == 568)
             {
                 [self.detailsView setFrame:CGRectMake(0, 252.875, 320, 369.125)];
             }
             else
             {
                 [self.detailsView setFrame:CGRectMake(0, 252.875, 320, 281.125)];
             }
         }
         else if (self.view.frame.size.width == 414)
         {
             //Set the frame of the detail view.
             [self.detailsView setFrame:CGRectMake(0, 252.875, 414, 481.125)];
         }
     }];
    
    
    //Unhide and enable multiple aspects of the video's playback.
    [self.playerView setHidden:NO];
    [self.playerView setUserInteractionEnabled:YES];
    [self.playerView setAlpha:1];
    
    [self.playerOverlay setHidden:NO];
    [self.playerOverlay setUserInteractionEnabled:NO];
    [self.playerOverlay setAlpha:1];
    
    [self.playerWebViewOverlay setHidden:YES];
    [self.playerWebViewOverlay setUserInteractionEnabled:NO];
    [self.playerWebViewOverlay setAlpha:0];
    [self.playerWebViewOverlay setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    
    
    //Hide the detail view.
    [self.detailsView setHidden:YES];
    
    //Initialize and set the frame of the detail view.
    //CGRect playerViewRect = self.playerView.frame;
    //playerViewRect.size.height = playerViewRect.size.width / 16 * 9 + 20;
    //
    //CGRect detailsViewRect = self.detailsView.frame;
    //detailsViewRect.origin.x = 0;
    //detailsViewRect.origin.y = playerViewRect.size.height;
    //detailsViewRect.size.height = self.detailsView.frame.size.height - 100;
    //[self.detailsView setFrame:detailsViewRect];
    
    //Set the alpha of the detail view.
    self.detailsView.alpha = 1.0;
    
    //Bring both the detail view and the player view to the front of the view.
    [self.view bringSubviewToFront:self.detailsView];
    [self.view bringSubviewToFront:self.playerView];
    
    //Set the video time to the YouTube video's current time.
    self.videoTime = self.playerView.currentTime;
    
    //Set the time as a string to the string value of the NSNumber value of the float value of the video time.
    self.timeAsString = [[NSNumber numberWithFloat:self.videoTime] stringValue];
    
    //If the time as a string does not contain a decimal, (meaning it is an integer and not a float value), set it to itself?
    //Otherwise, convert the float value to an integer value, perhaps a bit unconventionally, and set the converted value as a string to the time as a string value.
#warning Weird Code.
    if ([self.timeAsString rangeOfString:@"."].location == NSNotFound)
    {
        self.timeAsString = self.timeAsString;
    }
    else
    {
        NSString *subString = [self.timeAsString substringWithRange: NSMakeRange(0, [self.timeAsString rangeOfString: @"."].location)];
        self.timeAsString = subString;
    }
    
    //If the device is an iPhone 4s/4/3GS/3G, set the detail view to a different frame.
    //Otherwise, treat the device as if it is an iPhone 6 Plus, and set up the detail view accordingly.
    if (self.view.frame.size.width == 320)
    {
        if (self.view.frame.size.height == 568)
        {
            [self.detailsView setFrame:CGRectMake(0, 252.875, 320, 369.125)];
        }
        else
        {
            [self.detailsView setFrame:CGRectMake(0, 252.875, 320, 281.125)];
        }
    }
    else if (self.view.frame.size.width == 414)
    {
        //Set the frame of the detail view.
        [self.detailsView setFrame:CGRectMake(0, 252.875, 414, 481.125)];
    }
    
    //Minimize the player's view.
    [self minimizeMp:YES animated:YES];
}

///Function that performs various actions upon the tapping of a button on a UIAlertView.
- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //If the cancel button's index was tapped or called on the UIAlertView, perform various actions.
    if (buttonIndex == [alertView cancelButtonIndex])
    {
        //Set the NSUSerDefaults to symbolize that the user has selected for the playback warning not to be displayed again.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:1 forKey:@"noShowAgain"];
        [defaults synchronize];
    }
    else
    {
        //Set the NSUSerDefaults to symbolize that the user has not selected for the playback warning not to be displayed again.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:0 forKey:@"noShowAgain"];
        [defaults synchronize];
    }
    
    //Set the hasShown boolean value.
    self.hasShown = YES;
}


///Function to handle when a UISlider's value has changed because of user action.
- (void)sliderValueChanged:(UISlider *)sender
{
    //Seek the YouTube video to the UISlider's value.
    [self.playerView seekToSeconds:sender.value allowSeekAhead:YES];
}

///Function that performs actions when either the play or pause buttons are pressed.
- (IBAction)buttonPressed:(id)sender
{
    //If the sender of the button press was the play button, play the video.
    //If it was the pause button, pause the video.
    if (sender == self.playButton)
    {
        //Post a playback started notification.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Playback started" object:self];
        
        //Play the video.
        [self.playerView playVideo];
        //}
        //else if (sender == self.stopButton)
        //{
        //  [self.playerView stopVideo];
        //}
        
    }
    else if (sender == self.pauseButton)
    {
        //Pause the video's playback.
        [self.playerView pauseVideo];
        
        [self.playerView.webView stringByEvaluatingJavaScriptFromString:@"player.pauseVideo();"];
    }
    /*
     else if (sender == self.reverseButton)
     {
     float seekToTime = self.playerView.currentTime - 30.0;
     [self.playerView seekToSeconds:seekToTime allowSeekAhead:YES];
     [self appendStatusText:[NSString stringWithFormat:@"Seeking to time: %.0f seconds\n", seekToTime]];
     }
     else if (sender == self.forwardButton)
     {
     float seekToTime = self.playerView.currentTime + 30.0;
     [self.playerView seekToSeconds:seekToTime allowSeekAhead:YES];
     [self appendStatusText:[NSString stringWithFormat:@"Seeking to time: %.0f seconds\n", seekToTime]];
     }
     else if (sender == self.startButton)
     {
     [self.playerView seekToSeconds:0 allowSeekAhead:YES];
     [self appendStatusText:@"Seeking to beginning\n"];
     }
     */
}

@end
