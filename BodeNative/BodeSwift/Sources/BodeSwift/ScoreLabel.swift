import SwiftGodot

@Godot
final class ScoreLabel: Label {
	@BindChild(path: "../../Player") var player: Player

	override func _ready() {
		player.connect(signal: Player.scoreChanged, to: self, method: "update_text")
	}

	@Callable func update_text() {
		text = "Score: \(player.score)"
	}
}
