#import "DurationFormatter.h"

@implementation DurationFormatter

- (NSString*)stringForObjectValue:(id)anObject
{

    if (![anObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }

    SInt64 duration = [anObject longValue];

    if (duration < 0) {
        duration = -duration;
        return [NSString stringWithFormat:@"-%02i:%02i", duration / 60, duration % 60];
    } else
        return [NSString stringWithFormat:@"%02i:%02i", duration / 60, duration % 60];
}

- (NSAttributedString*)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary*)attributes
{
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:[self stringForObjectValue:anObject]
                                                                  attributes:attributes];
    return [attrStr autorelease];
}

- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string errorDescription:(NSString**)error
{
    // No editing facility provided
    return NO;
}
@end