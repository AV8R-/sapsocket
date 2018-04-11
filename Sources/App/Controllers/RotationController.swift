//
//  RotationController.swift
//  App
//
//  Created by Богдан Маншилин on 06/04/2018.
//

import Foundation
import Vapor

final class RotationController {
    
    var activeConnections: [Int: WebSocket] = [:]
    let throttler = Throttler(seconds: 1)
    let client: ClientFactoryProtocol
    
    init(client: ClientFactoryProtocol) {
        self.client = client
    }
    
    func rotation(request: Request, ws: WebSocket) throws {
        let id = activeConnections.count
        activeConnections[id] = ws
        
        ws.onText = { [weak self] ws, text in
            print("Sent rotation: \(text)")
            self?.activeConnections.forEach({ (ws) in
                try? ws.value.send(text)
            })
        }
        
        ws.onClose = { [weak self, id = id] _, _, _, _ in
            self?.activeConnections[id] = nil
        }
    }
    
    func sendRotation(request: Request) throws -> ResponseRepresentable {
        guard let json = request.json else {
            throw Abort(.badRequest, reason: "wrong content type. expected application/json")
        }
        
        let rotation: Float = try json.get("rotation")
        
        guard 0...8000 ~= rotation else {
            throw Abort(.badRequest, reason: "rotation parameter must be in range 0...8000")
        }
        
        activeConnections.forEach({ (ws) in
            try? ws.value.send("\(rotation)")
        })
        
        throttler.throttle { [client = self.client] in
            do {
                dump(try client.post("https://hanacisa731b2d26.hana.ondemand.com/Engine3D/eventpost.xsjs",
                                     query: [:], [.contentType: "application/json"], JSON(node: ["Rotation": "\(rotation)"])))
            } catch {
                print("error sending to SAP server")
            }
        }
        
        return Response(status: .ok)
    }
}


