//
//  EventSource.m
//  EventSource
//
//  Created by Neil on 25/07/2013.
//  Copyright (c) 2013 Neil Cowburn. All rights reserved,
//  Modified to match Spark events by Ido Kleinman, 2015
//  Original codebase:
//  https://github.com/neilco/EventSource


#import "EventSource.h"

static CGFloat const ES_RETRY_INTERVAL = 1.0;
//static CGFloat const ES_DEFAULT_TIMEOUT = 300.0;

static NSString *const ESKeyValueDelimiter = @": ";
static NSString *const ESEventSeparatorLFLF = @"\n\n";
static NSString *const ESEventSeparatorCRCR = @"\r\r";
static NSString *const ESEventSeparatorCRLFCRLF = @"\r\n\r\n";
static NSString *const ESEventKeyValuePairSeparator = @"\n";

static NSString *const ESEventDataKey = @"data";
static NSString *const ESEventIDKey = @"id";
static NSString *const ESEventEventKey = @"event";
static NSString *const ESEventRetryKey = @"retry";

@interface EventSource () <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    BOOL wasClosed;
}

@property (nonatomic, strong) NSURL *eventURL;
@property (nonatomic, strong) NSURLConnection *eventSource;
@property (nonatomic, strong) NSMutableDictionary *listeners;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSTimeInterval retryInterval;
@property (nonatomic, strong) id lastEventID;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSString* accessToken;

- (void)open;

@end

@implementation EventSource


+ (instancetype)eventSourceWithURL:(NSURL *)URL timeoutInterval:(NSTimeInterval)timeoutInterval queue:(dispatch_queue_t)queue accessToken:(NSString *)accessToken
{
    return [[EventSource alloc] initWithURL:URL timeoutInterval:timeoutInterval queue:queue accessToken:accessToken];
}


- (instancetype)initWithURL:(NSURL *)URL timeoutInterval:(NSTimeInterval)timeoutInterval queue:(dispatch_queue_t)queue accessToken:(NSString *)accessToken
{
    self = [super init];
    if (self) {
        _listeners = [NSMutableDictionary dictionary];
        _eventURL = URL;
        _timeoutInterval = timeoutInterval;
        _retryInterval = ES_RETRY_INTERVAL;
        _queue = queue;
        _accessToken = accessToken;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_retryInterval * NSEC_PER_SEC));
        dispatch_after(popTime, queue, ^(void){
            [self open];
        });
    }
    return self;
}

- (void)addEventListener:(NSString *)eventName handler:(EventSourceEventHandler)handler
{
    if (self.listeners[eventName] == nil) {
        [self.listeners setObject:[NSMutableArray array] forKey:eventName];
    }
    
    [self.listeners[eventName] addObject:handler];
}

- (void)removeEventListener:(NSString *)eventName handler:(EventSourceEventHandler)handler
{
    if (self.listeners[eventName])
        [self.listeners[eventName] removeObject:handler];
}



- (void)onMessage:(EventSourceEventHandler)handler
{
    [self addEventListener:MessageEvent handler:handler];
}

- (void)onError:(EventSourceEventHandler)handler
{
    [self addEventListener:ErrorEvent handler:handler];
}

- (void)onOpen:(EventSourceEventHandler)handler
{
    [self addEventListener:OpenEvent handler:handler];
}

- (void)open
{
    NSLog(@"event open");
    // TODO: add the authorization headers/parameters here
    wasClosed = NO;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.eventURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:self.timeoutInterval];
    if (self.lastEventID)
    {
        [request setValue:self.lastEventID forHTTPHeaderField:@"Last-Event-ID"];
    }
    
    [request addValue:[NSString stringWithFormat:@"Bearer %@",self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];
    
    self.eventSource = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
    if (![NSThread isMainThread]) {
        CFRunLoopRun();
    }
}

- (void)close
{
    wasClosed = YES;
    [self.eventSource cancel];
    self.queue = nil;
}

// ---------------------------------------------------------------------------------------------------------------------

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode == 200) {
        // Opened
        Event *e = [Event new];
        e.readyState = kEventStateOpen;
        
        // TODO: remove this? (open/close/etc) - consult with David
        NSArray *openHandlers = self.listeners[OpenEvent];
        for (EventSourceEventHandler handler in openHandlers) {
            dispatch_async(self.queue, ^{
                handler(e);
            });
        }
    }
    else
    {
        NSLog(@"Error opening event stream, code %ld",(long)httpResponse.statusCode);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    Event *e = [Event new];
    e.readyState = kEventStateClosed;
    e.error = error;
    
    NSArray *errorHandlers = self.listeners[ErrorEvent];
    for (EventSourceEventHandler handler in errorHandlers) {
        dispatch_async(self.queue, ^{
            handler(e);
        });
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryInterval * NSEC_PER_SEC));
    dispatch_after(popTime, self.queue, ^(void){
        [self open];
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    __block NSString *eventString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([eventString hasSuffix:ESEventSeparatorLFLF] ||
        [eventString hasSuffix:ESEventSeparatorCRCR] ||
        [eventString hasSuffix:ESEventSeparatorCRLFCRLF]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            eventString = [eventString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSMutableArray *components = [[eventString componentsSeparatedByString:ESEventKeyValuePairSeparator] mutableCopy];
            
            Event *e = [Event new];
            e.readyState = kEventStateOpen;
            
            for (NSString *component in components) {
                if (component.length == 0) {
                    continue;
                }
                
                NSInteger index = [component rangeOfString:ESKeyValueDelimiter].location;
                if (index == NSNotFound || index == (component.length - 2)) {
                    continue;
                }
                
                // TODO: clean this up prepare for Spark event structure
                NSString *key = [component substringToIndex:index];
                NSString *value = [component substringFromIndex:index + ESKeyValueDelimiter.length];
                
                if ([key isEqualToString:ESEventIDKey]) {
                    e.id = value;
                    self.lastEventID = e.id;
                } else if ([key isEqualToString:ESEventEventKey]) {
                    e.event = value;
                } else if ([key isEqualToString:ESEventDataKey]) {
                    e.data = [value dataUsingEncoding:NSUTF8StringEncoding]; //IDO added
                } else if ([key isEqualToString:ESEventRetryKey]) {
                    self.retryInterval = [value doubleValue];
                }
            }
            
            NSArray *messageHandlers = self.listeners[MessageEvent];
            for (EventSourceEventHandler handler in messageHandlers) {
                dispatch_async(self.queue, ^{
                    handler(e);
                });
            }
            
            if (e.event != nil) {
                NSArray *namedEventhandlers = self.listeners[e.event];
                for (EventSourceEventHandler handler in namedEventhandlers) {
                    dispatch_async(self.queue, ^{
                        handler(e);
                    });
                }
                
               
            }
            
        
        });
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (wasClosed) {
        return;
    }
    
    Event *e = [Event new];
    e.readyState = kEventStateClosed;
    e.error = [NSError errorWithDomain:@""
                                  code:e.readyState
                              userInfo:@{ NSLocalizedDescriptionKey: @"Connection with the event source was closed." }];
    
    NSArray *errorHandlers = self.listeners[ErrorEvent];
    for (EventSourceEventHandler handler in errorHandlers) {
        dispatch_async(self.queue, ^{
            handler(e);
        });
    }
    
    [self open];
}

@end

// ---------------------------------------------------------------------------------------------------------------------

@implementation Event

- (NSString *)description
{
    NSString *state = nil;
    switch (self.readyState) {
        case kEventStateConnecting:
            state = @"CONNECTING";
            break;
        case kEventStateOpen:
            state = @"OPEN";
            break;
        case kEventStateClosed:
            state = @"CLOSED";
            break;
    }
    
    return [NSString stringWithFormat:@"<%@: readyState: %@, id: %@; event: %@; data: %@>",
            [self class],
            state,
            self.id,
            self.event,
            self.data];
}

@end

NSString *const MessageEvent = @"message";
NSString *const ErrorEvent = @"error";
NSString *const OpenEvent = @"open";