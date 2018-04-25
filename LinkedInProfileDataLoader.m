//
//  LinkedInProfileDataLoader.m
//  TestGetSourceCode
//
//  Created by whoami on 4/24/18.
//  Copyright © 2018 Mountain Viewer. All rights reserved.
//

#import "LinkedInProfileDataLoader.h"

@interface LinkedInProfileDataLoader ()

// JSONified main profile info obtained from HTML source
@property (nonatomic, strong) NSMutableArray *mainInfo;

// JSONified contact info obtained from HTML source
@property (nonatomic, strong) NSMutableArray *contactInfo;

@end

@implementation LinkedInProfileDataLoader

- (id)initWithUsername:(NSString *)username {
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.username = username;
    
    NSString *mainInfoURLString = [NSString stringWithFormat:@"https://www.linkedin.com/in/%@", self.username];
    NSString *contactInfoURLString = [NSString stringWithFormat:@"https://www.linkedin.com/in/%@/detail/contact-info/", self.username];

    
    NSString *mainInfoSource = [self produceSourceCodeByURLString:mainInfoURLString];
    NSString *contactInfoSource = [self produceSourceCodeByURLString:contactInfoURLString];
    
    mainInfoSource = [LinkedInProfileDataLoader decodeHTMLCharacterEntitiesString:mainInfoSource];
    contactInfoSource = [LinkedInProfileDataLoader decodeHTMLCharacterEntitiesString:contactInfoSource];
    
    self.mainInfo = [self extractMainInfo:mainInfoSource];
    self.contactInfo = [self extractContactInfo:contactInfoSource];
    
    return self;
}

- (NSString *)produceSourceCodeByURLString:(NSString *)URLString {
    NSError *error = nil;
    
    NSURL *URL = [NSURL URLWithString:[URLString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSString *source = [NSString stringWithContentsOfURL:URL encoding:NSASCIIStringEncoding error:&error];
    return source;
}

- (NSMutableArray *)extractMainInfo:(NSString *)source {
    NSString *text = source;
    NSMutableArray<NSString *> *sourcePartition = [NSMutableArray array];
    
    while (YES) {
        NSRange beginPartRange = [text rangeOfString:@"<code"];
        
        if (beginPartRange.location == NSNotFound) {
            break;
        }
        
        text = [text substringFromIndex:beginPartRange.location];
        
        NSRange closeBracket = [text rangeOfString:@">"];
        text = [text substringFromIndex:closeBracket.location + closeBracket.length];
        
        NSRange endPartRange = [text rangeOfString:@"</code>"];
        NSRange partRange = NSMakeRange(0, endPartRange.location);
        NSString *part = [text substringWithRange:partRange];
        
        [sourcePartition addObject:part];
    }
    
    NSUInteger partLength = 0;
    NSUInteger index = -1;
    
    for (NSUInteger i = 0; i < [sourcePartition count]; ++i) {
        NSString *part = sourcePartition[i];
        
        // Finding the part with max length -- this is the main profile info
        if ([part length] > partLength) {
            partLength = [part length];
            index = i;
        }
    }
    
    NSData *jsonData = [sourcePartition[index] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e = nil;
    
    NSMutableArray *array = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];
    return array;
}

- (NSMutableArray *)extractContactInfo:(NSString *)source {
    NSString *text = source;
    NSMutableArray<NSString *> *sourcePartition = [NSMutableArray array];
    
    while (YES) {
        NSRange beginPartRange = [text rangeOfString:@"<code"];
        
        if (beginPartRange.location == NSNotFound) {
            break;
        }
        
        text = [text substringFromIndex:beginPartRange.location];
        
        NSRange closeBracket = [text rangeOfString:@">"];
        text = [text substringFromIndex:closeBracket.location + closeBracket.length];
        
        NSRange endPartRange = [text rangeOfString:@"</code>"];
        NSRange partRange = NSMakeRange(0, endPartRange.location);
        NSString *part = [text substringWithRange:partRange];
        
        [sourcePartition addObject:part];
    }
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < [sourcePartition count]; ++i) {
        NSString *part = sourcePartition[i];
        
        // Finding the part with substring @"fs_contactinfo" -- this is the contact info
        if ([part containsString:@"fs_contactinfo"]) {
            NSData *jsonData = [part dataUsingEncoding:NSUTF8StringEncoding];
            NSError *e = nil;
            
            array = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];
            break;
        }
    }
    
    return array;
}

- (NSDictionary *)getSummary {
    NSMutableDictionary *summary = [NSMutableDictionary dictionary];
    
    NSArray *elems = ((NSDictionary *)self.mainInfo)[@"included"];
    
    NSMutableArray *summaryTags = [NSMutableArray array];
    for (NSUInteger i = 0; i < elems.count; ++i) {
        NSDictionary *dict = (NSDictionary *)elems[i];
        if ([dict objectForKey:@"summary"]) {
            [summaryTags addObject:dict];
        }
    }
    
    if ([summaryTags[0] objectForKey:@"locationName"]) {
        [summary setObject:summaryTags[0][@"locationName"] forKey:@"locationName"];
    }
    
    if ([summaryTags[0] objectForKey:@"lastName"]) {
        [summary setObject:summaryTags[0][@"lastName"] forKey:@"lastName"];
    }
    
    if ([summaryTags[0] objectForKey:@"firstName"]) {
        [summary setObject:summaryTags[0][@"firstName"] forKey:@"firstName"];
    }
    
    if ([summaryTags[0] objectForKey:@"industryName"]) {
        [summary setObject:summaryTags[0][@"industryName"] forKey:@"industryName"];
    }
    
    if ([summaryTags[0] objectForKey:@"headline"]) {
        [summary setObject:summaryTags[0][@"headline"] forKey:@"headline"];
    }
    
    if ([summaryTags[0] objectForKey:@"summary"]) {
        [summary setObject:summaryTags[0][@"summary"] forKey:@"summary"];
    }
    
    return summary;
}

- (NSDictionary *)getPhotoURL {
    NSMutableDictionary *photoURL = [NSMutableDictionary dictionary];
    
    NSArray *elems = ((NSDictionary *)self.mainInfo)[@"included"];
    
    NSMutableArray *summaryTags = [NSMutableArray array];
    for (NSUInteger i = 0; i < elems.count; ++i) {
        NSDictionary *dict = (NSDictionary *)elems[i];
        if ([dict objectForKey:@"summary"]) {
            [summaryTags addObject:dict];
        }
    }
    
    NSString *miniProfile = summaryTags[0][@"miniProfile"];
    
    
    NSString *rootURL = @"";
    for (NSUInteger i = 0; i < elems.count; ++i) {
        if ([elems[i] objectForKey:@"rootUrl"] && [elems[i][@"rootUrl"] rangeOfString:@"profile-displayphoto-shrink_"].location != NSNotFound &&
            [elems[i][@"$id"] rangeOfString:miniProfile].location != NSNotFound) {
            rootURL = elems[i][@"rootUrl"];
            break;
        }
    }
    
    NSString *pathSegment = @"";
    NSUInteger width = 0;
    for (NSUInteger i = 0; i < elems.count; ++i) {
        if ([elems[i] objectForKey:@"height"] && [elems[i] objectForKey:@"width"] && [elems[i][@"$id"] rangeOfString:miniProfile].location != NSNotFound &&
            [elems[i][@"$id"] rangeOfString:@"picture"].location != NSNotFound) {
            if (width < (NSUInteger)[elems[i] objectForKey:@"width"]) {
                width = (NSUInteger)[elems[i] objectForKey:@"width"];
                pathSegment = elems[i][@"fileIdentifyingUrlPathSegment"];
            }
        }
    }
    
    
    NSString *fullURL = [NSString stringWithFormat:@"%@%@", rootURL, pathSegment];
    [photoURL setObject:fullURL forKey:@"photoURL"];
    
    return photoURL;
}

- (NSArray *)getEducation {
    NSMutableArray *education = [NSMutableArray array];
    
    NSArray *elems = ((NSDictionary *)self.mainInfo)[@"included"];
    
    NSMutableArray *educationTags = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < elems.count; ++i) {
        NSDictionary *dict = (NSDictionary *)elems[i];
        if ([dict objectForKey:@"schoolName"] && [dict objectForKey:@"degreeName"]) {
            [educationTags addObject:dict];
        }
    }
    
    for (NSUInteger i = 0; i < [educationTags count]; ++i) {
        NSMutableDictionary *schoolDict = [NSMutableDictionary dictionary];
        
        if ([educationTags[i] objectForKey:@"schoolName"]) {
            [schoolDict setObject:educationTags[i][@"schoolName"] forKey:@"schoolName"];
        }
        
        if ([educationTags[i] objectForKey:@"degreeName"]) {
            [schoolDict setObject:educationTags[i][@"degreeName"] forKey:@"degreeName"];
        }
        
        if ([educationTags[i] objectForKey:@"fieldOfStudy"]) {
            [schoolDict setObject:educationTags[i][@"fieldOfStudy"] forKey:@"fieldOfStudy"];
        }
        
        // Time period
        for (NSUInteger j = 0; j < [elems count]; ++j) {
            if ([educationTags[i] objectForKey:@"timePeriod"] && [elems[j][@"$id"] rangeOfString:educationTags[i][@"timePeriod"]].location != NSNotFound) {
                if ([elems[j][@"$id"] rangeOfString:@"startDate"].location != NSNotFound) {
                    
                    if ([elems[j] objectForKey:@"month"]) {
                        [schoolDict setObject:elems[j][@"month"] forKey:@"startMonth"];
                    }
                    
                    if ([elems[j] objectForKey:@"year"]) {
                        [schoolDict setObject:elems[j][@"year"] forKey:@"startYear"];
                    }
                } else if ([elems[j][@"$id"] rangeOfString:@"endDate"].location != NSNotFound){
                    if ([elems[j] objectForKey:@"month"]) {
                        [schoolDict setObject:elems[j][@"month"] forKey:@"endMonth"];
                    }
            
                    if ([elems[j] objectForKey:@"year"]) {
                        [schoolDict setObject:elems[j][@"year"] forKey:@"endYear"];
                    }
                }
            }
        }
        
        [education addObject:schoolDict];
    }
    
    return education;
}

- (NSArray *)getJobs {
    NSMutableArray *jobs = [NSMutableArray array];
    
    NSArray *elems = ((NSDictionary *)self.mainInfo)[@"included"];
    
    NSMutableArray *jobsTags = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < elems.count; ++i) {
        NSDictionary *dict = (NSDictionary *)elems[i];
        if ([dict objectForKey:@"companyName"]) {
            [jobsTags addObject:dict];
        }
    }
    NSLog(@"%@", jobsTags);
    for (NSUInteger i = 0; i < [jobsTags count]; ++i) {
        NSMutableDictionary *jobDict = [NSMutableDictionary dictionary];
        
        if ([jobsTags[i] objectForKey:@"title"]) {
             [jobDict setObject:jobsTags[i][@"title"] forKey:@"jobTitle"];
        }
        
        if ([jobsTags[i] objectForKey:@"companyName"]) {
            [jobDict setObject:jobsTags[i][@"companyName"] forKey:@"companyName"];
        }
        
        // Time period
        for (NSUInteger j = 0; j < [elems count]; ++j) {
            if ([jobsTags[i] objectForKey:@"timePeriod"] && [elems[j][@"$id"] rangeOfString:jobsTags[i][@"timePeriod"]].location != NSNotFound) {
                if ([elems[j][@"$id"] rangeOfString:@"startDate"].location != NSNotFound) {
                    
                    if ([elems[j] objectForKey:@"month"]) {
                        [jobDict setObject:elems[j][@"month"] forKey:@"startMonth"];
                    }
                    
                    if ([elems[j] objectForKey:@"year"]) {
                        [jobDict setObject:elems[j][@"year"] forKey:@"startYear"];
                    }
                } else if ([elems[j][@"$id"] rangeOfString:@"endDate"].location != NSNotFound){
                    if ([elems[j] objectForKey:@"month"]) {
                        [jobDict setObject:elems[j][@"month"] forKey:@"endMonth"];
                    }
                    
                    if ([elems[j] objectForKey:@"year"]) {
                        [jobDict setObject:elems[j][@"year"] forKey:@"endYear"];
                    }
                }
            }
        }
        
        [jobs addObject:jobDict];
    }
    
    return jobs;
}

- (NSDictionary *)getContactInfo {
    NSMutableDictionary *contactInfo = [NSMutableDictionary dictionary];
    
    NSDictionary *dict = (NSDictionary *)self.contactInfo;
    if ([dict[@"data"] objectForKey:@"emailAddress"]) {
        [contactInfo setObject:dict[@"data"][@"emailAddress"] forKey:@"emailAddress"];
    }
    
    NSMutableDictionary *dictHelper = [NSMutableDictionary dictionary];
    for (NSUInteger i = 0; i < [dict[@"included"] count]; ++i) {
        for (id key in dict[@"included"][i]) {
            [dictHelper setObject:[dict[@"included"][i] objectForKey:key] forKey:key];
        }
    }

    if ([dictHelper objectForKey:@"number"]) {
        [contactInfo setObject:dictHelper[@"number"] forKey:@"number"];
    }
    
    if ([dictHelper objectForKey:@"month"]) {
        [contactInfo setObject:dictHelper[@"month"] forKey:@"month"];
    }
    
    if ([dictHelper objectForKey:@"day"]) {
        [contactInfo setObject:dictHelper[@"day"] forKey:@"day"];
    }
    
    if ([dictHelper objectForKey:@"name"]) {
        [contactInfo setObject:dictHelper[@"name"] forKey:@"twitter"];
    }
    
    return contactInfo;
}

+ (NSString *)decodeHTMLCharacterEntitiesString:(NSString *)string {
    if ([string rangeOfString:@"&"].location == NSNotFound) {
        return string;
    } else {
        NSMutableString *escaped = [NSMutableString stringWithString:string];
        NSArray *codes = [NSArray arrayWithObjects:
                          @"&nbsp;", @"&iexcl;", @"&cent;", @"&pound;", @"&curren;", @"&yen;", @"&brvbar;",
                          @"&sect;", @"&uml;", @"&copy;", @"&ordf;", @"&laquo;", @"&not;", @"&shy;", @"&reg;",
                          @"&macr;", @"&deg;", @"&plusmn;", @"&sup2;", @"&sup3;", @"&acute;", @"&micro;",
                          @"&para;", @"&middot;", @"&cedil;", @"&sup1;", @"&ordm;", @"&raquo;", @"&frac14;",
                          @"&frac12;", @"&frac34;", @"&iquest;", @"&Agrave;", @"&Aacute;", @"&Acirc;",
                          @"&Atilde;", @"&Auml;", @"&Aring;", @"&AElig;", @"&Ccedil;", @"&Egrave;",
                          @"&Eacute;", @"&Ecirc;", @"&Euml;", @"&Igrave;", @"&Iacute;", @"&Icirc;", @"&Iuml;",
                          @"&ETH;", @"&Ntilde;", @"&Ograve;", @"&Oacute;", @"&Ocirc;", @"&Otilde;", @"&Ouml;",
                          @"&times;", @"&Oslash;", @"&Ugrave;", @"&Uacute;", @"&Ucirc;", @"&Uuml;", @"&Yacute;",
                          @"&THORN;", @"&szlig;", @"&agrave;", @"&aacute;", @"&acirc;", @"&atilde;", @"&auml;",
                          @"&aring;", @"&aelig;", @"&ccedil;", @"&egrave;", @"&eacute;", @"&ecirc;", @"&euml;",
                          @"&igrave;", @"&iacute;", @"&icirc;", @"&iuml;", @"&eth;", @"&ntilde;", @"&ograve;",
                          @"&oacute;", @"&ocirc;", @"&otilde;", @"&ouml;", @"&divide;", @"&oslash;", @"&ugrave;",
                          @"&uacute;", @"&ucirc;", @"&uuml;", @"&yacute;", @"&thorn;", @"&yuml;", nil];
        
        NSUInteger i, count = [codes count];
        
        // Html
        for (i = 0; i < count; i++) {
            NSRange range = [string rangeOfString:[codes objectAtIndex:i]];
            if (range.location != NSNotFound) {
                [escaped replaceOccurrencesOfString:[codes objectAtIndex:i]
                                         withString:[NSString stringWithFormat:@"%C", (unsigned short) (160 + i)]
                                            options:NSLiteralSearch
                                              range:NSMakeRange(0, [escaped length])];
            }
        }
        
        // The following five are not in the 160+ range
        
        // @"&amp;"
        NSRange range = [string rangeOfString:@"&amp;"];
        if (range.location != NSNotFound) {
            [escaped replaceOccurrencesOfString:@"&amp;"
                                     withString:[NSString stringWithFormat:@"%C", (unsigned short) 38]
                                        options:NSLiteralSearch
                                          range:NSMakeRange(0, [escaped length])];
        }
        
        // @"&lt;"
        range = [string rangeOfString:@"&lt;"];
        if (range.location != NSNotFound) {
            [escaped replaceOccurrencesOfString:@"&lt;"
                                     withString:[NSString stringWithFormat:@"%C", (unsigned short) 60]
                                        options:NSLiteralSearch
                                          range:NSMakeRange(0, [escaped length])];
        }
        
        // @"&gt;"
        range = [string rangeOfString:@"&gt;"];
        if (range.location != NSNotFound) {
            [escaped replaceOccurrencesOfString:@"&gt;"
                                     withString:[NSString stringWithFormat:@"%C", (unsigned short) 62]
                                        options:NSLiteralSearch
                                          range:NSMakeRange(0, [escaped length])];
        }
        
        // @"&apos;"
        range = [string rangeOfString:@"&apos;"];
        if (range.location != NSNotFound) {
            [escaped replaceOccurrencesOfString:@"&apos;"
                                     withString:[NSString stringWithFormat:@"%C", (unsigned short) 39]
                                        options:NSLiteralSearch
                                          range:NSMakeRange(0, [escaped length])];
        }
        
        // @"&quot;"
        range = [string rangeOfString:@"&quot;"];
        if (range.location != NSNotFound) {
            [escaped replaceOccurrencesOfString:@"&quot;"
                                     withString:[NSString stringWithFormat:@"%C", (unsigned short) 34]
                                        options:NSLiteralSearch
                                          range:NSMakeRange(0, [escaped length])];
        }
        
        // Decimal & Hex
        NSRange start, finish, searchRange = NSMakeRange(0, [escaped length]);
        i = 0;
        
        while (i < [escaped length]) {
            start = [escaped rangeOfString:@"&#"
                                   options:NSCaseInsensitiveSearch
                                     range:searchRange];
            
            finish = [escaped rangeOfString:@";"
                                    options:NSCaseInsensitiveSearch
                                      range:searchRange];
            
            if (start.location != NSNotFound && finish.location != NSNotFound &&
                finish.location > start.location) {
                NSRange entityRange = NSMakeRange(start.location, (finish.location - start.location) + 1);
                NSString *entity = [escaped substringWithRange:entityRange];
                NSString *value = [entity substringWithRange:NSMakeRange(2, [entity length] - 2)];
                
                [escaped deleteCharactersInRange:entityRange];
                
                if ([value hasPrefix:@"x"]) {
                    unsigned tempInt = 0;
                    NSScanner *scanner = [NSScanner scannerWithString:[value substringFromIndex:1]];
                    [scanner scanHexInt:&tempInt];
                    [escaped insertString:[NSString stringWithFormat:@"%C", (unsigned short) tempInt] atIndex:entityRange.location];
                } else {
                    [escaped insertString:[NSString stringWithFormat:@"%C", (unsigned short) [value intValue]] atIndex:entityRange.location];
                } i = start.location;
            } else { i++; }
            searchRange = NSMakeRange(i, [escaped length] - i);
        }
        
        return escaped;    // Note this is autoreleased
    }
}

+ (NSString *)encodeHTMLCharacterEntitiesString:(NSString *)string {
    NSMutableString *encoded = [NSMutableString stringWithString:string];
    
    // @"&amp;"
    NSRange range = [string rangeOfString:@"&"];
    if (range.location != NSNotFound) {
        [encoded replaceOccurrencesOfString:@"&"
                                 withString:@"&amp;"
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, [encoded length])];
    }
    
    // @"&lt;"
    range = [string rangeOfString:@"<"];
    if (range.location != NSNotFound) {
        [encoded replaceOccurrencesOfString:@"<"
                                 withString:@"&lt;"
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, [encoded length])];
    }
    
    // @"&gt;"
    range = [string rangeOfString:@">"];
    if (range.location != NSNotFound) {
        [encoded replaceOccurrencesOfString:@">"
                                 withString:@"&gt;"
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, [encoded length])];
    }
    
    return encoded;
}

@end
