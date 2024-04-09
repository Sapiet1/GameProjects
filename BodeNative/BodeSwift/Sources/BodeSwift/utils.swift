postfix operator ++

extension Int {
	static postfix func ++(left: inout Int) -> Int {
		let value = left
		left += 1
		return value
	}
}
