//
//  YouTubeVideo.h
//  Prodigus II
//
//  Created by Grant Goodman on 6/3/15.
//  Copyright © 2015 Macster Software Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YouTubeVideo : NSObject


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                                  Strings                                                        */


/*! A string that specifies the title of a channel. */
@property (strong, nonatomic) NSString *channelTitle;
/*! A string that specifies the amount of comments on a video. */
@property (strong, nonatomic) NSString *commentCount;
/*! A string that specifies the amount of dislikes on a video. */
@property (strong, nonatomic) NSString *dislikesCount;
/*! A string that specifies the duration of a video. */
@property (strong, nonatomic) NSString *duration;
/*! A string that specifies the amount of likes on a video. */
@property (strong, nonatomic) NSString *likesCount;
/*! A string that specifies the date that a video was published. */
@property (strong, nonatomic) NSString *publishedAt;
/*! A string that specifies the URL of a video's thumbnail. */
@property (strong, nonatomic) NSString *previewUrl;
/*! A string that specifies the title of a video. */
@property (strong, nonatomic) NSString *title;
/*! A string that specifies the unformatted duration, (duration in seconds), of a video. */
@property (strong, nonatomic) NSString *unformattedDuration;
/*! A string that specifies the description of a video. */
@property (strong, nonatomic) NSString *videoDescription;
/*! A string that specifies the identifier of a video. */
@property (strong, nonatomic) NSString *videoID;
/*! A string that specifies the amount of views on a video. */
@property (strong, nonatomic) NSString *viewsCount;


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                Other Non-Interface Builder Elements                                             */

/*! An integer that describes how a list of videos should be sorted. */
@property int sortID;


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


/*                                                            Method Definitions												   */

/*! A function that logs most of the current video's information to the console. */
- (void)testPrint;


 //-//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//--//-//


@end

