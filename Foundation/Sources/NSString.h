/* 
   NSString.h

   Interface to string class.

   Copyright (C) 1995, 1996, 1997, 1998 Free Software Foundation, Inc.

   Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	1995
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSString
#define _mySTEP_H_NSString

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

#define NSMaximumStringLength	(INT_MAX-1)
#define NSHashStringLength		63

typedef unsigned short unichar;

@class NSArray;
@class NSCharacterSet;
@class NSData;
@class NSDictionary;
@class NSError;
@class NSMutableString;
@class NSURL;

enum 
{
	NSCaseInsensitiveSearch = 1,
	NSLiteralSearch			= 2,
	NSBackwardsSearch		= 4,
	NSAnchoredSearch		= 8,
	NSNumericSearch			= 64
};

typedef enum _NSStringEncoding				// O encoding defines a variable of
{											// type encoding that is undefined
	NSASCIIStringEncoding 			= 1,	// 0...127
	NSNEXTSTEPStringEncoding 		= 2,
	NSJapaneseEUCStringEncoding 	= 3,
	NSUTF8StringEncoding 			= 4,
	NSISOLatin1StringEncoding 		= 5,
	NSSymbolStringEncoding 			= 6,
	NSNonLossyASCIIStringEncoding 	= 7,	// 7-bit ASCII to rep all unichars
	NSShiftJISStringEncoding 		= 8,
	NSISOLatin2StringEncoding 		= 9,
	NSUnicodeStringEncoding 		= 10,
	NSWindowsCP1251StringEncoding 	= 11,
	NSWindowsCP1252StringEncoding 	= 12,	// WinLatin1
	NSWindowsCP1253StringEncoding 	= 13,
	NSWindowsCP1254StringEncoding 	= 14,
	NSWindowsCP1250StringEncoding 	= 15,
	NSISO2022JPStringEncoding 		= 21,
	NSMacOSRomanStringEncoding 		= 30,
	NSProprietaryStringEncoding 	= 65536,

	// other encodings
	NSCyrillicStringEncoding 		= 22,
	NSISOLatin3StringEncoding		= 100,
	NSISOLatin4StringEncoding,
	NSISOCyrillicStringEncoding,
	NSISOArabicStringEncoding,
	NSISOGreekStringEncoding,
	NSISOHebrewStringEncoding,
	NSISOLatin5StringEncoding,
	NSISOLatin6StringEncoding,
	NSISOLatin7StringEncoding,
	NSISOLatin8StringEncoding,
	NSISOLatin9StringEncoding
	
} NSStringEncoding;

enum {
	NSOpenStepUnicodeReservedBase = 0xF400
};

extern NSString *NSParseErrorException;

@interface NSString : NSObject  <NSCoding, NSCopying, NSMutableCopying>
{
@public
    char *_cString;
    unsigned int _count;
}

+ (const NSStringEncoding *) availableStringEncodings;
+ (NSStringEncoding) defaultCStringEncoding;
+ (NSString *) localizedNameOfStringEncoding:(NSStringEncoding)encoding;
+ (NSString *) localizedStringWithFormat:(NSString *)format, ...;
+ (NSString *) pathWithComponents:(NSArray *) components;
+ (id) string;
+ (id) stringWithCharacters:(const unichar*)chars length:(unsigned int)length;
+ (id) stringWithContentsOfFile:(NSString *)path;
+ (id) stringWithContentsOfFile:(NSString *)path
					   encoding:(NSStringEncoding)enc
						  error:(NSError **)error;
+ (id) stringWithContentsOfFile:(NSString *)path
				   usedEncoding:(NSStringEncoding *)enc
						  error:(NSError **)error;
+ (id) stringWithContentsOfURL:(NSURL*)url;
+ (id) stringWithContentsOfURL:(NSURL *)url
					  encoding:(NSStringEncoding)enc
						 error:(NSError **)error;
+ (id) stringWithContentsOfURL:(NSURL *)url
				  usedEncoding:(NSStringEncoding *)enc
						 error:(NSError **)error;
+ (id) stringWithCString:(const char*)byteString;
+ (id) stringWithCString:(const char *)cString
				encoding:(NSStringEncoding)enc;
+ (id) stringWithCString:(const char*)byteString
				  length:(unsigned int)length;
+ (id) stringWithFormat:(NSString*)format, ...;
+ (id) stringWithString:(NSString*)aString;
+ (id) stringWithUTF8String:(const char *)bytes;

- (BOOL) canBeConvertedToEncoding:(NSStringEncoding)encoding;
- (NSString*) capitalizedString;						// Changing Case
- (NSComparisonResult) caseInsensitiveCompare:(NSString*)aString;
- (unichar) characterAtIndex:(unsigned int)index;
- (NSString*) commonPrefixWithString:(NSString*)aString
							 options:(unsigned int)mask;
- (NSComparisonResult) compare:(NSString*)aString;		// Comparing Strings
- (NSComparisonResult) compare:(NSString*)aString	
					   options:(unsigned int)mask;
- (NSComparisonResult) compare:(NSString*)aString
					   options:(unsigned int)mask
						 range:(NSRange)aRange;
- (NSComparisonResult) compare:(NSString*)aString
					   options:(unsigned int)mask
						 range:(NSRange)aRange
						locale:(NSDictionary *)locale;
- (NSArray*) componentsSeparatedByString:(NSString*)separator;
- (const char*) cString;								// C Strings
- (unsigned int) cStringLength;
- (const char *) cStringUsingEncoding:(NSStringEncoding)encoding;
- (NSData*) dataUsingEncoding:(NSStringEncoding)encoding;
- (NSData*) dataUsingEncoding:(NSStringEncoding)encoding
		 allowLossyConversion:(BOOL)flag;
- (NSString *) decomposedStringWithCanonicalMapping;
- (NSString *) decomposedStringWithCompatibilityMapping;
- (NSString*) description;
- (double) doubleValue;
- (NSStringEncoding) fastestEncoding;
- (float) floatValue;									// Numeric Values
- (void) getCharacters:(unichar*)buffer;
- (void) getCharacters:(unichar*)buffer range:(NSRange)aRange;
- (void) getCString:(char*)buffer;
- (void) getCString:(char*)buffer maxLength:(unsigned int)maxLength;
- (BOOL) getCString:(char *)buffer maxLength:(unsigned)maxLength encoding:(NSStringEncoding)enc;
- (void) getCString:(char*)buffer
		  maxLength:(unsigned int)maxLength
			  range:(NSRange)aRange
	 remainingRange:(NSRange*)leftoverRange;
- (void) getLineStart:(unsigned int *)startIndex
				  end:(unsigned int *)lineEndIndex
		  contentsEnd:(unsigned int *)contentsEndIndex
			 forRange:(NSRange)aRange;
- (void) getParagraphStart:(unsigned *)startIndex
					   end:(unsigned *)endIndex
			   contentsEnd:(unsigned *)contentsEndIndex
				  forRange:(NSRange)range;
- (unsigned int) hash;
- (BOOL) hasPrefix:(NSString*)aString;
- (BOOL) hasSuffix:(NSString*)aString;
// - (id) init;
- (id) initWithBytes:(const void *)bytes
			  length:(unsigned)length
			encoding:(NSStringEncoding)enc;
- (id) initWithCharactersNoCopy:(unichar*)chars
						 length:(unsigned int)length
				   freeWhenDone:(BOOL)flag;
- (id) initWithBytesNoCopy:(void *)bytes
					length:(unsigned)length
				  encoding:(NSStringEncoding)enc
			  freeWhenDone:(BOOL)flag;
- (id) initWithCharacters:(const unichar*)chars
				   length:(unsigned int)length;
- (id) initWithCharactersNoCopy:(unichar *)chars
						 length:(unsigned)length
				   freeWhenDone:(BOOL)flag;
- (id) initWithContentsOfFile:(NSString*)path;
- (id) initWithContentsOfFile:(NSString *)path
					 encoding:(NSStringEncoding)enc
						error:(NSError **)error;
- (id) initWithContentsOfFile:(NSString *)path
				 usedEncoding:(NSStringEncoding *)enc
						error:(NSError **)error;
- (id) initWithContentsOfURL:(NSURL*)url;
- (id) initWithContentsOfURL:(NSURL *)url
					encoding:(NSStringEncoding)enc
					   error:(NSError **)error;   
- (id) initWithContentsOfURL:(NSURL *)url
				usedEncoding:(NSStringEncoding *)enc
					   error:(NSError **)error;
- (id) initWithCString:(const char*)byteString;
- (id) initWithCString:(const char *)cstring
			  encoding:(NSStringEncoding)enc;
- (id) initWithCString:(const char*)byteString
				length:(unsigned int)length;
- (id) initWithCStringNoCopy:(char*)byteString
					  length:(unsigned int)length
				freeWhenDone:(BOOL)flag;
- (id) initWithData:(NSData*)data encoding:(NSStringEncoding)encoding;
- (id) initWithFormat:(NSString*)format, ...;
- (id) initWithFormat:(NSString*)format arguments:(va_list)args;
- (id) initWithFormat:(NSString*)format locale:(NSDictionary*)dictionary, ...;
- (id) initWithFormat:(NSString*)format
			   locale:(NSDictionary*)dictionary
			arguments:(va_list)argList;
- (id) initWithString:(NSString*)string;
- (id) initWithUTF8String:(const char *)bytes;
- (int) intValue;
- (NSInteger) integerValue;
- (BOOL) isEqualToString:(NSString*)aString;
- (unsigned int) length;
- (unsigned) lengthOfBytesUsingEncoding:(NSStringEncoding)enc;	// exact
- (NSRange) lineRangeForRange:(NSRange)aRange;
- (NSComparisonResult) localizedCaseInsensitiveCompare:(NSString *)string;
- (NSComparisonResult) localizedCompare:(NSString *)string;
- (const char *) lossyCString;
- (NSString*) lowercaseString;
- (unsigned) maximumLengthOfBytesUsingEncoding:(NSStringEncoding)enc;	// estimate
- (NSRange) paragraphRangeForRange:(NSRange)range;
- (NSString *) precomposedStringWithCanonicalMapping;
- (NSString *) precomposedStringWithCompatibilityMapping;
- (id) propertyList;									// Property List
- (NSDictionary*) propertyListFromStringsFileFormat;
- (NSRange) rangeOfCharacterFromSet:(NSCharacterSet*)aSet;
- (NSRange) rangeOfCharacterFromSet:(NSCharacterSet*)aSet
							options:(unsigned int)mask;
- (NSRange) rangeOfCharacterFromSet:(NSCharacterSet*)aSet
							options:(unsigned int)mask
							  range:(NSRange)aRange;
- (NSRange) rangeOfComposedCharacterSequenceAtIndex:(unsigned int)anIndex;
- (NSRange) rangeOfString:(NSString*)string;
- (NSRange) rangeOfString:(NSString*)string options:(unsigned int)mask;
- (NSRange) rangeOfString:(NSString*)aString
				  options:(unsigned int)mask
					range:(NSRange)aRange;
- (NSStringEncoding) smallestEncoding;
- (NSString *) stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding) encoding;
- (NSString *) stringByAppendingFormat:(NSString*)format,...;
- (NSString *) stringByAppendingString:(NSString*)aString;
- (NSString *) stringByPaddingToLength:(unsigned)len withString:(NSString *) pad startingAtIndex:(unsigned) index;
- (NSString *) stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding) encoding;
- (NSString *) stringByTrimmingCharactersInSet:(NSCharacterSet *)set;
- (NSString *) substringFromIndex:(unsigned int)index;
- (NSString *) substringToIndex:(unsigned int)index;
- (NSString *) substringWithRange:(NSRange)aRange;
- (NSString *) uppercaseString;
- (const char *) UTF8String;
- (BOOL) writeToFile:(NSString *)filename 
		  atomically:(BOOL)useAuxiliaryFile;
- (BOOL) writeToFile:(NSString *)path
		  atomically:(BOOL)useAuxiliaryFile
			encoding:(NSStringEncoding)enc
			   error:(NSError **)error;
- (BOOL) writeToURL:(NSURL *)url
		 atomically:(BOOL)useAuxiliaryFile;
- (BOOL) writeToURL:(NSURL *)url
		 atomically:(BOOL)useAuxiliaryFile
		   encoding:(NSStringEncoding)enc
			  error:(NSError **)error;

@end

#import <Foundation/NSPathUtilities.h>

@interface NSMutableString : NSString

+ (NSMutableString*) stringWithCapacity:(unsigned)capacity;

- (void) appendFormat:(NSString*)format, ...;
- (void) appendString:(NSString*)aString;
- (void) deleteCharactersInRange:(NSRange)range;
- (id) initWithCapacity:(unsigned)capacity;
- (void) insertString:(NSString*)aString atIndex:(unsigned)index;
- (void) replaceCharactersInRange:(NSRange)range withString:(NSString*)aString;
- (unsigned int) replaceOccurrencesOfString:(NSString *)replace
								 withString:(NSString*) by
									options:(unsigned int) opts
									  range:(NSRange) searchRange;
- (void) setString:(NSString*)aString;

@end

#ifdef __APPLE__	// this one is required by gcc on MacOS X

extern void *_NSConstantStringClassReference;

@interface NSSimpleCString : NSString
{
	@protected
}
@end

@interface NSConstantString : NSSimpleCString
{
	@protected
	unsigned numBytes;
    char *bytes;
}
@end

#endif

///// Implementation private classes - should not be defined in public header if possible! ==> NSString.m

@interface GSBaseCString : NSString 
@end

@interface NXConstantString : GSBaseCString		// compiler thinks that @"..." strings are NXConstantString
@end

#endif /* _mySTEP_H_NSString */
