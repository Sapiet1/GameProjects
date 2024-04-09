import SwiftGodot

@Godot
final class Block: RigidBody3D {
	static var id: Int = 0
	static let deletionTimer: Double = 5

	@BindChild(path: "Despawn") var despawnArea: Area3D
	
	let blockID = Block.id++
	var player: Player? = nil

	func initialize(with player: Player) {
		self.player = player
	}

	override func _ready() {
		contactMonitor = true
		maxContactsReported = 10
	
		despawnArea.bodyEntered.connect { body in 
			guard let player = body as? Player else {
				return
			}

			player.nearbyBlocks.insert(self.blockID)
		}

		despawnArea.bodyExited.connect { body in
			guard let player = body as? Player else {
				return
			}

			self.queueFree()
			player.nearbyBlocks.remove(self.blockID)
		}

		bodyEntered.connect { body in
			if let player = body as? Player {
				player.kill()
			} else if let mob = body as? Mob {
				mob.kill(by: self.player)
			}
		}
	}
}
