//
//  plasma.h
//  Plasma
//
//  Created by Long Ngo on 5/24/17.
//  Copyright © 2017 Longo Games. All rights reserved.
//

#ifndef plasma_h
#define plasma_h

#include "fixed.h"
#include "bitmap.h"

/* Set to 1 to enable debug log traces. */
#define DEBUG 0

/* Set to 1 to optimize memory stores when generating plasma. */
#define OPTIMIZE_WRITES  1

/* Color palette used for rendering the plasma */
#define  PALETTE_BITS   8
#define  PALETTE_SIZE   (1 << PALETTE_BITS)

#if PALETTE_BITS > FIXED_BITS
#  error PALETTE_BITS must be smaller than FIXED_BITS
#endif

/* simple stats management */
typedef struct {
    double  renderTime;
    double  frameTime;
} FrameStats;

#define  MAX_FRAME_STATS  200
#define  MAX_PERIOD_MS    1500

typedef struct {
    double  firstTime;
    double  lastTime;
    double  frameTime;
    
    int         firstFrame;
    int         numFrames;
    FrameStats  frames[ MAX_FRAME_STATS ];
} Stats;

// apis
void renderPlasma(BitmapInfo * info, void* pixels, long time_ms);

#endif /* plasma_h */
