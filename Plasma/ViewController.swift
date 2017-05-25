//
//  ViewController.swift
//  Plasma
//
//  Created by Long Ngo on 5/24/17.
//  Copyright © 2017 Longo Games. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    let INTERVAL: Double = 1.0 / 45
    let BYTES_PER_PIXEL = 4
    let IMAGE_SCALE: CGFloat  = 1
    
    var uiImageView: UIImageView?
    
    var imageWidth = 0
    var imageHeight = 0
    //var pixels565: [UInt16]?
    var pixelsARGB: [UInt32]?
    var frame: UInt = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get screen size
        let screenBounds = UIScreen.mainScreen().bounds
        
        // define bitmap info for plasma
        imageWidth = Int(round(screenBounds.width * IMAGE_SCALE))
        imageHeight = Int(round(screenBounds.height * IMAGE_SCALE))
        // pixels565 = [UInt16](count: Int(imageWidth * imageHeight), repeatedValue: 0);
        pixelsARGB = [UInt32](count: Int(imageWidth * imageHeight), repeatedValue: 0);
        
        // create UIImageView
        uiImageView = UIImageView(frame: screenBounds)
        //uiImageView?.contentMode = .ScaleAspectFill
        view.addSubview(uiImageView!)
        
        // schedule repeated render
        NSTimer.scheduledTimerWithTimeInterval(INTERVAL, target: self,
                                               selector: #selector(ViewController.render),
                                               userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func render()
    {
        renderPlasma(&pixelsARGB!, CInt(imageWidth), CInt(imageHeight), frame)
        frame += UInt(INTERVAL * 1000)
        
        // prepping for CGImage
        let bitsPerComponent = 8
        let bitsPerPixel = bitsPerComponent * BYTES_PER_PIXEL
        let bytesPerRow = imageWidth * BYTES_PER_PIXEL
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: pixelsARGB!, length: pixelsARGB!.count * BYTES_PER_PIXEL)
        )
        
        let cgim = CGImageCreate(
            imageWidth,
            imageHeight,
            bitsPerComponent,
            bitsPerPixel,
            bytesPerRow,
            CGColorSpaceCreateDeviceRGB(),
            CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue),
            providerRef,
            nil,
            false,
            .RenderingIntentDefault
        )
        
        // TODO: is there a better way?
        uiImageView?.image = UIImage(CGImage: cgim!)
    }
    
    /*
    // Only needed when using RGB565 format
    private func convert2RBG() -> CGImage? {
        var index = 0
        var r, g, b: UInt8
        // convert the pixels to ARGB
        for p in 0..<pixels565!.count {
            let pixel = pixels565![p]
            r = UInt8((pixel & 0xf800) >> 11)
            r = (r << 3) | (r >> 2) // OR 3 significant bits
            g = UInt8((pixel & 0x07e0) >> 5)
            g = (g << 2) | (g >> 4) // OR 2 significant bits
            b = UInt8((pixel & 0x001f))
            b = (b << 3) | (b >> 2) // OR 3 significant bits
            
            // this is terribly slow
            //pixelsARGB![index...index + 3] = [255, r, g, b]
            pixelsARGB![index + 0] = r;
            pixelsARGB![index + 1] = g;
            pixelsARGB![index + 2] = b;
            
            index += BYTES_PER_PIXEL
        }
        
        let bitsPerComponent = 8
        let bitsPerPixel = bitsPerComponent * BYTES_PER_PIXEL
        
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: pixelsARGB!, length: pixelsARGB!.count)
        )
        
        return CGImageCreate(
            imageWidth,
            imageHeight,
            bitsPerComponent,
            bitsPerPixel,
            imageWidth * BYTES_PER_PIXEL,
            CGColorSpaceCreateDeviceRGB(),
            CGBitmapInfo(rawValue: CGImageAlphaInfo.None.rawValue),
            providerRef,
            nil,
            false,
            .RenderingIntentDefault
        )
    }*/
}


