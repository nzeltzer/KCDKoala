//
//  KCDRuntime.h
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 8/25/15.
//  Copyright © 2015 LawBox LLC. All rights reserved.
//

#ifndef KCDRuntime_h
#define KCDRuntime_h


#ifdef __IPHONE_9_0
#define KCDGeneric(x) <x>
#else
#define KCDGeneric(x) /**/
#endif

#ifdef __MAC_10_11
#define KCDGeneric(x) <x>
#else
#define KCDGeneric(x) /**/
#endif


#endif /* KCDRuntime_h */
