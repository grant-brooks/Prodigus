//
//  YouTubeTools.m
//  Prodigus II
//
//  Created by Grant Goodman on 6/3/15.
//  Copyright © 2015 Macster Software Corporation. All rights reserved.
//

#import "YouTubeTools.h"
#import "YouTubeVideo.h"
#import "AFNetworking.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation YouTubeTools

+ (NSString *) developerKey
{
    // iOS
    //return @"AIzaSyAmxl1yiU1wRRmn8-_jUTLaurqhWHYmmxs";
    // browser
    return @"AIzaSyBuNCktvI83aYxu10pbqD45wB7KTbP2P60";
}

+ (NSMutableArray *) popularVideoArrayWithMaxResults:(NSString *) maxResults
                               withCompletitionBlock:(void (^)() )reloadData;
{
    // getting json from YouTube API
    NSString *playlistID = @"PLrEnWoR732-BHrPp_Pm8_VleD68f9s14-";
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlistItems?part=snippet%%2CcontentDetails&maxResults=%@&playlistId=%@&fields=items%%2Fsnippet&key=%@", maxResults, playlistID, [self developerKey]];
    //NSLog(@"URL String: '%@'.", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableArray *videoList = [[NSMutableArray alloc] init];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary *items = [responseObject objectForKey:@"items"];
         
         int count = 0;
         for (NSDictionary *item in items )
         {
             NSDictionary* snippet = [item objectForKey:@"snippet"];
             
             __block YouTubeVideo *youTubeVideo = [[YouTubeVideo alloc] init];
             youTubeVideo.sortID = count;
             count+=1;
             NSString *videoID = [[snippet objectForKey:@"resourceId"]objectForKey:@"videoId"];
             [[self responceForDetailedVideoInfoForId:videoID] subscribeNext:^(id detailedResponce)
              {
                  [self detailedVideoInfo:youTubeVideo withJSON:detailedResponce];
                  [videoList addObject:youTubeVideo];
                  
                  if ([videoList count] == [items count])
                  {
                      NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortID"
                                                                                     ascending:YES];
                      NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                      [videoList sortUsingDescriptors:sortDescriptors];
                      reloadData();
                  }
                  
              }];
             
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         
         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Video playlist"
                                                             message:[error localizedDescription]
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
         [alertView show];
     }];
    
    // 5
    [operation start];
    return videoList;
}

// finding
+ (NSMutableArray *) findVideoArrayWithString:(NSString *) string
                                   maxResults:(NSString *) maxResults
                        withCompletitionBlock:(void (^)() ) reloadData;
{
    // getting json from YouTube API
    NSString *searchString = [string stringByReplacingOccurrencesOfString:@" " withString: @"+"];
    
    // converting string to Percent Escapes format
    searchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?part=snippet&q=%@&fields=items%%2Fid&maxResults=%@&type=video&key=%@", searchString, maxResults, [self developerKey]];
    
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableArray *videoList = [[NSMutableArray alloc] init];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary *items = [responseObject objectForKey:@"items"];
         int count = 0;
         for (NSDictionary *item in items )
         {
             __block YouTubeVideo *youTubeVideo = [[YouTubeVideo alloc] init];
             youTubeVideo.sortID = count;
             count+=1;
             NSString *videoID = [[item objectForKey:@"id"] objectForKey:@"videoId"];
             
             [[self responceForDetailedVideoInfoForId:videoID] subscribeNext:^(id detailedResponce)
              {
                  [self detailedVideoInfo:youTubeVideo withJSON:detailedResponce];
                  [videoList addObject:youTubeVideo];
                  
                  if ([videoList count] == [items count])
                  {
                      NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortID"
                                                                                     ascending:YES];
                      NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                      [videoList sortUsingDescriptors:sortDescriptors];
                      reloadData();
                  }
                  
                  if (items.count == 0)
                  {
                      NSLog(@"No results found for '%@'.", searchString);
                      [videoList removeAllObjects];
                      reloadData();
                  }
                  
              }];
             
         }
         
         //[self.tableView reloadData];
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         
         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:[error localizedDescription]
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
         [alertView show];
     }];
    
    // 5
    [operation start];
    return videoList;
}

+ (void) detailedVideoInfo:(YouTubeVideo *)youTubeVideo withJSON:(NSDictionary *)json
{
    
    NSDictionary *items = [json objectForKey:@"items"];
    for (NSDictionary *item in items )
    {
        NSDictionary* snippet = [item objectForKey:@"snippet"];
        NSDictionary* contentDetails = [item objectForKey:@"contentDetails"];
        NSDictionary* statistics = [item objectForKey:@"statistics"];
        
        youTubeVideo.videoID = [item objectForKey:@"id"];
        
        youTubeVideo.title = [snippet objectForKey:@"title"];
        youTubeVideo.videoDescription = [snippet objectForKey:@"description"];
        youTubeVideo.publishedAt = [snippet objectForKey:@"publishedAt"];
        youTubeVideo.channelTitle = [snippet objectForKey:@"channelTitle"];
        if ([[[snippet objectForKey:@"thumbnails"] objectForKey:@"high"] objectForKey:@"url"])
            youTubeVideo.previewUrl = [[[snippet objectForKey:@"thumbnails"] objectForKey:@"high"] objectForKey:@"url"];
        else
            [[[snippet objectForKey:@"thumbnails"] objectForKey:@"medium"] objectForKey:@"url"];
        
        youTubeVideo.viewsCount = [statistics objectForKey:@"viewCount"];
        youTubeVideo.likesCount = [statistics objectForKey:@"likeCount"];
        youTubeVideo.dislikesCount = [statistics objectForKey:@"dislikeCount"];
        youTubeVideo.commentCount = [statistics objectForKey:@"commentCount"];
        
        NSMutableString *duration = [NSMutableString stringWithString:[contentDetails objectForKey:@"duration"]];
        
        // time to a propper format
        NSString *temp = [duration substringFromIndex:2];
        
        const char *stringToParse = [duration UTF8String];
        int days = 0, hours = 0, minutes = 0, seconds = 0;
        
        const char *ptr = stringToParse;
        while(*ptr)
        {
            if(*ptr == 'P' || *ptr == 'T')
            {
                ptr++;
                continue;
            }
            
            int value, charsRead;
            char type;
            if(sscanf(ptr, "%d%c%n", &value, &type, &charsRead) != 2)
                ;  // handle parse error
            if(type == 'D')
                days = value;
            else if(type == 'H')
                hours = value;
            else if(type == 'M')
                minutes = value;
            else if(type == 'S')
                seconds = value;
            else
                ;  // handle invalid type
            
            ptr += charsRead;
        }
        
        NSTimeInterval interval = ((days * 24 + hours) * 60 + minutes) * 60 + seconds;
        NSString *intervalString = [NSString stringWithFormat:@"%f", interval];
        NSArray *intervalArray = [intervalString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
        //NSLog(@"Video Time: '%@'.", [intervalArray objectAtIndex:0]);
        youTubeVideo.unformattedDuration = [intervalArray objectAtIndex:0];
        
        //temp = [temp substringToIndex:[temp length] - 1];
        duration = [NSMutableString stringWithString: temp];
        int i = 0;
        int length = (int)[duration length];
        while (i<length)
        {
            char c = [duration characterAtIndex:i];
            if(!(c>='0' && c<='9'))
            {
                NSRange range = {i,1};
                switch (c)
                {
                    case 'H':
                        [duration replaceCharactersInRange:range withString:@"h "];
                        i++;
                        length++;
                        break;
                    case 'M':
                        [duration replaceCharactersInRange:range withString:@"m "];
                        i++;
                        length++;
                        break;
                    case 'S':
                        [duration replaceCharactersInRange:range withString:@"s"];
                        break;
                    case ':':
                        break;
                    default:
                        [duration replaceCharactersInRange:range withString:@" "];
                        break;
                }
            }
            i++;
        }
        youTubeVideo.duration = duration;
        
        
        //[youTubeVideo testPrint];
    }
    
}

#pragma system methods
// first request
+ (RACSignal*)responceForDetailedVideoInfoForId: (NSString *) videoId
{
    // getting json from YouTube API
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/videos?part=snippet%%2CcontentDetails%%2Cstatistics&id=%@&key=%@",videoId, [self developerKey]];
    
    //NSLog(@"URL: %@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    return [RACSignal createSignal:^RACDisposable *(id sibscriber)
            {
                AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                operation.responseSerializer = [AFJSONResponseSerializer serializer];
                
                [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
                 {
                     [sibscriber sendNext:responseObject];
                     [sibscriber sendCompleted];
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error)
                 {
                     [sibscriber sendError:error];
                 }];
                [operation start];
                return nil;
            }];
    
}

+ (NSMutableArray *)sortVideoArray: (NSMutableArray *)array
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortID"
                                                                   ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    return [NSMutableArray arrayWithArray:[array sortedArrayUsingDescriptors:sortDescriptors]];
}
@end
