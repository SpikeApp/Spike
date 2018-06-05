#import <Foundation/Foundation.h>

enum  FQErrCode {
    FQSuccess           = 0,    /**< success    */
    FQErrCodeCommon     = -1,   /**< error    */
};
enum  FQRespType {
    FQReceived           =  0,    /**< received hexData  */
    FQUnRead             = -1,    /**< unread sensor*/
    FQChange             = -2,    /**< when miaomiao read another sensor*/
    FQSetIntervalSuccess = -6,    /**< set time interval success */
    FQSetIntervalFail    = -7,    /**< set time interval failed */
};


@interface FQApiObject : NSObject

@end

@interface FQBaseResp : NSObject

@property (nonatomic, assign) NSInteger errCode;    /** error code */
@property (nonatomic, assign) enum FQRespType type; /** resp type */
@property (nonatomic, strong) NSString *errStr;     /** error str */
@property (nonatomic, strong) NSString *hexStr;     /** hex string */

@end










