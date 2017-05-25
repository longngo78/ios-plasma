//
//  plasma.c
//  Plasma
//
//  Created by Long Ngo on 5/24/17.
//  Copyright © 2017 Longo Games. All rights reserved.
//

/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "plasma.h"
#include "fixed.h"
#include "quickmath.h"
#include "ioshelper.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/* Return current time in milliseconds */
static double now_ms(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec*1000. + tv.tv_usec/1000.;
}

static uint16_t  palette[PALETTE_SIZE];

static uint16_t  make565(int red, int green, int blue)
{
    return (uint16_t)( ((red   << 8) & 0xf800) |
                      ((green << 3) & 0x07e0) |
                      ((blue  >> 3) & 0x001f) );
}

static void init_palette(void)
{
    int  nn, mm = 0;
    /* fun with colors */
    for (nn = 0; nn < PALETTE_SIZE/4; nn++) {
        int  jj = (nn-mm)*4*255/PALETTE_SIZE;
        palette[nn] = make565(255, jj, 255-jj);
    }
    
    for ( mm = nn; nn < PALETTE_SIZE/2; nn++ ) {
        int  jj = (nn-mm)*4*255/PALETTE_SIZE;
        palette[nn] = make565(255-jj, 255, jj);
    }
    
    for ( mm = nn; nn < PALETTE_SIZE*3/4; nn++ ) {
        int  jj = (nn-mm)*4*255/PALETTE_SIZE;
        palette[nn] = make565(0, 255-jj, 255);
    }
    
    for ( mm = nn; nn < PALETTE_SIZE; nn++ ) {
        int  jj = (nn-mm)*4*255/PALETTE_SIZE;
        palette[nn] = make565(jj, 0, 255);
    }
}

/*
static __inline__ uint16_t  palette_from_fixed( Fixed  x )
{
    if (x < 0) x = -x;
    if (x >= FIXED_ONE) x = FIXED_ONE-1;
    int  idx = FIXED_FRAC(x) >> (FIXED_BITS - PALETTE_BITS);
    return palette[idx & (PALETTE_SIZE-1)];
}
*/

static __inline__ void  set_pixel( PIXEL* pixel, Fixed  x )
{
    if (x < 0) x = -x;
    if (x >= FIXED_ONE) x = FIXED_ONE-1;
    int  idx = FIXED_FRAC(x) >> (FIXED_BITS - PALETTE_BITS);
    
    // apply
    const uint16_t color = palette[idx & (PALETTE_SIZE-1)];
    if (sizeof(*pixel) == 2) {
        // RGB565
        *pixel = color;
    } else {
        
        // covert RGB565 to ARGB with color enhancement
        uint8_t r = (color & 0xf800) >> 11;
        r = (r << 3) | (r >> 2); // OR 3 significant bits
        uint8_t g = (color & 0x07e0) >> 5;
        g = (g << 2) | (g >> 4); // OR 2 significant bits
        uint8_t b = (color & 0x001f);
        b = (b << 3) | (b >> 2); // OR 3 significant bits
         
        //*pixel = 255 << 24 | r << 16 | g << 8 | b;
        // note: this is backward
        *pixel = b << 24 | g << 16 | r << 8 | 255;
        // inline
        //*pixel = ((color & 0x001f) << 3) << 24 | ((color & 0x07e0) >> 5) << 2 << 16 | ((color & 0xf800) >> 11) << 3 << 8 | 255;
    }
}

/* Angles expressed as fixed point radians */

void init_tables(void)
{
    init_palette();
    init_angles();
}

void fill_plasma(void* pixels, const int width, const int height, const unsigned long t)
{
    const int stride = sizeof(PIXEL) * width;
    Fixed yt1 = FIXED_FROM_FLOAT(t/1230.);
    Fixed yt2 = yt1;
    Fixed xt10 = FIXED_FROM_FLOAT(t/3000.);
    Fixed xt20 = xt10;
    
#define  YT1_INCR   FIXED_FROM_FLOAT(1/100.)
#define  YT2_INCR   FIXED_FROM_FLOAT(1/163.)
    
    int  yy;
    for (yy = 0; yy < height; yy++) {
        PIXEL*  line = (PIXEL*)pixels;
        Fixed      base = fixed_sin(yt1) + fixed_sin(yt2);
        Fixed      xt1 = xt10;
        Fixed      xt2 = xt20;
        
        yt1 += YT1_INCR;
        yt2 += YT2_INCR;
        
#define  XT1_INCR  FIXED_FROM_FLOAT(1/173.)
#define  XT2_INCR  FIXED_FROM_FLOAT(1/242.)
        
#if OPTIMIZE_WRITES
        /* optimize memory writes by generating one aligned 32-bit store
         * for every pair of pixels.
         */
        PIXEL*  line_end = line + width;
        
        if (line < line_end) {
            if (((uint32_t)(uintptr_t)line & 3) != 0) {
                Fixed ii = base + fixed_sin(xt1) + fixed_sin(xt2);
                
                xt1 += XT1_INCR;
                xt2 += XT2_INCR;
                
                //line[0] = palette_from_fixed(ii >> 2);
                set_pixel(line, ii >> 2);
                line++;
            }
            
            while (line + 2 <= line_end) {
                Fixed i1 = base + fixed_sin(xt1) + fixed_sin(xt2);
                xt1 += XT1_INCR;
                xt2 += XT2_INCR;
                
                Fixed i2 = base + fixed_sin(xt1) + fixed_sin(xt2);
                xt1 += XT1_INCR;
                xt2 += XT2_INCR;
                
                // Longo replaced this...
                //uint32_t  pixel = ((uint32_t)palette_from_fixed(i1 >> 2) << 16) | (uint32_t)palette_from_fixed(i2 >> 2);
                //((uint32_t*)line)[0] = pixel;
                // ...by this
                set_pixel(line, i1 >> 2);
                set_pixel(line + 1, i2 >> 2);
                
                line += 2;
            }
            
            if (line < line_end) {
                Fixed ii = base + fixed_sin(xt1) + fixed_sin(xt2);
                set_pixel(line, ii >> 2);
                line++;
            }
        }
#else /* !OPTIMIZE_WRITES */
        int xx;
        for (xx = 0; xx < info->width; xx++) {
            
            Fixed ii = base + fixed_sin(xt1) + fixed_sin(xt2);
            
            xt1 += XT1_INCR;
            xt2 += XT2_INCR;
            
            set_pixel(line + xx, ii >> 2);
        }
#endif /* !OPTIMIZE_WRITES */
        
        // go to next line
        pixels = (char*)pixels + stride;
    }
}

void stats_init( Stats*  s )
{
    s->lastTime = now_ms();
    s->firstTime = 0.;
    s->firstFrame = 0;
    s->numFrames  = 0;
}

void stats_startFrame( Stats*  s )
{
    s->frameTime = now_ms();
}

void stats_endFrame( Stats*  s )
{
    double now = now_ms();
    double renderTime = now - s->frameTime;
    double frameTime  = now - s->lastTime;
    int nn;
    
    if (now - s->firstTime >= MAX_PERIOD_MS) {
        if (s->numFrames > 0) {
            double minRender, maxRender, avgRender;
            double minFrame, maxFrame, avgFrame;
            int count;
            
            nn = s->firstFrame;
            minRender = maxRender = avgRender = s->frames[nn].renderTime;
            minFrame  = maxFrame  = avgFrame  = s->frames[nn].frameTime;
            for (count = s->numFrames; count > 0; count-- ) {
                nn += 1;
                if (nn >= MAX_FRAME_STATS)
                    nn -= MAX_FRAME_STATS;
                double render = s->frames[nn].renderTime;
                if (render < minRender) minRender = render;
                if (render > maxRender) maxRender = render;
                double frame = s->frames[nn].frameTime;
                if (frame < minFrame) minFrame = frame;
                if (frame > maxFrame) maxFrame = frame;
                avgRender += render;
                avgFrame  += frame;
            }
            avgRender /= s->numFrames;
            avgFrame  /= s->numFrames;
            
            /*LOGI("frame/s (avg,min,max) = (%.1f,%.1f,%.1f) "
                 "render time ms (avg,min,max) = (%.1f,%.1f,%.1f)\n",
                 1000./avgFrame, 1000./maxFrame, 1000./minFrame,
                 avgRender, minRender, maxRender);*/
        }
        s->numFrames  = 0;
        s->firstFrame = 0;
        s->firstTime  = now;
    }
    
    nn = s->firstFrame + s->numFrames;
    if (nn >= MAX_FRAME_STATS)
        nn -= MAX_FRAME_STATS;
    
    s->frames[nn].renderTime = renderTime;
    s->frames[nn].frameTime  = frameTime;
    
    if (s->numFrames < MAX_FRAME_STATS) {
        s->numFrames += 1;
    } else {
        s->firstFrame += 1;
        if (s->firstFrame >= MAX_FRAME_STATS)
            s->firstFrame -= MAX_FRAME_STATS;
    }
    
    s->lastTime = now;
}

void renderPlasma(void* pixels, const int width, const int height, const unsigned long time_ms)
{
    //BitmapInfo         info;
    //void*              pixels;
    //int                ret;
    static Stats       stats;
    static int         init;
    
    if (!init) {
        init_tables();
        stats_init(&stats);
        init = 1;
    }
    
    //    if ((ret = AndroidBitmap_getInfo(env, bitmap, &info)) < 0) {
    //        LOGE("AndroidBitmap_getInfo() failed ! error=%d", ret);
    //        return;
    //    }
    //
    //    if (info.format != ANDROID_BITMAP_FORMAT_RGB_565) {
    //        LOGE("Bitmap format is not RGB_565 !");
    //        return;
    //    }
    //
    //    if ((ret = AndroidBitmap_lockPixels(env, bitmap, &pixels)) < 0) {
    //        LOGE("AndroidBitmap_lockPixels() failed ! error=%d", ret);
    //    }
    
    stats_startFrame(&stats);
    
    // Now fill the values with a nice little plasma
    fill_plasma(pixels, width, height, time_ms);
    
    //AndroidBitmap_unlockPixels(env, bitmap);
    
    stats_endFrame(&stats);
}



