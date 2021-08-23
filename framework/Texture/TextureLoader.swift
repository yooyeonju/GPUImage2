//
//  TextureLoader.swift
//  GPUImage
//
//  Created by USER on 2021/08/23.
//  Copyright © 2021 Sunset Lake Software LLC. All rights reserved.
//

import Foundation
import GLKit

enum TextureError: Error {
    case loadTextureError
}

final class TextureLoadingResults {
    var name: GLuint = 0
    var target: GLenum = 0
    var width: GLuint = 0
    var height: GLuint = 0
}

final class SimpleTextureInfo: TextureInfo {
    override public var alreadyCleared: Bool {
        didSet {
            if self.alreadyCleared {
                name = 0
                width = 0
                height = 0
            }
        }
    }

    deinit {
        if !alreadyCleared && name != 0 {
            runOperationSynchronously {
                if !self.alreadyCleared && self.name != 0 {
                    var texName = self.name
                    glDeleteTextures(1, &texName)
                }
            }
        }
    }
}

final class TextureLoader {
    
    static func loadSimpleTexture(withImage imageRef: CGImage) -> TextureLoadingResults {
        let results = TextureLoadingResults()
        results.name = 0
        results.height = 0
        results.width = 0
        results.target = 0
        
        let textureSize = CGSize(width: imageRef.width, height: imageRef.height)
        guard let imageData = imageData(imageRef, textureSize: textureSize) else { return results }
        
        var textureId: GLuint = 0
        glGenTextures(1, &textureId)
        glBindTexture(GLenum(GL_TEXTURE_2D), textureId)

        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)

        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(textureSize.width), GLsizei(textureSize.height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), imageData)

        results.name = textureId
        results.width = GLuint(textureSize.width)
        results.height = GLuint(textureSize.height)
        results.target = GLenum(GL_TEXTURE_2D)
        
        free(imageData)
        return results
    }
    
    static func imageData(_ imageRef: CGImage, textureSize: CGSize) -> UnsafeMutablePointer<GLubyte>? {
        guard var colorSpace = imageRef.colorSpace else { return nil }
        let imageColorSpaceModel = colorSpace.model
        let unsupportedColorSpace = imageColorSpaceModel == .unknown ||
        imageColorSpaceModel == .monochrome ||
        imageColorSpaceModel == .cmyk ||
        imageColorSpaceModel == .indexed
        
        if unsupportedColorSpace {
            colorSpace = CGColorSpaceCreateDeviceRGB()
        }
        
        let imageData = calloc(Int(textureSize.width * textureSize.height) * 4, MemoryLayout<GLubyte>.stride)
        let context = CGContext(data: imageData,
                                width: Int(textureSize.width),
                                height: Int(textureSize.height),
                                bitsPerComponent: 8,
                                bytesPerRow: Int(textureSize.width) * 4,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)

        context?.draw(imageRef, in: CGRect(x: 0, y: 0, width: textureSize.width, height: textureSize.height))

        return UnsafeMutablePointer<GLubyte>(OpaquePointer(imageData))
    }
    
    static func simpleTexture(withCGImage cgImage: CGImage) throws -> TextureInfo {
        let loadedResult: TextureLoadingResults = loadSimpleTexture(withImage: cgImage)
        let error = glGetError()
        if error != GL_NO_ERROR {
            if 0 != glIsTexture(loadedResult.name) {
                glDeleteTextures(1, &loadedResult.name)
                loadedResult.name = GLuint(GL_NONE)
            }
        }
        
        guard loadedResult.name != GLuint(GL_NONE) else {
            throw TextureError.loadTextureError
        }
        let textureInfo = SimpleTextureInfo()
        textureInfo.name = loadedResult.name
        textureInfo.target = loadedResult.target
        textureInfo.width = loadedResult.width
        textureInfo.height = loadedResult.height
        return textureInfo
    }
    
    static func simpleTexture(withImage image: UIImage) throws -> TextureInfo {
        guard let cgImage = image.cgImage else {
            throw TextureError.loadTextureError
        }
        return try simpleTexture(withCGImage: cgImage)
    }
    
}
