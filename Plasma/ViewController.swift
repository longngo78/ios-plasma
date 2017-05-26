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
    
    let screenBounds = UIScreen.main.bounds
    var uiImageView: UIImageView?
    
    var palette = 0
    var speed: Float = 1.0
    var imageScale: Float = 1.0
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
        
        // define bitmap info for plasma
        imageWidth = Int(round(screenBounds.width * CGFloat(imageScale)))
        imageHeight = Int(round(screenBounds.height * CGFloat(imageScale)))
        // pixels565 = [UInt16](count: Int(imageWidth * imageHeight), repeatedValue: 0);
        pixelsARGB = [UInt32](repeating: 0, count: Int(imageWidth * imageHeight));
        maxRadius = Int(screenBounds.width / 3)
        
        // create UIImageView
        uiImageView = UIImageView(frame: screenBounds)
        //uiImageView?.contentMode = .ScaleAspectFill
        view.addSubview(uiImageView!)
        
        // palette button
        let button = UIButton(type: UIButtonType.contactAdd);
        button.frame = CGRect(x: 10, y: 20, width: 50, height: 50)
        //button.backgroundColor = UIColor.gray
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        view.addSubview(button)
        
        // zoom stepper
        let stepper = UIStepper(frame: CGRect(x: screenBounds.width - 120, y: 30, width: 100, height: 50))
        stepper.wraps = false
        stepper.autorepeat = false
        stepper.minimumValue = 0
        stepper.maximumValue = 0.5
        stepper.stepValue = 0.1
        stepper.value = 1 - Double(imageScale)
        stepper.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)
        view.addSubview(stepper)
        
        // speed slider
        let sliderWidth = screenBounds.width * 0.9
        let sliderX = (screenBounds.width - sliderWidth) * 0.5
        let slider = UISlider(frame: CGRect(x: sliderX, y: screenBounds.height - 50, width: sliderWidth, height: 20))
        slider.minimumValue = -2
        slider.maximumValue = 2
        slider.isContinuous = true
        slider.value = -speed
        slider.addTarget(self, action: #selector(sliderValueDidChange), for: .valueChanged)
        view.addSubview(slider)
        
        // schedule repeated render
        Timer.scheduledTimer(timeInterval: INTERVAL, target: self,
                                               selector: #selector(self.render),
                                               userInfo: nil, repeats: true)
    }
    
    @IBAction func buttonPressed(_ sender: UIButton!)
    {
        palette += 1
        set_palette(CInt(palette))
    }
    
    @IBAction func stepperValueChanged(_ sender: UIStepper!)
    {
        imageScale = Float(1 - sender.value)
        imageWidth = Int(round(screenBounds.width * CGFloat(imageScale)))
        imageHeight = Int(round(screenBounds.height * CGFloat(imageScale)))
    }
    
    @IBAction func sliderValueDidChange(_ sender: UISlider!)
    {
        speed = Float(-sender!.value)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func render()
    {
        if (touching) {
            if (touchRadius < maxRadius) {
                touchRadius += 1
            }
        } else if (touchRadius > 0) {
            touchRadius -= 1
        }
        // time flies
        time += Int(Float(INTERVAL * 1000) * speed)
        
        // render here
        render_plasma(&pixelsARGB!,
                      CInt(imageWidth), CInt(imageHeight), time,
                      CInt(Float(touchX) * imageScale), CInt(Float(touchY) * imageScale),
                      CInt(touchRadius))
        
        // prepping for CGImage
        let bitsPerComponent = 8
        let bitsPerPixel = bitsPerComponent * BYTES_PER_PIXEL
        let bytesPerRow = imageWidth * BYTES_PER_PIXEL
        let cfdata = Data(bytes: pixelsARGB!, count: (imageWidth * imageHeight) * BYTES_PER_PIXEL) as CFData
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


