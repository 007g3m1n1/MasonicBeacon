//
//  GeocodeService.m
//  ArcGISMobile
//
//  Created by Mark Dostal on 6/14/11.
//  Copyright 2011 ESRI. All rights reserved.
//

#import "GeocodeService.h"

#import "MapAppDelegate.h"
#import "ArcGISMobileConfig.h"
#import "NSDictionary+Additions.h"

@interface GeocodeService ()

@property (nonatomic, unsafe_unretained) ArcGISAppDelegate *app;

@end

@implementation GeocodeService

@synthesize delegate = _delegate;
@synthesize responseString = _responseString;
@synthesize findAddressLocator = _findAddressLocator;
@synthesize addressLocatorString = _addressLocatorString;
@synthesize findAddressOperation = _findAddressOperation;
@synthesize findPlaceOperation = _findPlaceOperation;
@synthesize useSingleLine = _useSingleLine;

//private properties
@synthesize app = _app;

#pragma mark -
#pragma mark NSURLConnection

#pragma mark -
#pragma mark Public


#pragma -
#pragma mark Lazy Loads
-(ArcGISAppDelegate *)app
{
    if(_app == nil)
        self.app = (ArcGISAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    return _app;
}

#pragma mark -
#pragma mark findAddressCandidates

- (NSOperation *)findAddressCandidates:(NSString *)searchString withSpatialReference:(AGSSpatialReference *)spatialReference {
	
    if (self.findAddressOperation)
    {
        //if we're already finding an address, cancel it
        [self.findAddressOperation cancel];
    }

    // Search for address using AddressLocator (AGSLocator)
    if(!self.findAddressLocator)
    {
        NSURL *url = ( self.addressLocatorString != nil && self.addressLocatorString.length > 0) ?  [NSURL URLWithString:self.addressLocatorString] : 
                                                                                                    [NSURL URLWithString:self.app.config.locatorServiceUrl];
        self.findAddressLocator = [AGSLocator locatorWithURL:url];
        self.findAddressLocator.delegate = self;
    }

    NSString *currentLocaleString = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:searchString, (self.useSingleLine) ? @"SingleLine" : @"SingleKey",
                            currentLocaleString, @"localeCode", nil];  
    
    self.findAddressOperation = [self.findAddressLocator locationsForAddress:params
                                                                returnFields:[NSArray arrayWithObject:@"*"]
                                                         outSpatialReference:spatialReference];
    
    return (self.findAddressOperation);
}

// Locator delegate methods
- (void) locator:(AGSLocator *)locator operation:(NSOperation *)op didFindLocationsForAddress:(NSArray *)candidates
{
    NSLog(@"%@ Found %d candidates",locator.URL ,[candidates count] );
    
    if ([self.delegate respondsToSelector:@selector(geocodeService:operation:didFindLocationsForAddress:)])
    {
        [self.delegate geocodeService:self operation:op didFindLocationsForAddress:candidates];
    }    
    
    self.findAddressOperation = nil;
}

- (void) locator: (AGSLocator *) locator operation: (NSOperation *) op didFailLocationsForAddress: (NSError *) error
{
	NSLog(@"%@", error);
    
    if ([self.delegate respondsToSelector:@selector(geocodeService:operation:didFailLocationsForAddress:)])
    {
        [self.delegate geocodeService:self operation:op didFailLocationsForAddress:error];
    }
    
    self.findAddressOperation = nil;
}

#pragma mark -
#pragma mark findPlace

- (NSOperation *)findPlace:(NSString *)searchString withSpatialReference:(AGSSpatialReference *)spatialReference {
	
    if (self.findPlaceOperation)
    {
        //if we're already finding an address, cancel it
        [self.findPlaceOperation cancel];
        self.findPlaceOperation = nil;
    }
    
    NSString *currentLocaleString = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"json", @"f",
                                   searchString, @"place",
                                   currentLocaleString, @"localeCode",
                                   nil];
            
    if (spatialReference != nil){
        [spatialReference encodeToJSON:params forKey:@"outSR"];
    }

    NSURL *url = [NSURL URLWithString:self.app.config.worldLocatorServiceUrl];

    AGSJSONRequestOperation *operation = [[AGSJSONRequestOperation alloc] initWithURL:url
                                                                             resource:@"findPlace"
                                                                      queryParameters:params
                                                                               doPOST:YES];
    
    operation.target = self;
    operation.action = @selector(findPlaceOperation:didComplete:);
    operation.errorAction = @selector(findPlaceOperation:didFailWithError:);
    operation.credential = nil;
    
    [[AGSRequestOperation sharedOperationQueue] addOperation:operation];
    
    self.findPlaceOperation = operation;
    
    return operation;
}

- (void)findPlaceOperation:(NSOperation*)op didComplete:(NSDictionary *)json {

    AGSSpatialReference *spatialReference = nil;

    id tmp = [json valueForKey:@"spatialReference"];    
    if (tmp && tmp != [NSNull null])
    {
        spatialReference = [[AGSSpatialReference alloc] initWithJSON:tmp]; 
    }
    
    NSArray *jsonArray = [json valueForKey:@"candidates"];
    NSMutableArray *places = [NSMutableArray arrayWithCapacity:[jsonArray count]];
    for (NSDictionary *placeJson in jsonArray) {
        
        FindPlaceCandidate *place = [[FindPlaceCandidate alloc] initWithJSON:placeJson withSpatialReference:spatialReference];
        [places addObject:place];
        
    }
    
    if ([self.delegate respondsToSelector:@selector(geocodeService:operation:didFindPlace:)])
    {
        [self.delegate geocodeService:self operation:op didFindPlace:places];
    }
}

- (void)findPlaceOperation:(NSOperation *)op didFailWithError:(NSError *)error {

    if ([self.delegate respondsToSelector:@selector(geocodeService:operation:didFailFindPlace:)])
    {
        [self.delegate geocodeService:self operation:op didFailFindPlace:error];
    }
}

#pragma mark -
#pragma mark Memory Management

-(void) dealloc{
	self.delegate = nil;
}

@end

#pragma mark -
#pragma mark FindPlaceCandidate

@implementation FindPlaceCandidate

@synthesize name = _name;
@synthesize score = _score;
@synthesize location = _location;
@synthesize extent = _extent;


-(id)initWithJSON:(NSDictionary *)json withSpatialReference:(AGSSpatialReference *)spatialReference
{
    if (self = [self initWithJSON:json])
    {
        //use the spatialReference with our location
        self.location = [AGSPoint pointWithX:self.location.x y:self.location.y spatialReference:spatialReference];
        self.extent = [AGSEnvelope envelopeWithXmin:self.extent.xmin
                                               ymin:self.extent.ymin
                                               xmax:self.extent.xmax
                                               ymax:self.extent.ymax
                                   spatialReference:spatialReference];
    }
    
    return self;
}

- (id)initWithJSON:(NSDictionary *)json {
    if (self = [super init]) {
        [self decodeWithJSON:json];
    }
    
    return self;
}

- (NSDictionary*)encodeToJSON {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
    [NSDictionary safeSetObjectInDictionary:dict object:self.name withKey:@"name"];
    [NSDictionary safeSetObjectInDictionary:dict object:self.score withKey:@"score"];
	[dict setValue:[self.location encodeToJSON] forKey:@"location"];
	[dict setValue:[self.extent encodeToJSON] forKey:@"extent"];
	
	return dict;
}

- (void)decodeWithJSON:(NSDictionary *)json {
    self.name = [json valueForKey:@"name"];
    self.score = [json valueForKey:@"score"];
    self.location = [[AGSPoint alloc] initWithJSON:[json valueForKey:@"location"]];
    self.extent = [[AGSEnvelope alloc] initWithJSON:[json valueForKey:@"extent"]];
}



@end