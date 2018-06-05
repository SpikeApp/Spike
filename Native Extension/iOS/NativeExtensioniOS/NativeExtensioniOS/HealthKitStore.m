#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>
#import "FPANEUtils.h"
#import "HealthKitStore.h"


@interface HealthKitStore ()
@property (nonatomic, copy)  HKHealthStore *store;
@end

@implementation HealthKitStore

static HealthKitStore * instance;
HKQuantityType *bloodGlucoseType;
HKQuantityType *carbohydrateType;
HKQuantityType *insulinDeliveryType;
HKHealthStore *_store;

+ (HealthKitStore*) getInstance:(NSString*) iosVersion {
    if (instance == nil) {
        _store = [[HKHealthStore alloc] init];
        instance = [[HealthKitStore alloc] init];
         bloodGlucoseType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose];
         carbohydrateType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCarbohydrates];

        if (!([iosVersion hasPrefix:@"10"] || [iosVersion hasPrefix:@"9"] || [iosVersion hasPrefix:@"8"])) {//as of iOS 11 insulin is supported - assuming iOS7 will not occur anymore
            insulinDeliveryType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierInsulinDelivery];
        } else {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE HealthKitStore.m HealthKitStore not initializing insulinDeliveryType because ios version is lower than 11.0, verison = %@", iosVersion]);
            insulinDeliveryType = nil;
        }
        
        if ([_store authorizationStatusForType:bloodGlucoseType] != HKAuthorizationStatusSharingAuthorized
             ||
            [_store authorizationStatusForType:carbohydrateType] != HKAuthorizationStatusSharingAuthorized
             ||
            (insulinDeliveryType != nil && [_store authorizationStatusForType:insulinDeliveryType] != HKAuthorizationStatusSharingAuthorized)
           ) {
            [_store requestAuthorizationToShareTypes:[HealthKitStore dataTypesToWrite] readTypes:NULL completion:^(BOOL success, NSError *error) {
                if(error) {
                    FPANE_Log(@"spiketrace ANE HealthKitStore.m HealthKitStore authorization request error");
                } else {
                    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE HealthKitStore.m HealthKitStore authorization request result %@", success ? @"YES" : @"NO"]);
                }
            }];
        } else {
            FPANE_Log(@"spiketrace ANE HealthKitStore.m HealthKitStore already authorized");
        }
    }
    return instance;
}
             
+ (NSSet *) dataTypesToWrite {
    if (insulinDeliveryType != nil)
        return [NSSet setWithObjects:bloodGlucoseType,carbohydrateType,insulinDeliveryType, nil];
    else
        return [NSSet setWithObjects:bloodGlucoseType,carbohydrateType, nil];
}

+ (void) storeBloodGlucose:(double) valueInMgDL dateWithTimeIntervalSince1970:(NSDate *) date{
    HKUnit *mgPerdL = [HKUnit unitFromString:@"mg/dL"];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:mgPerdL doubleValue:valueInMgDL];
    
    HKQuantitySample *mySample = [HKQuantitySample quantitySampleWithType:bloodGlucoseType quantity:quantity startDate:date endDate:date metadata:nil];
    
    [_store saveObject:mySample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE HealthKitStore.m HealthKitStore Error while saving bloodglucose value, localizedDescription = %@, domain = %@", [error localizedDescription], [error domain]]);
            
        }
    }];    
}

+ (void) storeInsulinDelivery:(double) amount dateWithTimeIntervalSince1970:(NSDate *) date isBolus:(bool) bolus {
    if (insulinDeliveryType == nil) {//means lower than ios11
        FPANE_Log(@"spiketrace ANE HealthKitStore.m storeInsulinDelivery but insulinDeliveryType not supported");
        return;
    }
        
    HKUnit *unit = [HKUnit internationalUnit];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:amount];
    NSDictionary *metadata = nil;
    if (bolus) {
        metadata = @{HKMetadataKeyInsulinDeliveryReason:[NSNumber numberWithFloat: HKInsulinDeliveryReasonBolus]};
    } else {
        metadata = @{HKMetadataKeyInsulinDeliveryReason:[NSNumber numberWithFloat: HKInsulinDeliveryReasonBasal]};
    }
    
    HKQuantitySample *mySample = [HKQuantitySample quantitySampleWithType:insulinDeliveryType quantity:quantity startDate:date endDate:date metadata:metadata];

    
    [_store saveObject:mySample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE HealthKitStore.m HealthKitStore Error while saving insulin delivery value, localizedDescription = %@, domain = %@", [error localizedDescription], [error domain]]);
            
        }
    }];
}

+ (void) storeCarbs:(double) amount dateWithTimeIntervalSince1970:(NSDate *) date{
    HKUnit *unit = [HKUnit gramUnit];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:amount];

    HKQuantitySample *mySample = [HKQuantitySample quantitySampleWithType:carbohydrateType quantity:quantity startDate:date endDate:date metadata:nil];
    
    [_store saveObject:mySample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE HealthKitStore.m HealthKitStore Error while saving carbohydrate value, localizedDescription = %@, domain = %@", [error localizedDescription], [error domain]]);
            
        }
    }];
}

@end
