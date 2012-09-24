//
//  ContentItem.m
//  ArcGISMobile
//
//  Created by ryan3374 on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ContentItem.h"
#import "NSDictionary+Additions.h"

@implementation ContentItem

@synthesize itemId = _itemId;
@synthesize item = _item;
@synthesize itemType = _itemType;
@synthesize contentType = _contentType;
@synthesize title = _title;
@synthesize type = _type;
@synthesize thumbnail = _thumbnail;
@synthesize access = _access;
@synthesize owner = _owner;
@synthesize size = _size;
@synthesize description = _description;
@synthesize snippet = _snippet;
@synthesize extent = _extent;
@synthesize uploaded = _uploaded;
@synthesize name = _name;
@synthesize avgRating = _avgRating;
@synthesize tags = _tags;
@synthesize numComments = _numComments;
@synthesize numRatings = _numRatings;
@synthesize numViews = _numViews;

#pragma mark -
#pragma mark AGSCoding

- (void)decodeWithJSON:(NSDictionary *)json {
	self.itemId = [AGSJSONUtility getStringFromDictionary:json withKey:@"id"];
	self.item = [AGSJSONUtility getStringFromDictionary:json withKey:@"item"];
	self.itemType = [AGSJSONUtility getStringFromDictionary:json withKey:@"itemType"];
    self.access = [AGSJSONUtility getStringFromDictionary:json withKey:@"access"];
	self.contentType = [AGSJSONUtility getStringFromDictionary:json withKey:@"contentType"];
	self.title = [AGSJSONUtility getStringFromDictionary:json withKey:@"title"];
	self.type = [AGSJSONUtility getStringFromDictionary:json withKey:@"type"];
	self.thumbnail = [AGSJSONUtility getStringFromDictionary:json withKey:@"thumbnail"];
	self.owner = [AGSJSONUtility getStringFromDictionary:json withKey:@"owner"];
	self.description = [AGSJSONUtility getStringFromDictionary:json withKey:@"description"];
	self.snippet = [AGSJSONUtility getStringFromDictionary:json withKey:@"snippet"];
	
	// agol stores the extent as an array that contains 2 arrays of doubles
	NSArray *extentArray = [NSDictionary safeGetObjectFromDictionary:json withKey:@"extent"];
    if (extentArray && [extentArray count] == 2)
    {
        NSArray *bl = [extentArray objectAtIndex:0];
        NSArray *tr = [extentArray objectAtIndex:1];
        double minx = [[bl objectAtIndex:0]doubleValue];
        double miny = [[bl objectAtIndex:1]doubleValue];
        double maxx = [[tr objectAtIndex:0]doubleValue];
        double maxy = [[tr objectAtIndex:1]doubleValue];
        self.extent = [[AGSEnvelope alloc]initWithXmin:minx ymin:miny xmax:maxx ymax:maxy spatialReference:[AGSSpatialReference spatialReferenceWithWKID:4326 WKT:nil]];
    }
    else {
        self.extent = nil;
    }

    self.size = [[json valueForKey:@"size"] intValue];
    
    self.uploaded = [[json valueForKey:@"uploaded"] doubleValue];
    
	if ([json valueForKey:@"avgRating"] != nil) {
		self.avgRating = [[json valueForKey:@"avgRating"] doubleValue];
	}
	else {
		self.avgRating = 0.0;
	}   
    
	self.name = [AGSJSONUtility getStringFromDictionary:json withKey:@"name"];

    self.tags = [json valueForKey:@"tags"];
    
    self.numComments = [[json valueForKey:@"numComments"] intValue];
    self.numRatings = [[json valueForKey:@"numRatings"] intValue];
    self.numViews = [[json valueForKey:@"numViews"] intValue];
}

- (id)initWithJSON:(NSDictionary *)json {
    if (self = [super init]) {
        [self decodeWithJSON:json];
    }
    return self;
}

- (NSDictionary *)encodeToJSON;
{
	NSMutableDictionary *json = [NSMutableDictionary dictionaryWithCapacity:15];
	
	[NSDictionary safeSetObjectInDictionary:json object:self.itemId withKey:@"id"];
	[NSDictionary safeSetObjectInDictionary:json object:self.item withKey:@"item"];
	[NSDictionary safeSetObjectInDictionary:json object:self.itemType withKey:@"itemType"];
	[NSDictionary safeSetObjectInDictionary:json object:self.contentType withKey:@"contentType"];
	[NSDictionary safeSetObjectInDictionary:json object:self.title withKey:@"title"];
    [NSDictionary safeSetObjectInDictionary:json object:self.access withKey:@"access"];
	[NSDictionary safeSetObjectInDictionary:json object:self.type withKey:@"type"];
	[NSDictionary safeSetObjectInDictionary:json object:self.thumbnail withKey:@"thumbnail"];
	[NSDictionary safeSetObjectInDictionary:json object:self.owner withKey:@"owner"];
    [NSDictionary safeSetObjectInDictionary:json object:self.description withKey:@"description"];
    [NSDictionary safeSetObjectInDictionary:json object:self.snippet withKey:@"snippet"];
	[json setValue:[NSNumber numberWithInt:self.size] forKey:@"size"];

    if (self.extent != nil)
    {
        // agol stores the extent as an array that contains 2 arrays of doubles
        NSArray *bl = [NSArray arrayWithObjects: [NSNumber numberWithDouble:self.extent.xmin], [NSNumber numberWithDouble:self.extent.ymin], nil];
        NSArray *tr = [NSArray arrayWithObjects: [NSNumber numberWithDouble:self.extent.xmax], [NSNumber numberWithDouble:self.extent.ymax], nil];
        NSArray *extentArray = [NSArray arrayWithObjects:bl,tr,nil];
        [json setValue:extentArray forKey:@"extent"];
    }

	[json setValue:[NSNumber numberWithDouble:self.uploaded] forKey:@"uploaded"];
    [NSDictionary safeSetObjectInDictionary:json object:self.name withKey:@"name"];
	[json setValue:[NSNumber numberWithDouble:self.avgRating] forKey:@"avgRating"];

    if (self.tags != nil)
        [json setObject:self.tags forKey:@"tags"];

	[json setValue:[NSNumber numberWithInt:self.numComments] forKey:@"numComments"];
    [json setValue:[NSNumber numberWithInt:self.numRatings] forKey:@"numRatings"];
    [json setValue:[NSNumber numberWithInt:self.numViews] forKey:@"numViews"];

    return json;
}

#pragma mark -
#pragma mark other



@end