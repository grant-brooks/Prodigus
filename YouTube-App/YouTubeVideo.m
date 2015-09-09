//
//  YouTubeVideo.m
//  Prodigus II
//
//  Created by Grant Goodman on 6/3/15.
//  Copyright © 2015 Macster Software Corporation. All rights reserved.
//

#import "YouTubeVideo.h"

@implementation YouTubeVideo

///Function that logs most of the current video's information to the console.
- (void)testPrint
{
    NSLog(@"1) %@\n2) %@\n3) %@\n4) %@\n5) %@\n6) %@\n7) %@\n8) %@\n9) %@\n10) %@\n", self.title, self.videoDescription, self.previewUrl, self.videoID, self.publishedAt, self.duration, self.viewsCount, self.likesCount, self.dislikesCount, self.commentCount);
}

@end
