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
    var slider: UISlider?
    
    var imageWidth = 0
    var imageHeight = 0
    var touching = false
    var touchX = 0
    var touchY = 0
    var touchRadius = 100
    var maxRadius = 0
    
    //var pixels565: [UInt16]?
    var pixelsARGB: [UInt32]?
    var time: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get screen size
        let screenBounds = UIScreen.main.bounds
        
        // define bitmap info for plasma
        imageWidth = Int(round(screenBounds.width * IMAGE_SCALE))
        imageHeight = Int(round(screenBounds.height * IMAGE_SCALE))
        // pixels565 = [UInt16](count: Int(imageWidth * imageHeight), repeatedValue: 0);
        pixelsARGB = [UInt32](repeating: 0, count: Int(imageWidth * imageHeight));
        maxRadius = imageWidth / 3
        
        // create UIImageView
        uiImageView = UIImageView(frame: screenBounds)
        //uiImageView?.contentMode = .ScaleAspectFill
        view.addSubview(uiImageView!)
        
        // speed slider
        let sliderWidth = screenBounds.width * 0.9
        let sliderX = (screenBounds.width - sliderWidth) * 0.5
        slider = UISlider(frame: CGRect(x: sliderX, y: screenBounds.height - 50, width: sliderWidth, height: 20))
        slider!.minimumValue = -2
        slider!.maximumValue = 2
        slider!.isContinuous = true
        //sliderDemo.tintColor = UIColor.redColor()
        slider!.value = -1
        //slider!.addTarget(self, action: "sliderValueDidChange:", forControlEvents: .ValueChanged)
        view.addSubview(slider!)
        
        // schedule repeated render
        Timer.scheduledTimer(timeInterval: INTERVAL, target: self,
                                               selector: #selector(self.render),
                                               userInfo: nil, repeats: true)
    }
    
    func sliderValueDidChange(_ sender: UISlider!)
    {
        print("value: \(sender.value)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func render()
    {
        if (touching) {
            touchRadius = min(touchRadius + 1, maxRadius)
        } else if (touchRadius > 0) {
            touchRadius -= 1
        }
        renderPlasma(&pixelsARGB!, CInt(imageWidth), CInt(imageHeight), time, CInt(touchX), CInt(touchY), CInt(touchRadius))
        time += Int(INTERVAL * 1000 * Double(-slider!.value))
        
        
        // prepping for CGImage
        let bitsPerComponent = 8
        let bitsPerPixel = bitsPerComponent * BYTES_PER_PIXEL
        let bytesPerRow = imageWidth * BYTES_PER_PIXEL
        //let cfdata = Data(bytes: UnsafePointer<UInt8>(pixelsARGB!), count: pixelsARGB!.count * BYTES_PER_PIXEL) as CFData
        let cfdata = Data(bytes: pixelsARGB!, count: pixelsARGB!.count * BYTES_PER_PIXEL) as CFData
        let providerRef = CGDataProvider(data: cfdata)
        
        let cgim = CGImage(
            width: imageWidth,
            height: imageHeight,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
            provider: providerRef!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
        
        // TODO: is there a better way?
        uiImageView?.image = UIImage(cgImage: cgim!)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first {
            let pos = touch.location(in: uiImageView)
            //print(pos);
            touching = true
            touchX = Int(pos.x)
            touchY = Int(pos.y)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        touching = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        if let touch = touches.first {
            let pos = touch.location(in: uiImageView)
            //print(pos);
            touchX = Int(pos.x)
            touchY = Int(pos.y)
        }
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


