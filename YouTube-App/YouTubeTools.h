//
//  YouTubeTools.h
//  Prodigus II
//
//  Created by Grant Goodman on 6/3/15.
//  Copyright © 2015 Macster Software Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
@class YouTubeVideo;

@interface YouTubeTools : NSObject

+ (NSString *) developerKey;

// methods to return list of video
+ (NSMutableArray *) popularVideoArrayWithMaxResults:(NSString *) maxResults
                               withCompletitionBlock:(void (^)() ) reloadData;


+ (NSMutableArray *) findVideoArrayWithString:(NSString *) string
                                   maxResults:(NSString *) maxResults
                        withCompletitionBlock:(void (^)() ) reloadData;

//+ (RACSignal*)detailedVideoInfoForId: (NSString *) videoId;
//+ (YouTubeVideo *) detailedVideoInfoForId: (NSString *) videoId;
@end
