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

/* Set to 1 to enable debug log traces. */
//#define DEBUG 0

/* Set to 1 to optimize memory stores when generating plasma. */
#define OPTIMIZE_WRITES  1

/* Color palette used for rendering the plasma */
#define PALETTE_BITS   8
#define PALETTE_SIZE   (1 << PALETTE_BITS)

#if PALETTE_BITS > FIXED_BITS
#  error PALETTE_BITS must be smaller than FIXED_BITS
#endif

/* simple stats management */
typedef struct {
    double renderTime;
    double frameTime;
} FrameStats;

#define STATS_ENABLED      0
#define MAX_FRAME_STATS    200
#define MAX_PERIOD_MS      1500

// pixel formats
#define RGB565 uint16_t
#define ARGB uint32_t
#define PIXEL ARGB
#define PIXEL2 (sizeof(PIXEL) == 2) ? uint32_t : uint64_t

// make colors
#define CONCAT(a, b) a ## b
#define VARIANT 4
#define MAKE_ARGB_0(r, g, b) (ARGB)( b << 24 | g << 16 | r << 8 | 255 )
#define MAKE_ARGB_1(r, g, b) (ARGB)( b << 24 | g << 8 | r << 16 | 255 )
#define MAKE_ARGB_2(r, g, b) (ARGB)( b << 16 | g << 24 | r << 8 | 255 )
#define MAKE_ARGB_3(r, g, b) (ARGB)( b << 16 | g << 8 | r << 24 | 255 )
#define MAKE_ARGB_4(r, g, b) (ARGB)( b << 8 | g << 24 | r << 16 | 255 )
#define MAKE_ARGB_5(r, g, b) (ARGB)( b << 8 | g << 16 | r << 24 | 255 )
#define MAKE_ARGB_V(r, g, b, v) CONCAT(MAKE_ARGB_, v)(r, g, b)

#define MAKE_565(r, g, b) (RGB565)( ((r << 8) & 0xf800) | ((g << 3) & 0x07e0) | ((b  >> 3) & 0x001f) )
#define MAKE_COLOR(r, g, b) (sizeof(PIXEL) == 2) ? MAKE_565((r), (g), (b)) : MAKE_ARGB_V((r), (g), (b), VARIANT)

// animation
#define XT1_INCR   FIXED_FROM_FLOAT(1/240.)
#define XT2_INCR   XT1_INCR
#define YT1_INCR   FIXED_FROM_FLOAT(1/210.)
#define YT2_INCR   FIXED_FROM_FLOAT(1/163.)

typedef struct {
    double firstTime;
    double lastTime;
    double frameTime;
    
    int firstFrame;
    int numFrames;
    FrameStats frames[MAX_FRAME_STATS];
} Stats;

// apis
void renderPlasma(void *pixels, const int width, const int height, const unsigned long time_ms);

#endif /* plasma_h */
