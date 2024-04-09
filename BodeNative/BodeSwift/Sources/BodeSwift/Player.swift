import SwiftGodot
import Foundation

@Godot
final class Player: CharacterBody3D {
	static let defaultFallAcceleration: Double = 75
	static let fallAcceleration: Double = Double(ProjectSettings.getSetting(
		name: "physics/3d/default_gravity",
		defaultValue: Variant(Player.defaultFallAcceleration)
	))!

	static let jumpImpulse: Double = 20
	static let speed: Double = 14
	static let rotationSpeed: Double = 1.0
	static let fallHeight: Double = -10
	static let fallTimer: Double = 3.5
	static let blocksSceneName: StringName = "block"
	static let blockHeight: Double = 30
	static let movingAnimationSpeed: Double = 3

	var targetVelocity: Vector3 = Vector3.zero
	var targetRotation: Quaternion = Quaternion.identity
	var score: Int = 0
	var offScreenAt: Vector3? = nil
	var nearbyBlocks: Set<Int> = Set()
	var blockIsNearby: Bool { !nearbyBlocks.isEmpty }

	@BindChild(path: "Pivot") var pivot: Node3D
	@BindChild(path: "CameraPivot") var cameraPivot: Marker3D
	@BindChild(path: "Blocks") var blocks: ResourcePreloader
	@BindChild(path: "AnimationPlayer") var animation: AnimationPlayer

	var blockSpawner: Block {
		guard
			let resource = blocks.getResource(name: Player.blocksSceneName),
			let scene = resource as? PackedScene,
			let node = scene.instantiate(),
			let block = node as? Block
		else {
			GD.pushError("Expected `block` scene from `Blocks`")
			fatalError()
		}

		return block
	}

	#signal("score_changed")
	#signal("player_died")

	func kill() {
		emit(signal: Player.playerDied)
	}

	private func handleInput(delta: Double) {
		var direction = Vector3.zero

		if Input.isActionPressed(action: "move_right") {
			direction.x += 1
		}

		if Input.isActionPressed(action: "move_left") {
			direction.x -= 1
		}

		if Input.isActionPressed(action: "move_forward") {
			direction.z -= 1
		}

		switch direction != Vector3.zero {
			case true where isOnFloor():
				animation.speedScale = Player.movingAnimationSpeed
				fallthrough
			case true:
				direction = direction.normalized()
			    direction = cameraPivot.basis * direction

				pivot.basis = Basis.lookingAt(target: direction)
				targetRotation = Basis.lookingAt(target: direction).getRotationQuaternion()
			case false:
				animation.speedScale = 1
		}

		pivot.rotation.x = Float.pi / 6 * velocity.y / Float(Player.jumpImpulse)

		targetVelocity.x = direction.x * Float(Player.speed)
		targetVelocity.z = direction.z * Float(Player.speed)

		if !blockIsNearby && Input.isActionJustPressed(action: "action") {
			let block = blockSpawner
			block.initialize(with: self)
			block.position = position
			block.position.y = Float(Player.blockHeight)
			getTree()?.currentScene?.addChild(node: block)
		} else if blockIsNearby && isOnFloor() {
			targetVelocity.y = Input.isActionJustPressed(action: "action")
				? Float(Player.jumpImpulse)
				: 0
		}

		cameraPivot.rotation = Quaternion.fromEuler(cameraPivot.rotation).slerp(to: targetRotation, weight: Player.rotationSpeed * delta).getEuler()
		velocity = targetVelocity
		moveAndSlide()
	}

	private func handleCollisions() {
		for index in 0..<getSlideCollisionCount() {
			guard
				let collision = getSlideCollision(slideIdx: index),
				let collider = collision.getCollider(),
				let mob = collider as? Mob
			else {
				continue
			}

			if Vector3.up.dot(with: collision.getNormal()) > 0.25 {
				mob.kill(by: self)
				targetVelocity.y = Float(Player.jumpImpulse)
				break
			} else {
				kill()
				break
			}
		}
	}

	override func _physicsProcess(delta: Double) {
		if !isOnFloor() {
			targetVelocity.y = targetVelocity.y - Float(Player.fallAcceleration * delta)
		}
	
		guard offScreenAt == nil else {
			moveAndSlide()
			return
		}

		handleInput(delta: delta)
		handleCollisions()
	}

	override func _process(delta: Double) {
		if let offScreenAt {
			cameraPivot.globalPosition = offScreenAt
			return
		}

		let offScreen = globalPosition.y < Float(Player.fallHeight)

		if offScreen {
			offScreenAt = cameraPivot.globalPosition
			getTree()?.createTimer(timeSec: Player.fallTimer)?.timeout.connect {
				self.kill()
			}
		}
    }
}
