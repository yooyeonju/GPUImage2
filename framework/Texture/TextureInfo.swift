//
//  TextureInfo.swift
//  GPUImage
//
//  Created by USER on 2021/08/23.
//  Copyright © 2021 Sunset Lake Software LLC. All rights reserved.
//

import UIKit
import OpenGLES

@objcMembers
class TextureInfo: NSObject {
    var name: GLuint = 0
    var target: GLenum = 0
    var width: GLuint = 0
    var height: GLuint = 0
    var alreadyCleared: Bool = false
    
    func isAlreadyCleared() -> Bool {
        return alreadyCleared
    }
    
    var textureSize: CGSize {
        return CGSize(width: Int(width), height: Int(height))
    }
}
