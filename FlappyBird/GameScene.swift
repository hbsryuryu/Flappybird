//
//  GameScene.swift
//  FlappyBird
//
//  Created by 濱田龍輝 on 2019/09/09.
//  Copyright © 2019 Ryuuki.hamada. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene , SKPhysicsContactDelegate{
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var pointUpItemNode:SKNode!
    var bird:SKSpriteNode!
    
    var effectSoundPlayer:AVAudioPlayer?
    var bgmPlayer: AVAudioPlayer?
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let pointUpItemCategory: UInt32 = 1 << 4       // 0...10000
    
    // スコア用
    var score = 0
    var pointUpItem_score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var restartLabelNode:SKLabelNode!
    var hintLabelNode:SKLabelNode!
    var pointUpItemLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    var hint_array = ["error"]
    var hint_array_number = 0
    
    
    
    /*
    zPosition
     
     Cloud -100
     wall -50
     pointUpItem -40
     scoreLabel 100
     bestscoreLabel 100
     restartLabel 100
     hintLabel 100
     pointUpItemLabel 100
     
    */

    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)// 背景色を設定
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()
        pointUpItemNode = SKNode()
        scrollNode.addChild(wallNode)
        scrollNode.addChild(pointUpItemNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupScoreLabel()
        setupPointUpItem()
        load_audio()
        setup_effectSoundPlayer()
        setup_hint_array()
        
    }
    
    
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            bird.physicsBody?.velocity = CGVector.zero// 鳥の速度をゼロにする
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))// 鳥に縦方向の力を与える
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return //ここでdidBegin処理終了 壁接触後の床の処理をさせないため
        }
        
        //ポイントアップ要素同時処理対応
        var flug_contact_score = 0
        if (contact.bodyA.categoryBitMask & pointUpItemCategory) == pointUpItemCategory || (contact.bodyB.categoryBitMask & pointUpItemCategory) == pointUpItemCategory {
            score += 3
            pointUpItem_score += 1
            pointUpItemLabelNode.text = "Item Count:\(pointUpItem_score)"
            upDateScore()
            effectSoundPlayer?.play()
            flug_contact_score = 1
            pointUpItemNode.removeAllChildren()
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            score += 1
            upDateScore()
        } else if (flug_contact_score == 0) {
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
            restartLabelNode.text = "GAME OVER"
            hintLabelNode.text = "\(hint_array[hint_array_number])"
        }
    }
    
    func upDateScore(){
        scoreLabelNode.text = "Score:\(score)"
        var bestScore = userDefaults.integer(forKey: "BEST")
        if score > bestScore {
            bestScore = score
            userDefaults.set(bestScore, forKey: "BEST")
            userDefaults.synchronize()
            bestScoreLabelNode.text = "Best Score:\(bestScore)"
        }
    }
    
    func restart() {
        score = 0
        pointUpItem_score = 0
        scoreLabelNode.text = "Score:\(score)"
        pointUpItemLabelNode.text = "Item Count:\(pointUpItem_score)"
        restartLabelNode.text = ""
        hintLabelNode.text = ""
        hint_array_number = Int.random(in: 0..<hint_array.count)
        //print("count: \(hint_array.count)")
        //print("number: \(hint_array_number)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        pointUpItemNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())   // ←追加
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory    // ←追加
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false   // ←追加
            
            scrollNode.addChild(sprite)// スプライトを追加する
        }
    }
    
    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
        let slit_length = birdSize.height * 3
        
        // 隙間位置の上下の振れ幅を鳥のサイズの3倍とする
        let random_y_range = birdSize.height * 3
        
        // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            let random_y = CGFloat.random(in: 0..<random_y_range)// 0〜random_y_rangeまでのランダム値を生成
            let under_wall_y = under_wall_lowest_y + random_y// Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            under.physicsBody?.isDynamic = false    // 衝突の時に動かないように設定する
            
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            upper.physicsBody?.isDynamic = false    // 衝突の時に動かないように設定する
            
            wall.addChild(upper)
            
            // スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texuresAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.2)    // 物理演算を設定
        bird.physicsBody?.allowsRotation = false    // 衝突した時に回転させない
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | pointUpItemCategory
        
        bird.run(flap)  // アニメーションを設定
        addChild(bird)  // スプライトを追加する
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        pointUpItemLabelNode = SKLabelNode()
        pointUpItemLabelNode.fontColor = UIColor.black
        pointUpItemLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        pointUpItemLabelNode.zPosition = 100
        pointUpItemLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        pointUpItemLabelNode.text = "Item Count:\(pointUpItem_score)"
        self.addChild(pointUpItemLabelNode)
        
        restartLabelNode = SKLabelNode()
        restartLabelNode.fontColor = UIColor.black
        restartLabelNode.fontName = "Thonburi-Bold"
        restartLabelNode.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        restartLabelNode.zPosition = 100
        restartLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        restartLabelNode.text = ""
        self.addChild(restartLabelNode)
        
        hintLabelNode = SKLabelNode()
        hintLabelNode.fontColor = UIColor.black
        hintLabelNode.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 50)
        hintLabelNode.zPosition = 100
        hintLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        hintLabelNode.text = ""
        self.addChild(hintLabelNode)
    }
    
    
    func setupPointUpItem() {
        
        let pointUpItemTexture = SKTexture(imageNamed: "pan")
        pointUpItemTexture.filteringMode = .nearest
        
        // 移動する距離を計算
        let pointUpItemMovingDistance = CGFloat(self.frame.size.width + pointUpItemTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let movePointUpItem = SKAction.moveBy(x: -pointUpItemMovingDistance, y: 0, duration:4)
        
        // 自身を取り除くアクションを作成
        let removePointUpItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let pointUpItemAnimation = SKAction.sequence([movePointUpItem, removePointUpItem])
        
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        let random_y_MaxRange = birdSize.height * 3.5
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        // ポイントアップを生成するアクションを作成
        let createPointUpItemAnimation = SKAction.run({
            // 削除管理用ノード
            let pointUpItem_basenode = SKNode()
            pointUpItem_basenode.position = CGPoint(x: 0, y: 0)
            pointUpItem_basenode.zPosition = 0
            
            //random_y_MinRange~random_y_MaxRangeの間
            let random_y = CGFloat.random(in: -random_y_MaxRange...random_y_MaxRange)
            let random_x = CGFloat.random(in: -random_y_MaxRange...0)
            let pointUpItem_y = center_y + random_y
            
            let pointUpItem = SKSpriteNode(texture: pointUpItemTexture)
            
            pointUpItem.position = CGPoint(x: random_x + self.frame.size.width + pointUpItemTexture.size().width / 2, y: pointUpItem_y)
            pointUpItem.zPosition = -40
            pointUpItem.physicsBody = SKPhysicsBody(rectangleOf: pointUpItemTexture.size())
            pointUpItem.physicsBody?.categoryBitMask = self.pointUpItemCategory
            pointUpItem.physicsBody?.isDynamic = false
            
            pointUpItem_basenode.addChild(pointUpItem)
            pointUpItem_basenode.run(pointUpItemAnimation)
            self.pointUpItemNode.addChild(pointUpItem_basenode)
        })
        
        let waitAnimation = SKAction.wait(forDuration: 5.2)
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createPointUpItemAnimation, waitAnimation]))
        
        pointUpItemNode.run(repeatForeverAnimation)
        
    }
    
    func load_audio(){
        let path = Bundle.main.path(forResource: "background" , ofType: "mp3")!
        let url = URL(fileURLWithPath: path)
        
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = 0.9
            bgmPlayer?.play()
        } catch {
            print("bgmPlayer ERROR")
        }
    }
    
    func setup_effectSoundPlayer(){
        let path = Bundle.main.path(forResource: "chun" , ofType: "mp3")!
        let url = URL(fileURLWithPath: path)
        
        do {
            effectSoundPlayer = try AVAudioPlayer(contentsOf: url)
            effectSoundPlayer?.numberOfLoops = 0
            effectSoundPlayer?.volume = 1.0
            effectSoundPlayer?.prepareToPlay()
        } catch {
            print("effectSoundPlayer ERROR")
        }
    }
    
    func setup_hint_array(){
        //10文字まで
        hint_array[0] = "タップでリスタート！"
        hint_array.append("無理は禁物！")
        hint_array.append("リズムを大事に！")
        hint_array.append("パンは３ポイント！")
        hint_array.append("頑張れ！")
    }
    
}
