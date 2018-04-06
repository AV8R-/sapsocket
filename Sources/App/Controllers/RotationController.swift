//
//  RotationController.swift
//  App
//
//  Created by Богдан Маншилин on 06/04/2018.
//

import Foundation

final class RotationController {
    
    var activeConnections: [Int: WebSocket] = [:]
    
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
}


