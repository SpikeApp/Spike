#import <Foundation/Foundation.h>

enum  G5ErrCode {
    G5Success           = 0,    /**< success    */
    G5ErrCodeCommon     = -1,   /**< error    */
};
enum  G5RespType {
    G5Received           =  0,    /**< received hexData  */
    G5UnRead             = -1,    /**< unread sensor*/
    G5Change             = -2,    /**< when miaomiao read another sensor*/
    G5SetIntervalSuccess = -6,    /**< set time interval success */
    G5SetIntervalFail    = -7,    /**< set time interval failed */
};


@interface G5ApiObject : NSObject

@end

@interface G5BaseResp : NSObject

@property (nonatomic, assign) NSInteger errCode;    /** error code */
@property (nonatomic, assign) enum G5RespType type; /** resp type */
@property (nonatomic, strong) NSString *errStr;     /** error str */
@property (nonatomic, strong) NSString *hexStr;     /** hex string */

@end










