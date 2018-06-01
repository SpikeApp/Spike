#ifndef HealthKitStore_h
#define HealthKitStore_h

@interface HealthKitStore : NSObject

+ (HealthKitStore*) getInstance:(NSString*) iosVersion;

+ (void) storeBloodGlucose:(double) valueInMgDL dateWithTimeIntervalSince1970:(NSDate *) date;

+ (void) storeInsulinDelivery:(double) amount dateWithTimeIntervalSince1970:(NSDate *) date isBolus:(bool) bolus ;

+ (void) storeCarbs:(double) amount dateWithTimeIntervalSince1970:(NSDate *) date;

@end

#endif 

