import SwiftGodot

@Godot
final class Main: Node3D {
	static let mobSceneName: StringName = "mob"

	@BindChild(path: "ResourcePreloader") var resources: ResourcePreloader
	@BindChild(path: "MobTimer") var mobTimer: Timer
	@BindChild(path: "SpawnPath/SpawnLocation") var spawnLocation: PathFollow3D
	@BindChild(path: "Player") var player: Player
	lazy var mobScene = loadMobScene()

	private func loadMobScene() -> PackedScene {
		guard
			let resource = resources.getResource(name: Main.mobSceneName),
			let scene = resource as? PackedScene
		else {
			GD.pushError("Unable to load `mob` from `ResourcePreloader` as `PackedScene`.")
			fatalError()
		}

		return scene
	}

	private func instantiateMobScene() -> Mob {
		guard
			let node = mobScene.instantiate(),
			let mob = node as? Mob
		else {
			GD.pushError("Unable to instantiate `mob` as `Mob` class.")
			fatalError()
		}

		return mob
	}

	override func _ready() {
		mobTimer.timeout.connect {
			let rng = RandomNumberGenerator()
			let randomNumber = RandomNumberGenerator.randf(rng)
		
			let mobSpawnLocation = self.spawnLocation
			mobSpawnLocation.progressRatio = randomNumber()

			let mob = self.instantiateMobScene()
			mob.initialize(startPosition: mobSpawnLocation.position, player: self.player, rng: rng)

			self.addChild(node: mob)
		}
	}
}
