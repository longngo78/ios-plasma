//
//  ioshelper.h
//  Plasma
//
//  Created by Long Ngo on 5/24/17.
//  Copyright © 2017 Longo Games. All rights reserved.
//

#ifndef ioshelper_h
#define ioshelper_h

#include "plasma.h"
#include <sys/time.h>

//#define  LOG_TAG    "libplasma"
#define LOGI(...) { NSLogv([NSString stringWithUTF8String:format], __VA_ARGS__)
#define LOGE(...) { NSLogv([NSString stringWithUTF8String:format], __VA_ARGS__)

#endif /* ioshelper_h */
