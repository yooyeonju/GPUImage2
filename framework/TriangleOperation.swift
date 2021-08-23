//
//  TriangleOperation.swift
//  GPUImage
//
//  Created by USER on 2021/08/23.
//  Copyright © 2021 Sunset Lake Software LLC. All rights reserved.
//

import UIKit
import Foundation

public class TriangleOperation: BasicOperation {
    
    public enum TrianglePosition {
        case center
        case leftMiddle
        case rightBottom
    }

    var image: UIImage
    var imageSize: CGSize
    var imagePosition: TrianglePosition
    var textureInfo: TextureInfo?
    
    private var normalizedImageVertices:[GLfloat]!
   
    public var transform: Matrix4x4 = Matrix4x4.identity { didSet { uniformSettings["transformMatrix"] = transform } }
    
    let positions: [Position] = [Position( 0, -0.5),
                                 Position( -0.5,  0.5),
                                 Position( 0.5,  0.5)]
    
    private static let leftMiddlePositionMargin: CGFloat = 33
    
    let vertexShader = """
    attribute vec4 position;\n
    attribute vec4 inputTextureCoordinate;\n

    uniform mat4 transformMatrix;\n
    uniform mat4 orthographicMatrix;\n

    varying vec2 textureCoordinate;\n

    void main() {\n
        textureCoordinate = inputTextureCoordinate.xy;\n
        gl_Position = transformMatrix * vec4(position.xyz, 1.0) * orthographicMatrix;\n
    }\n
    """
    
    let fragementShader = """
    varying highp vec2 textureCoordinate;\n

    uniform sampler2D inputImageTexture;\n

    void main()\n
    {\n
        gl_FragColor = texture2D(inputImageTexture, textureCoordinate);\n
    }\n
    """
    
    public init(image: UIImage, imageSize: CGSize, imagePosition: TrianglePosition = .rightBottom) {
        self.image = image
        self.imageSize = imageSize
        self.imagePosition = imagePosition
        
        do {
            let textureInfo = try TextureLoader.simpleTexture(withImage: image)
            self.textureInfo = textureInfo
        } catch (let error) {
            print(error.localizedDescription)
        }
        
        super.init(vertexShader: vertexShader, fragmentShader: fragementShader, numberOfInputs: 1)
    }
    
    override func internalRenderFunction(_ inputFramebuffer: Framebuffer, textureProperties: [InputTextureProperties]) {
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        shader.use()
        
        renderQuadWithShader(
            shader,
            uniformSettings: uniformSettings,
            vertices: normalizedImageVertices,
            inputTextures: triangleTextureProperties()
        )
        
        releaseIncomingFramebuffers()
    }
    
    public override func newFramebufferAvailable(_ framebuffer: Framebuffer, fromSourceIndex: UInt) {
        let inputSize = Size(framebuffer.size)
        let orthoMatrix = orthographicMatrix(0.0, right: inputSize.width, bottom: 0, top: inputSize.height, near: -1.0, far: 1.0)
        normalizedImageVertices = normalizedImageVerticesForAspectRatio(imageSize.size())
        uniformSettings["orthographicMatrix"] = orthoMatrix
        
        let outputSize = CGSize(framebuffer.size)
        var scale: CGFloat
        if outputSize.ratio > 1.0 {
            scale = outputSize.height / 1080
        } else {
            scale = outputSize.width / 1080
        }
        let scaleTransform = CGAffineTransform.init(scaleX: scale, y: scale)

        let scaledImageSize = imageSize * scale
        let margin: CGFloat = Self.leftMiddlePositionMargin * scale

        let x: CGFloat
        let y: CGFloat
        switch imagePosition {
        case .center:
            x = (outputSize.width - scaledImageSize.width) / 2
            y = (outputSize.height - scaledImageSize.height) / 2
        case .leftMiddle:
            x = margin
            y = (outputSize.height - scaledImageSize.height) / 2
        case .rightBottom:
            x = outputSize.width - scaledImageSize.width
            y = outputSize.height - scaledImageSize.height
        }

        let translationTransform = CGAffineTransform(translationX: x, y: y)
        let transform = scaleTransform.concatenating(translationTransform)

        self.transform = Matrix4x4(transform)
        super.newFramebufferAvailable(framebuffer, fromSourceIndex: fromSourceIndex)
    }
    
    private func triangleTextureProperties() -> [InputTextureProperties] {
        guard let _textureInfoName = textureInfo?.name else { return [] }
        let property = InputTextureProperties(textureVBO: sharedImageProcessingContext.framebufferCache.context.textureVBO(for: .noRotation), texture: _textureInfoName)
        return [property]
    }
    
}

extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    init(_ glSize: GLSize) {
        self.init(width: CGFloat(glSize.width), height: CGFloat(glSize.height))
    }
    
    func size() -> Size {
        return Size(width: Float(width), height: Float(height))
    }
    
    var ratio: CGFloat {
        return width / height
    }
}

