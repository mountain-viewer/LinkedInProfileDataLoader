//
//  LinkedInProfileDataLoader.h
//  TestGetSourceCode
//
//  Created by whoami on 4/24/18.
//  Copyright © 2018 Mountain Viewer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LinkedInProfileDataLoader : NSObject

// Suppose we have just the username
- (id)initWithUsername:(NSString *)username;

// Short overview of a LinkedIn profile
- (NSDictionary *)getSummary;

// URL to profile image
- (NSDictionary *)getPhotoURL;

// List of education places
- (NSArray *)getEducation;

// List of jobs involved
- (NSArray *)getJobs;

// List of contacts
- (NSDictionary *)getContactInfo;

// Decode to HTML
+ (NSString *)decodeHTMLCharacterEntitiesString:(NSString *)string;

// Encode from HTML
+ (NSString *)encodeHTMLCharacterEntitiesString:(NSString *)string;

// Username
@property (nonatomic, strong) NSString *username;

@end
