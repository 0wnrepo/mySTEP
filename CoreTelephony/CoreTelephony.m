//
//  CTCall.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "CTPrivate.h"

NSString const *CTCallStateDialing=@"CTCallStateDialing";
NSString const *CTCallStateIncoming=@"CTCallStateIncoming";
NSString const *CTCallStateConnected=@"CTCallStateConnected";
NSString const *CTCallStateDisconnected=@"CTCallStateDisconnected";

// FIXME: the call center shouldn't be a singleton!
// reason: there may be multiple and different delegates for each instance

@implementation CTCallCenter

/* NIB-safe Singleton pattern */

#define SINGLETON_CLASS		CTCallCenter
#define SINGLETON_VARIABLE	callCenter
#define SINGLETON_HANDLE	callCenter

/* static part */

static SINGLETON_CLASS * SINGLETON_VARIABLE = nil;

+ (id) allocWithZone:(NSZone *)zone
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		return [super allocWithZone:zone];
	}
    return SINGLETON_VARIABLE;
}

- (id) copyWithZone:(NSZone *)zone { return self; }

- (id) retain { return self; }

- (unsigned) retainCount { return UINT_MAX; }

- (void)release {}

- (id) autorelease { return self; }

+ (SINGLETON_CLASS *) SINGLETON_HANDLE
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		[[self alloc] init];
    }
    return SINGLETON_VARIABLE;
}

/* customized part */

- (id) init
{
	//    Class myClass = [self class];
	//    @synchronized(myClass)
	{
	if (!SINGLETON_VARIABLE && (self = [super init]))
		{
		SINGLETON_VARIABLE = self;
		/* custom initialization here */
		CTModemManager *m=[CTModemManager modemManager];
		currentCalls=[[NSMutableSet alloc] initWithCapacity:10];
		[CTTelephonyNetworkInfo telephonyNetworkInfo];	// initialize
		[m checkPin:nil];		// could read from a keychain if specified - nil asks the user
		}
    }
    return self;
}

- (void) dealloc
{ // should not be possible for a singleton!
	NSLog(@"CTCallCenter dealloc");
	abort();
	[currentCalls release];
	[super dealloc];
	callCenter=nil;
}

#undef SINGLETON_CLASS
#undef SINGLETON_VARIABLE
#undef SINGLETON_HANDLE

- (NSSet *) currentCalls; { return currentCalls; }

- (id <CTCallCenterDelegate>) delegate; { return delegate; }
- (void) setDelegate:(id <CTCallCenterDelegate>) d; { delegate=d; }

// see ANNEX G of GSM 07.07 how voice dialling works */

- (CTCall *) dial:(NSString *) number;
{
	CTModemManager *mm=[CTModemManager modemManager];
	// check if we are already connected
	// check string for legal characters (0-9, +, #, *, G/g, I/i, space or someone could inject arbitraty AT commands...)
	NSString *err;
	NSString *cmd=[NSString stringWithFormat:@"ATD%@;", number];	// initiate a voice call
	[mm runATCommand:@"AT+COLP=1"];	// report phone number and make ATD blocking
#if 1	// Run before setting up the call. Modem mutes all voice signals if we do that *during* a call
	[mm runATCommand:@"AT_OPCMENABLE=1"];
	[mm runATCommand:@"AT_OPCMPROF=0"];	// default "handset"
	[mm runATCommand:@"AT+VIP=0"];
#endif
	if([mm runATCommand:cmd target:nil action:NULL timeout:120.0])	// ATD blocks only until connection is setup and remote ringing starts; so don't timeout too early!
		{ // successfull call setup
			CTCall *call=[[CTCall new] autorelease];
			[call _setCallState:kCTCallStateDialing];
			[call _setPeerPhoneNumber:number];	// should this come from AT+COLP (later)?
			[currentCalls addObject:call];
			// notify delegate
			return call;
		}
	err=[mm error];
#if 1
	NSLog(@"dial error: %@", err);
#endif
	/*
	 error responses may be
	 ERROR
	 NO CARRIER (kein Anschluß unter dieser Nummer)
	 BUSY
	 NO ANSWER
	 CONNECT
	 
	 could also use AT+CEER to get a more precise information
	 */
	if([err isEqualToString:@""])
		{
		
		}
	return nil;	// not successfull
}

- (BOOL) sendSMS:(NSString *) message toNumber:(NSString *) number;
{ // send a SMS
	// AT+CMGS="91234567"<CR>Sending text messages is easy.<Ctrl+z>
	// +CMS ERROR: 304
	
	return NO;
}

// FIXME: in State-Machine einbauen - ein Befehl fertig triggert den nächsten...
// und letzter triggert nach Timeout den ersten
// also eine polling-queue
// oder einfacher: Timer alle 5 sekunden macht den jeweils nächsten...

- (void) poll
{ // timer triggered commands (because there is no unsolicited notification)
	static int next;
	switch(next++ % 4) {
		case 0:
			[[CTModemManager modemManager] runATCommand:@"AT_OBLS"];	// get SIM status (removed etc.)
			break;
		case 1:
			[[CTModemManager modemManager] runATCommand:@"AT_OBSI"];	// base station location
			break;
		case 2:
			[[CTModemManager modemManager] runATCommand:@"AT_ONCI?"];	// neighbouring base stations
			break;
		case 3:
			[[CTModemManager modemManager] runATCommand:@"AT+CMGL=\"REC UNREAD\""];	// received SMS
			// process +CMGL: responses
			// [delegate callCenter:self didReceiveSMS:(NSString *) message fromNumber:(NSString *) sender attributes:(NSDictionary *) dict];
			// Dabei könnte ein NSDict mit aller Zusatzinfo (Uhrzeit - Achtung TimeZone ist in 15min-Schritten, AT+CSDH=1) mitgegeben werden.
			// same for cell broadcasts (?) AT+CPMS="BM"
			break;			
	}
	[self performSelector:_cmd withObject:nil afterDelay:5.0];
}

@end

@implementation CTCall

- (void) dealloc
{
	if(callState != kCTCallStateDisconnected)
		[self terminate];
	[callID release];
	[peer release];
	[super dealloc];
}

- (NSString *) callID;
{
	return callID;	// should be a unique number
}

- (NSString *) callState;
{
	switch(callState)
	{
		case kCTCallStateDialing: return (NSString *) CTCallStateDialing;
		case kCTCallStateIncoming: return (NSString *) CTCallStateIncoming;
		case kCTCallStateConnected: return (NSString *) CTCallStateConnected;
		case kCTCallStateDisconnected: return (NSString *) CTCallStateDisconnected;
	}
	return @"callState: unknown";
}

- (int) _callState;
{
	return callState;
}

- (void) _setCallState:(int) state
{
	callState=state;
}

- (NSString *) peerPhoneNumber
{ // caller ID or called ID
	// can we read that from the Modem so that we never have to set it?
	return peer;
}

- (void) _setPeerPhoneNumber:(NSString *) number
{
	[peer autorelease];
	peer=[number retain];
}

- (void) terminate;
{
	[[CTModemManager modemManager] runATCommand:@"AT+CHUP"];
	system("killall arecord aplay");	// stop audio forwarding
	// error handling?
	[[CTModemManager modemManager] runATCommand:@"AT_OPCMENABLE=0"];	// disable PCM clocks to save some energy
}

- (void) hold;
{
	// anytime
}

- (void) accept;	// if incoming
{
	// ATA?
	// if CTCallStateIncoming
	[[CTModemManager modemManager] runATCommand:@"ATA"];
	// start PCM
}

- (void) reject;	// if incoming
{
	// if CTCallStateIncoming
	[self terminate];
}

- (void) divert;
{
	// if CTCallStateIncoming
}

// set 
- (void) handsfree:(BOOL) flag;	// switch on handsfree speakers (or headset?)
{
#if 1
	NSLog(@"handsfree: %d", flag);
#endif
	// if CTCallStateConnected (?)
	if(flag)
		{
#if 0	// does not work with Modem Firmware during a voice call
		[[CTModemManager modemManager] runATCommand:@"AT_OPCMPROF=2"];
#endif
		system("amixer set HandsfreeL on;"
			   "amixer set HandsfreeR on;"
			   "amixer set 'HandsfreeL Mux' AudioL2;"
			   "amixer set 'HandsfreeR Mux' AudioR2");
		}
	else
		{
		system("amixer set HandsfreeL off;"
			   "amixer set HandsfreeR off");
#if 0	// does not work with Modem Firmware during a voice call
		[[CTModemManager modemManager] runATCommand:@"AT_OPCMPROF=0"];
#endif
		}
}

- (void) mute:(BOOL) flag;	// mute microphone
{
	/* return */ [[CTModemManager modemManager] runATCommand:[NSString stringWithFormat:@"AT+CMUT=%d", flag != 0]];
	// if CTCallStateConnected
	// switch amixer
}

- (void) volume:(float) value;	// general volume (earpiece, handsfree, headset)
{
	/* return */ [[CTModemManager modemManager] runATCommand:[NSString stringWithFormat:@"AT+CLVL=%d", (int) (7.0*value)]];
	// if CTCallStateConnected
	// switch amixer
}

- (void) sendDTMF:(NSString *) digit
{ // 0..9, a-c, #, *
	if([digit length] != 1)
		return;	// we could loop over all digits with a little delay
	// check if this is a valid digit
	NSLog(@"send DTMF: %@", digit);
	// if this already blocks until the tone has been sent, we can simply loop over all characters
	if(![[CTModemManager modemManager] runATCommand:[NSString stringWithFormat:@"AT+VTS=%@", digit]] != CTModemOk)
		;
}

@end

@implementation CTCarrier

- (void) dealloc
{
	[carrierName release];
	[isoCountryCode release];
	[mobileCountryCode release];
	[carrierName release];
	[cellID release];
	[super dealloc];
}

- (NSString *) carrierName; { return carrierName; }
- (NSString *) isoCountryCode; { return isoCountryCode; }
- (NSString *) mobileCountryCode; { return mobileCountryCode; }
- (NSString *) mobileNetworkCode; { return mobileNetworkCode; }
- (BOOL) allowsVOIP; { return YES; }

- (float) strength; { return strength; }	// signal strength (0..1.0)
- (float) dBm; { return dBm; }		// signal strength (in dBm)
- (float) networkSpeed; { return networkType; }	// 1.0, 2.0, 2.5, 3.0, 3.5 etc.
- (NSString *) cellID;	 { return cellID; }	// current cell ID
- (BOOL) canChoose; { return YES; }	// is permitted to select (if there are alternatives)

// - (id) initWithName:(NSString *) name isoCode etc. --- oder initWithResponse:

- (void) _setCarrierName:(NSString *) n; { [carrierName autorelease]; carrierName=[n retain]; }
- (void) _setStrength:(float) s; { strength=s; }
- (void) _setNetworkType:(float) s; { networkType=s; }
- (void) _setdBm:(float) s; { dBm=s; }
- (void) _setCellID:(NSString *) n; { [cellID autorelease]; cellID=[n retain]; }

- (void) choose;
{ // make the current carrier if there are several options to choose
	return;
}

- (void) connectWWAN:(BOOL) flag;	// 0 to disconnect
{
	unsigned int context=1;
	CTModemManager *mm=[CTModemManager modemManager];
#if 1
	NSLog(@"connectWWAN %d", flag);
#endif
	if(flag && [self WWANstate] != CTCarrierWWANStateConnected)
		{ // set up WWAN connection
			// FIXME: this should be carrier specific!!!
			// see: http://blog.mobilebroadbanduser.eu/page/Worldwide-Access-Point-Name-%28APN%29-list.aspx#403
			NSString *apn=@"web.vodafone.de";	// lookup in some database? Or let the user choose by a prefPane?
			NSString *protocol=@"IP";	// either "IP" or "PPP"
			// FXIME: make configurable if user wants to use 3G
			[mm runATCommand:@"AT_OPSYS=3,2"];	// register to any network in any mode
			[mm runATCommand:@"AT_OWANCALLUNSOL=1"];	// receive unsolicited _OWANCALL messages
			[mm runATCommand:[NSString stringWithFormat:@"AT+CGDCONT=%u,\"%@\",\"%@\"", context, protocol, apn]];
			// secure: 0=no, 1=pap, 2=chap
			// [mm runATCommand:[NSString stringWithFormat:@"AT_OPDPP=%u,%u,\"%@\",\"%@\"", context, secure, passwd, user]];
			[mm runATCommand:[NSString stringWithFormat:@"AT_OWANCALL=%u,1,1", context]];	// context #1, start, send unsolicited response
		}
	else if(!flag && [self WWANstate] != CTCarrierWWANStateDisconnected)
		{ // disable WWAN connection
			system("ifconfig hso0 down");	// we could make the ifconfig up/down trigger our daemon...
			sleep(1);
			[mm runATCommand:[NSString stringWithFormat:@"AT_OWANCALL=%u,0,1", context]];	// stop
		}
}

- (CTCarrierWWANState) WWANstate;
{ // ask the modem
	// FIXME: this may be a little slow if we call it too often
	// so we should cache the state and update only if last value is older than e.g. 1 second
#if 1
	char bfr[512];
	FILE *f=popen("ifconfig -s | fgrep hso0", "r");
	NSLog(@"WWANstate f=%p", f);
	if(!f)
		return CTCarrierWWANStateUnknown;
	fgets(bfr, sizeof(bfr)-1, f);
	pclose(f);
	NSLog(@"WWANstate strlen=%d", strlen(bfr));
	return strlen(bfr) > 10?CTCarrierWWANStateConnected:CTCarrierWWANStateDisconnected;


#else
	// does not work well since it may get called recursively (why???) - but would be the correct way of checking connectivity
	
	CTModemManager *mm=[CTModemManager modemManager];
	NSString *r=[mm runATCommandReturnResponse:@"AT_OWANCALL?"];
	NSArray *a=[r componentsSeparatedByString:@" "];	// r is nil on errors
#if 1
	NSLog(@"a=%@", a);
#endif
	if([a count] >= 2)
		{
		return [[a objectAtIndex:1] intValue];	// 0..3
		}
#endif
	return CTCarrierWWANStateUnknown;
}

@end

@implementation CTTelephonyNetworkInfo

// FIXME: is this really a Singleton???
// if not, we can have multiple delegates

/* NIB-safe Singleton pattern */

#define SINGLETON_CLASS		CTTelephonyNetworkInfo
#define SINGLETON_VARIABLE	telephonyNetworkInfo
#define SINGLETON_HANDLE	telephonyNetworkInfo

/* static part */

static SINGLETON_CLASS * SINGLETON_VARIABLE = nil;

+ (id) allocWithZone:(NSZone *) zone
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		return [super allocWithZone:zone];
	}
    return SINGLETON_VARIABLE;
}

- (id) copyWithZone:(NSZone *) zone { return self; }

- (id) retain { return self; }

- (unsigned) retainCount { return UINT_MAX; }

- (void) release {}

- (id) autorelease { return self; }

+ (SINGLETON_CLASS *) SINGLETON_HANDLE
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		[[self alloc] init];
    }
    return SINGLETON_VARIABLE;
}

/* customized part */

- (id) init
{
	//    Class myClass = [self class];
	//    @synchronized(myClass)
	{
	if (!SINGLETON_VARIABLE && (self = [super init]))
		{
		CTModemManager *m;
		SINGLETON_VARIABLE = self;
		/* custom initialization here */
		subscriberCellularProvider=[CTCarrier new];	// create default entry
		currentNetwork=[subscriberCellularProvider retain];	// default: the same
		[subscriberCellularProvider _setCarrierName:@"No Carrier"];	// default if we can't read the SIM
		m=[CTModemManager modemManager];
		[m setUnsolicitedTarget:self action:@selector(processUnsolicitedInfo:)];
		}
	}
    return self;
}

- (void) dealloc
{ // should not be possible for a singleton!
	NSLog(@"CTTelephonyNetworkInfo dealloc");
	abort();
	[subscriberCellularProvider release];
	[super dealloc];
}

#undef SINGLETON_CLASS
#undef SINGLETON_VARIABLE
#undef SINGLETON_HANDLE

- (void) _processUnsolicitedInfo:(NSString *) line
{
#if 1
	NSLog(@"processUnsolicitedInfo: %@", line);
#endif
	if(!line) return;	// if called with result from directly running a command
	if([line hasPrefix:@"RING"] || [line hasPrefix:@"+CRING:"])
		{
		// incoming call
		NSLog(@"incoming call: %@", line);
		// decode CLIP information
		// create a new call and notify
		// FIXME: this message may repeat and end without other notice
		return;
		}
	if([line hasPrefix:@"BUSY"])
		{
		NSEnumerator *e=[[[CTCallCenter callCenter] currentCalls] objectEnumerator];
		CTCall *call;
		NSLog(@"busy: %@", line);
		while((call=[e nextObject]))
			{ // update connection state to connected
				if([call _callState] == kCTCallStateDialing)
					{ // found the call that was dialling
						[call _setCallState:kCTCallStateDisconnected];	// well, it was busy
						[[[CTCallCenter callCenter] delegate] callCenter:[CTCallCenter callCenter] handleCall:call];	// notify through CallCenter
						break;
					}
			}
		return;
		}
	if([line hasPrefix:@"NO CARRIER"])
		{
		NSEnumerator *e=[[[CTCallCenter callCenter] currentCalls] objectEnumerator];
		CTCall *call;
		NSLog(@"remote hangup: %@", line);
		while((call=[e nextObject]))
			{ // update connection state to connected
				if([call _callState] == kCTCallStateDialing)
					{ // found the call that was dialling
						[call _setCallState:kCTCallStateDisconnected];	// well, it was rejected
						[[[CTCallCenter callCenter] delegate] callCenter:[CTCallCenter callCenter] handleCall:call];	// notify through CallCenter
						break;
					}
				if([call _callState] == kCTCallStateConnected)
					{ // found the call that was established
						system("killall arecord aplay");	// stop audio forwarding
						// error handling?
						[[CTModemManager modemManager] runATCommand:@"AT_OPCMENABLE=0"];	// disable PCM clocks to save some energy
						[call _setCallState:kCTCallStateDisconnected];
						[[[CTCallCenter callCenter] delegate] callCenter:[CTCallCenter callCenter] handleCall:call];	// notify through CallCenter
						break;
					}
			}
		return;
		}
	if([line hasPrefix:@"+CBM:"])
		{
		NSLog(@"cell broadcast message: %@", line);
		return;
		}
	if([line hasPrefix:@"+COLP:"])
		{
		NSEnumerator *e=[[[CTCallCenter callCenter] currentCalls] objectEnumerator];
		CTCall *call;
		while((call=[e nextObject]))
			{ // update connection state to connected
				if([call _callState] == kCTCallStateDialing)
					{ // found the call that was dialling
					[call _setCallState:kCTCallStateConnected];
					[[[CTCallCenter callCenter] delegate] callCenter:[CTCallCenter callCenter] handleCall:call];	// notify through CallCenter
					break;
					}
			}
#if 1
		NSLog(@"connection established: %@", call);
#endif
		system("amixer set 'DAC1 Analog' off;"
			   "amixer set 'DAC2 Analog' on;"
			   //"amixer set  'Codec Operation Mode' 'Option 1 (audio)'");
			   "amixer set  'Codec Operation Mode' 'Option 2 (voice/audio)'");
		system("amixer set Earpiece 100%;"
			   "amixer set 'Earpiece Mixer AudioL2' on;"
			   /* "amixer set 'Earpiece Mixer AudioR2' off;" -- does not exist */
			   "amixer set 'Earpiece Mixer Voice' off");
		system("amixer set 'Analog' 5;"
			   "amixer set TX1 'Analog';"
			   "amixer set 'TX1 Digital' 12;"
			   "amixer set 'Analog Left AUXL' nocap;"
			   "amixer set 'Analog Right AUXR' nocap;"
			   "amixer set 'Analog Left Main Mic' cap;"
			   "amixer set 'Analog Left Headset Mic' nocap");
#if 0	// does not work! Modem mutes all voice signals if we do that *during* a call
		CTModemManager *mm=[CTModemManager modemManager];
		[mm runATCommand:@"AT_OPCMENABLE=1"];
		[mm runATCommand:@"AT_OPCMPROF=0"];	// default "handset"
		[mm runATCommand:@"AT+VIP=0"];
#endif
		[call handsfree:YES];	// switch profile and enable speakers
		[call volume:1.0];
		
		// FIXME: recording a phone call should only be possible under active user's control
		
		system("killall arecord aplay;"	// stop any running audio forwarding
			   "arecord -fS16_LE -r8000 | aplay -Dhw:1,0 &"	// forward microphone -> network
			   "arecord -Dhw:1,0 -fS16_LE -r8000 | aplay &"	// forward network -> handset/earpiece
			   );
		return;
		}
	if([line hasPrefix:@"_OPON:"])
		{ // current visited network - _OPON: <cs>,<oper>,<src>
			// cs=8bit code
			// src=3 -> SE13 hex format
			// src=4 -> MCCMNC in decimal
			CTTelephonyNetworkInfo *ni=[CTTelephonyNetworkInfo telephonyNetworkInfo];
			CTCarrier *carrier=[ni subscriberCellularProvider];
			NSScanner *sc=[NSScanner scannerWithString:line];
			NSString *cs=@"unknown";
			NSString *name=@"unknown";
			NSMutableString *s;
			int src;
			NSLog(@"visited network: %@", line);
			// Parameterliste kann auch leer sein!
			// => Visited Network verloren gegangen
			// wenn [ni currentNetwork] != nil -> löschen
			[sc scanString:@"_OPON: \"" intoString:NULL];
			[sc scanUpToString:@"," intoString:&cs];
			[sc scanString:@"," intoString:NULL];
			[sc scanUpToString:@"," intoString:&name];
			[sc scanString:@"," intoString:NULL];
			if(![sc scanInt:&src] || src != 3)
				return;
			s=[NSMutableString string];
			while([name length] >= 2)
				{ // eat each 2 characters
				unichar c1=[name characterAtIndex:0];
				unichar c2=[name characterAtIndex:1];
				c1=(c1 > '9') ? tolower(c1)-'a'+10 : c1 - '0';
				c2=(c2 > '9') ? tolower(c2)-'a'+10 : c2 - '0';
				[s appendFormat:@"%c", (c1<<4)+c2];
				name=[name substringFromIndex:2];
				}
			name=s;
#if 1
			NSLog(@"carrier name=%@ delegate=%@", name, [ni delegate]);
#endif
			// neuen Carrier in [ni currentNetwork] eintragen
			// [carrier _setCarrierName:name];
			[[ni delegate] subscriberCellularProviderDidUpdate:carrier];
			return;
		}
	if([line hasPrefix:@"_OSIGQ:"] || [line hasPrefix:@"+CSQ:"])
		{ // signal quality - _OSIGQ: 2*<rssi>-113dBm,<ber> (ber=99)
			int dbm=[[[line componentsSeparatedByString:@" "] lastObject] intValue];
			if(dbm == 99) dbm=(113-999)/2;	// show -999 dBm
			[currentNetwork _setdBm:2.0*dbm-113.0];
#if 1
			NSLog(@"ni=%@", currentNetwork);
			NSLog(@"ni.delegate=%@", delegate);
#endif
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OEANT:"])
		{ // antenna level - _OEANT: <n> (0..5 but 4 is the maximum ever reported)
			float strength=[[line substringFromIndex:8] floatValue]/4.0;
			if(strength > 1.0) strength=1.0;	// limit
			[currentNetwork _setStrength:strength];
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OCTI:"])
		{ // GSM/EDGE cell type - _OCTI: <n> (0..3)
#if 1
			NSLog(@"GSM capability: %@", line);
#endif
			switch([[line substringFromIndex:8] intValue]) {
				case 1:
					[currentNetwork _setNetworkType:2.0];	// GSM
					break;
				case 2:
					[currentNetwork _setNetworkType:2.5];	// GPRS
					break;
				case 3:
					[currentNetwork _setNetworkType:2.75];	// EDGE - see http://en.wikipedia.org/wiki/2G#Evolution
					break;
				default:
					[currentNetwork _setNetworkType:0.0];	// unknown
			}
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OUWCTI:"])
		{ // WDMA cell type - _OUWCTI: <n> (0..4)
#if 1
			NSLog(@"WCDMA capability: %@", line);
#endif
			switch([[line substringFromIndex:8] intValue]) { // see http://3g4g.blogspot.com/2007/05/3g-39g.html
				default:
					return;	// non-wcdma - don't overwrite
				case 1:
					[currentNetwork _setNetworkType:3.0];	// WCDMA
					break;
				case 2:
					[currentNetwork _setNetworkType:3.5];	// WCDMA+HSDPA
					break;
				case 3:
					[currentNetwork _setNetworkType:3.6];	// WCDMA+HSUPA
					break;
				case 4:
					[currentNetwork _setNetworkType:3.75];	// WCDMA+HSDPA+HSUPA
					break;
			}
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OSSYSI:"])
		{ // selected system: 0=GSM, 2=UTRAN, 3=No Service
			// notify through CTCarrier/CTTelephonyNetworkInfo
			NSLog(@"selected system: %@", line);
			return;
		}
	if([line hasPrefix:@"_OUHCIP:"])
		{ // HSDPA call in progress: 1
			// notify through CTCarrier/CTTelephonyNetworkInfo
			NSLog(@"HSDPA: %@", line);
			return;
		}
	if([line hasPrefix:@"_OPATEMP:"])
		{ // PA temperature
			NSLog(@"PA TEMP: %@", line);
			paTemp=[[[line componentsSeparatedByString:@" "] objectAtIndex:1] intValue];
			// check for overtemperature and pop up some alert
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OWANCALL:"])
		{ // internet connection state did change
			int state=[[[line componentsSeparatedByString:@","] lastObject] intValue];	// connection state
			unsigned int context=1;	// get from _OWANCALL: message
			if(state == 0)
				{ // became disconnected
					NSMutableArray *resolv=[[[NSString stringWithContentsOfFile:@"/etc/resolv.conf"] componentsSeparatedByString:@"\n"] mutableCopy];
					unsigned int i=[resolv count];
					while(i-- > 0)
						{
						if([[resolv objectAtIndex:i] hasSuffix:@" # wwan"])
							[resolv removeObjectAtIndex:i];	// remove wwan config
						}
#if 1
					NSLog(@"new resolv.conf: %@", resolv);
#endif
					[resolv writeToFile:@"/etc/resolv.conf" atomically:NO];
					[resolv release];
				}
			else if(state == 1)
				{ // became connected
					NSString *data=[[CTModemManager modemManager] runATCommandReturnResponse:[NSString stringWithFormat:@"AT_OWANDATA=%u", context]];	// e.g. _OWANDATA: 1, 10.152.124.183, 0.0.0.0, 193.189.244.225, 193.189.244.206, 0.0.0.0, 0.0.0.0,144000
					NSArray *a=[data componentsSeparatedByString:@","];
#if 1
					NSLog(@"Internet config: %@", a);
#endif
					if([a count] == 8)
						{ // format as expected: <c>, <ip>, <gw>, <dns1>, <dns2>, <nbns1>, <nbns2>, <csp>
							NSMutableString *resolv=[NSMutableString stringWithContentsOfFile:@"/etc/resolv.conf"];
							// FIXME: process <gw>
							NSString *cmd=[NSString stringWithFormat:@"ifconfig hso0 '%@' netmask 255.255.255.255 up",
										   [[a objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
#if 1
							NSLog(@"system: %@", cmd);
#endif
							system([cmd UTF8String]);
							// check for errors
							if(!resolv) resolv=[NSMutableString string];
							[resolv appendFormat:@"nameserver %@ # wwan\n",
							 [[a objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
							[resolv appendFormat:@"nameserver %@ # wwan\n",
							 [[a objectAtIndex:4] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
							// FIXME: the network interface namer daemon should collect all DNS entries for interfaces coming and going
							// i.e. we should write the DNS entries into that database (/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist)
							// and trigger the interface namer for an update
							// or add interface-specific record(s) to /etc/network/interfaces
							
							// notify connection speed [[a objectAtIndex:7] intValue] in kbit/s
							
#if 1
							NSLog(@"new resolv.conf: %@", resolv);
#endif
							[resolv writeToFile:@"/etc/resolv.conf" atomically:NO];
#if 1
							system("route add default hso0");
							// FIXME: this should be done by Sharing&Network setup (i.e. only ONE connection can/should be the -o)
							[@"1" writeToFile:@"/proc/sys/net/ipv4/ip_forward" atomically:NO];	// enable forwarding
							system("iptables -t nat -A POSTROUTING -o hso0 -j MASQUERADE");
#endif
						}	
				}
			else 
				{ // error
					NSString *error=[[CTModemManager modemManager] runATCommandReturnResponse:@"AT_OWANNWERROR?"];
#if 1
					NSLog(@"WWAN error=%@", error);
#endif
				}
			// FIXME: how do we know the "carrier"?
			//			[[[CTTelephonyNetworkInfo telephonyNetworkInfo] delegate] currentNetworkDidUpdate:self];	// notify				
			[delegate signalStrengthDidUpdate:currentNetwork];
		}
	// the following responses are not really "unsolicted" but are handled as if they were
	if([line hasPrefix:@"_ONCI:"])
		{ // neighbour cell info
			// notify through CTCarrier/CTTelephonyNetworkInfo
			NSLog(@"neighbour cell: %@", line);
			return;
		}
	if([line hasPrefix:@"_OBSI:"])
		{ // base station location - _OBSI=<id>,<lat>,<long>
			// notify through CTCarrier/CTTelephonyNetworkInfo
			NSLog(@"base station location: %@", line);
			// forward to CLLocation?
			return;
		}
	if([line hasPrefix:@"_OSIMOP:"])
		{ // home plnm - _OSIMOP: “<long_op>”,”<short_op>”,”<MCC_MNC>”
			NSScanner *sc=[NSScanner scannerWithString:line];
			NSString *name=@"unknown";
			// FIXME: response does not necessarily enclose args in quotes!
			[sc scanString:@"_OSIMOP: \"" intoString:NULL];
			[sc scanUpToString:@"\"" intoString:&name];
			[subscriberCellularProvider _setCarrierName:name];
#if 1
			NSLog(@"carrier name=%@", name);
#endif
			[delegate subscriberCellularProviderDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OLCC:"])
		{ // call status - _OLCC: <call>,<direction>,<status>,<mode>,<multi>,<number>,<?>
			NSArray *st=[line componentsSeparatedByString:@","];
			int call=[[[st objectAtIndex:0] substringFromIndex:6] intValue];	// call number
			int dir=[[st objectAtIndex:1] intValue];	// direction
			switch([[st objectAtIndex:2] intValue]) {
				case 0: NSLog(@"active"); break;
				case 1: NSLog(@"held"); break;
				case 2: NSLog(@"dialing (MO)"); break;
				case 3: NSLog(@"alerting (MO)"); break;
				case 4: NSLog(@"incoming (MT)"); break;
				case 5: NSLog(@"waiting (MT)"); break;
				case 30: NSLog(@"terminated"); break;
			}
			return;
		}
}

- (CTCarrier *) subscriberCellularProvider;
{
	return subscriberCellularProvider;	// FIXME: das sollte einfach ein Index in den carrier-Set sein!
}

- (void) _setSubscriberCellularProvider:(CTCarrier *) provider;
{
	if(subscriberCellularProvider != provider)
		{
		[subscriberCellularProvider release];
		subscriberCellularProvider=[provider retain];
		[delegate subscriberCellularProviderDidUpdate:provider];
		}
}

- (id <CTNetworkInfoDelegate>) delegate;
{
	return delegate;
}

- (void) setDelegate:(id <CTNetworkInfoDelegate>) del;
{
	delegate=del;
}

- (CTCarrier *) currentNetwork;
{ // changes while roaming
	return currentNetwork;
}

- (NSSet *) networks;
{ // list of networks being available
	if(currentNetwork)
		return [NSSet setWithObject:currentNetwork];	// we can at least report the current network...
	return [NSSet set];
	// geht auch ohne PIN
	// ask AT+COPS=? - blockiert sehr lange (30-60 Sekunden)
	// +COPS: (1,"E-Plus","E-Plus","26203",0),(2,"o2 - de","o2 - de","26207",2),(1,"E-Plus","E-Plus","26203",2),(1,"T-Mobile D","TMO D","26201",0),(1,"o2 - de","o2 - de","26207",0),(1,"Vodafone.de","voda DE","26202",0),(1,"Vodafone.de","voda DE","26202",2),(1,"T-Mobile D","TMO D","26201",2),,(0,1,2,3,4),(0,1,2)	
	// +COPS: (2,"o2 - de","o2 - de","26207",2),(1,"E-Plus","E-Plus","26203",0),(1,"E-Plus","E-Plus","26203",2),(1,"o2 - de","o2 - de","26207",0),(1,"Vodafone.de","voda DE","26202",0),(1,"T-Mobile D","TMO D","26201",0),(1,"T-Mobile D","TMO D","26201",2),(1,"Vodafone.de","voda DE","26202",2),,(0,1,2,3,4),(0,1,2)
	// 	at+cops=0  -- automatisch
	//  at+cops=1,2,26207  -- feste Wahl, Format <numerisch>
	// ohne SIM: +COPS: 0,0,"Limited Service",2
	// "1&1" scheint auch "26202" zu melden -> 26202 = physikalisches Netz (D1, D2, E1, E2) 
	return nil;
}

- (float) paTemperature;
{ // temperature of PA in centigrade
	return paTemp;
}

@end
