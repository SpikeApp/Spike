#import "Context.h"

@interface Context ()

@end

@implementation Context

static FREContext _context;
static Context * instance;

+ (void) setContext:(FREContext) newContext {
    _context = newContext;
}

+ (FREContext) getContext{
    return _context;
}

@end


