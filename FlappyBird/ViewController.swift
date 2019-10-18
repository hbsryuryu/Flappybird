//
//  ViewController.swift
//  FlappyBird
//
//  Created by 濱田龍輝 on 2019/09/09.
//  Copyright © 2019 Ryuuki.hamada. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = self.view as! SKView// SKViewに型を変換する
        skView.showsFPS = true// FPSを表示する
        skView.showsNodeCount = true // ノードの数を表示する
        
        // ビューと同じサイズでシーンを作成する
        let scene = GameScene(size:skView.frame.size) // ←GameSceneクラスに変更する
        skView.presentScene(scene)// ビューにシーンを表示する
    }
    
    // ステータスバーを消す
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
}
