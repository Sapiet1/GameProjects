import SwiftGodot

@Godot
final class Retry: ColorRect {
	@BindChild(path: "../../Player") var player: Player

	override func _ready() {
		hide()
		player.connect(signal: Player.playerDied, to: self, method: "show_screen")
    }

	@Callable func show_screen() {
		show()
	}

	override func _unhandledInput(event: InputEvent?) {
		guard
			visible,
			let event,
			event.isActionReleased(action: "ui_accept"),
			let tree = getTree()
		else {
			return
		}

		let _ = tree.reloadCurrentScene()
    }
}
