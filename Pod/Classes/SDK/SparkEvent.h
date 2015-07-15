//
//  SparkEvent.h
//  Pods
//
//  Created by Ido on 7/14/15.
//
//

#import <Foundation/Foundation.h>
/**
 *  Spark event handler function which receives two arguements
 *
 *  @param eventDict NSDictionary argument which contains the event payload keys: event (name), data (payload), ttl (time to live), published_at (date/time published), coreid (publishiing device ID).
 *  @param error     NSError object in case an error occured in parsing the event payload or receiving it
 */
@class SparkEvent;

typedef void (^SparkEventHandler)(SparkEvent *event, NSError *error);

@interface SparkEvent : NSObject

@property (nonatomic, strong) NSString *deviceID;   // Event published by this device ID
@property (nonatomic, strong) NSString *data;       // Event string payload
@property (nonatomic, strong) NSString *event;      // Event name
@property (nonatomic, strong) NSDate *time;         // Event "published at" time/dat
@property (nonatomic) NSInteger ttl;                // Event time to live

-(instancetype)initWithEventDict:(NSDictionary *)eventDict;

@end
