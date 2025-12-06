#import "TrackNumberFormatter.h"

@implementation TrackNumberFormatter
- (NSString*)stringForObjectValue:(id)anObject
{

    if (![anObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }

    SInt64 trackNumber = [anObject intValue];

    if (trackNumber != 0)
        return [NSString stringWithFormat:@"%i", trackNumber];
    else
        return @"";
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