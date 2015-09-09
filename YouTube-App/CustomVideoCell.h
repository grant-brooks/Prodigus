//
//  CustomVideoCell.h
//  Prodigus II
//
//  Created by Grant Goodman on 6/3/15.
//  Copyright © 2015 Macster Software Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YTPlayerView.h>

@interface CustomVideoCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *previewImage;
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *time;
@property (strong, nonatomic) IBOutlet UILabel *likeCount;
@property (strong, nonatomic) IBOutlet UILabel *dislikeCount;
@property (strong, nonatomic) IBOutlet UILabel *channelTitle;
@property (strong, nonatomic) IBOutlet UILabel *viewCount;
@property (weak, nonatomic) IBOutlet UILabel *publishedAt;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
- (IBAction)favoriteButton:(id)sender;

@end
