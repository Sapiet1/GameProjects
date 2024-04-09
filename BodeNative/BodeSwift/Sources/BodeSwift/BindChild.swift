import SwiftGodot

@propertyWrapper
internal struct BindChild<Wrapped: Node> {
	private var path: NodePath
	private var internalValue: Wrapped? = nil

	init(path: NodePath) {
		self.path = path
	}

	// Uses `subscript` instead.
	@available(*, unavailable, message: "This property wrapper can only be applied to classes")
	var wrappedValue: Wrapped {
		get { fatalError() }
		set { fatalError() }
	}

    public static subscript<Outer: Node>(
		_enclosingInstance instance: Outer,
		wrapped wrappedKeyPath: ReferenceWritableKeyPath<Outer, Wrapped>,
		storage storageKeyPath: ReferenceWritableKeyPath<Outer, Self>
    ) -> Wrapped {
		get {
			if let internalValue = instance[keyPath: storageKeyPath].internalValue {
				return internalValue
			} else {
				let path = instance[keyPath: storageKeyPath].path

				guard
					let wrappedNode = instance.getNode(path: NodePath(from: path)),
					let wrapped = wrappedNode as? Wrapped
				else {
					GD.pushError("`\(path)` is missing.")
					fatalError()
				}

				instance[keyPath: storageKeyPath].internalValue = wrapped
				return wrapped
			}
		}
		set {
			let path = instance[keyPath: storageKeyPath].path
			GD.pushWarning("Setting `\(path)` wrapper is a noop.")
		}
	}
}
