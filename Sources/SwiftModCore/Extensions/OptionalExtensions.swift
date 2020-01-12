public extension Optional {
    func unwrapped(or error: @autoclosure () -> Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error()
        }

        return wrapped
    }
}
