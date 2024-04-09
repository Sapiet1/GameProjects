import SwiftGodot

@Godot
final class Mob: CharacterBody3D {
	static let fallAcceleration: Double = Player.fallAcceleration
	static let minSpeed: Double = 12
	static let maxSpeed: Double = 20
	static let movingAnimationSpeed: Double = 2

	var targetVelocity: Vector3 = Vector3.zero
	@BindChild(path: "VisibilityNotifier") var visibilityNotifier: VisibleOnScreenNotifier3D
	@BindChild(path: "AnimationPlayer") var animation: AnimationPlayer

	func initialize(startPosition: Vector3, player: Player, rng: RandomNumberGenerator) {
		let randomRangeOf = RandomNumberGenerator.randfRange(rng)

		var playerPosition = player.position
		playerPosition.y = 0
		lookAtFromPosition(startPosition, target: playerPosition, up: Vector3.up)

		let randomAngle = randomRangeOf(-Double.pi / 4, Double.pi / 4)
		rotateY(angle: randomAngle)

		let randomSpeed = randomRangeOf(Mob.minSpeed, Mob.maxSpeed)
		animation.speedScale = randomSpeed / Mob.maxSpeed * Mob.movingAnimationSpeed
		
		targetVelocity = Vector3.forward * randomSpeed
		targetVelocity = targetVelocity.rotated(axis: Vector3.up, angle: Double(rotation.y))
	}

	func kill(by player: Player? = nil) {
		queueFree()

		if let player {
			player.score += 1
			player.emit(signal: Player.scoreChanged)
		}
	}

	override func _ready() {
		visibilityNotifier.screenExited.connect {
			self.kill()
        }
	}

	override func _physicsProcess(delta: Double) {
		if !isOnFloor() {
			targetVelocity.y = targetVelocity.y - Float(Mob.fallAcceleration * delta)
		}

		velocity = targetVelocity
		moveAndSlide()
    }
}
