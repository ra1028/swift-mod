import SwiftModCore
import SwiftSyntax

public final class DefaultAccessLevelRule: RuleDefinition {
    public static let description = RuleDescription(
        name: "defaultAccessLevel",
        priority: .default,
        overview: "Assigns the suitable access level to all declaration syntaxes if not present",
        exampleOptions: Options(
            accessLevel: .openOrPublic,
            implicitInternal: true
        ),
        exampleBefore: """
            struct Foo {
                var foo: Int

                // Not triggered if access level is already present
                internal var bar: String

                func function(string: String) -> String { string }
            }

            private struct Bar {
                // The member item acceess level is adjusted for owner's access level.
                var foo: Int
            }
            """,
        exampleAfter: """
            public struct Foo {
                public var foo: Int

                // Not triggered if access level is already present
                internal var bar: String

                public func function(string: String) -> String { string }
            }

            private struct Bar {
                // The member item acceess level is adjusted for owner's access level.
                var foo: Int
            }
            """
    )

    public enum AccessLebel: String, Codable, Sendable {
        case openOrPublic
        case `public`
        case `internal`
        case `fileprivate`
        case `private`
    }

    public struct Options: Codable, Sendable {
        public var accessLevel: AccessLebel
        public var implicitInternal: Bool?

        public init(accessLevel: AccessLebel, implicitInternal: Bool?) {
            self.accessLevel = accessLevel
            self.implicitInternal = implicitInternal
        }
    }

    public final class Rewriter: RuleSyntaxRewriter<Options> {
        private var visitStack = Stack<Visit>()

        public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.structKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.classKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.actorKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.enumKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.extensionKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.typealiasKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: AssociatedTypeDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.associatedtypeKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.protocolKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.bindingSpecifier },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.funcKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.subscriptKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.initKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.with(\.modifiers, $1) },
                visitChildren: nil
            )
        }
    }
}

private extension DefaultAccessLevelRule.Rewriter {
    struct Visit {
        var accessLevel: DefaultAccessLevelRule.AccessLebel?
        var extensionScopeAccessLebel: DefaultAccessLevelRule.AccessLebel?
        var canDeclOpen: Bool
        var canAssignAccessLevelToChildren: Bool

        var canOpenChildren: Bool {
            accessLevel == .openOrPublic && canDeclOpen && canAssignAccessLevelToChildren
        }
    }

    func visit<Node: DeclSyntaxProtocol>(
        _ node: Node,
        getDeclKeyword: (Node) -> TokenSyntax,
        getModifiers: (Node) -> DeclModifierListSyntax?,
        replacingModifiers: (Node, DeclModifierListSyntax) -> Node,
        visitChildren: ((Node) -> DeclSyntax)?
    ) -> DeclSyntax {
        let implicitInternal = options.implicitInternal ?? true

        let modifiers = getModifiers(node) ?? DeclModifierListSyntax([])
        let visitFinally = visitChildren ?? DeclSyntax.init
        let parentVisit = visitStack.top

        let modifierTokenToAssign: TokenSyntax?
        let actualAccessLevel: DefaultAccessLevelRule.AccessLebel?
        let canAssignAccessLevelToChildren: Bool

        if node is ExtensionDeclSyntax {
            modifierTokenToAssign = nil
            actualAccessLevel = modifiers.accessLevel
            canAssignAccessLevelToChildren = actualAccessLevel == nil
        }
        else if let accessLevel = modifiers.accessLevel {
            modifierTokenToAssign = nil
            actualAccessLevel = accessLevel
            canAssignAccessLevelToChildren = true
        }
        else if let parentVisit = parentVisit, !parentVisit.canAssignAccessLevelToChildren {
            modifierTokenToAssign = nil
            actualAccessLevel = modifiers.accessLevel
            canAssignAccessLevelToChildren = true
        }
        else {
            canAssignAccessLevelToChildren = true

            // Select assignable access level.
            let assumedAccessLevel = assignableAccessLevel()

            switch assumedAccessLevel {
            case .openOrPublic:
                // Indicating whether that can open this decralation in parent scope access level.
                let canOpenInParent = node is ClassDeclSyntax || (node.canOpen && parentVisit?.canOpenChildren ?? false)
                let shouldOpen = canOpenInParent && !modifiers.hasFinal && !modifiers.hasStatic
                modifierTokenToAssign =
                    shouldOpen
                    ? .keyword(.open)
                    : .keyword(.public)
                actualAccessLevel = shouldOpen ? .openOrPublic : .public

            case .public:
                modifierTokenToAssign = .keyword(.public)
                actualAccessLevel = .public

            case .internal:
                modifierTokenToAssign = implicitInternal ? nil : .keyword(.internal)
                actualAccessLevel = .internal

            case .fileprivate:
                modifierTokenToAssign = .keyword(.fileprivate)
                actualAccessLevel = .fileprivate

            case .private:
                modifierTokenToAssign = .keyword(.private)
                actualAccessLevel = .private
            }
        }

        // Back to the parent stack after exit current scope.
        defer { visitStack.pop() }
        visitStack.push(
            Visit(
                accessLevel: actualAccessLevel,
                extensionScopeAccessLebel: node is ExtensionDeclSyntax
                    ? actualAccessLevel
                    : parentVisit?.extensionScopeAccessLebel,
                canDeclOpen: node.canOpen,
                canAssignAccessLevelToChildren: canAssignAccessLevelToChildren
            )
        )

        let modifier = modifierTokenToAssign.map { token in
            DeclModifierSyntax(name: token.with(\.trailingTrivia, .space))
        }

        // If originally has modifiers.
        if let modifier = modifier, let firstModifier = modifiers.first, let firstModifierToken = firstModifier.firstToken(viewMode: .sourceAccurate) {
            // Prepends an access level modifier that exchanged the leading trivia.
            let (leading, trailing) = TokenSyntax.movingLeadingTrivia(
                leading: modifier,
                for: modifier.name,
                trailing: firstModifier,
                for: firstModifierToken
            )
            let newModifiers = DeclModifierListSyntax([leading, trailing] + Array(modifiers.dropFirst()))
            return visitFinally(replacingModifiers(node, newModifiers))
        }
        else if let modifier = modifier, let nodeToken = getDeclKeyword(node).firstToken(viewMode: .sourceAccurate) {
            // Assigns an access level modifier that exchanged the leading trivia.
            let (newModifier, newNode) = TokenSyntax.movingLeadingTrivia(
                leading: modifier,
                for: modifier.name,
                trailing: node,
                for: nodeToken
            )
            let newModifiers = DeclModifierListSyntax([newModifier])
            return visitFinally(replacingModifiers(newNode, newModifiers))
        }
        else {
            return visitFinally(node)
        }
    }

    func assignableAccessLevel() -> DefaultAccessLevelRule.AccessLebel {
        let parentVisit = visitStack.top
        let scopeAccessLevel = parentVisit?.accessLevel ?? parentVisit?.extensionScopeAccessLebel

        guard let priorityAccessLevel = scopeAccessLevel else {
            return options.accessLevel
        }

        if priorityAccessLevel.priority >= options.accessLevel.priority {
            return options.accessLevel
        }
        else if priorityAccessLevel.priority < DefaultAccessLevelRule.AccessLebel.internal.priority {
            return .internal
        }
        else {
            return priorityAccessLevel
        }
    }
}

private extension DefaultAccessLevelRule.AccessLebel {
    var priority: Int {
        switch self {
        case .openOrPublic, .public:
            return 3

        case .internal:
            return 2

        case .fileprivate:
            return 1

        case .private:
            return 0
        }
    }
}

private extension DeclSyntaxProtocol {
    var canOpen: Bool {
        switch self {
        case is ClassDeclSyntax, is FunctionDeclSyntax, is SubscriptDeclSyntax:
            return true

        case let decl as VariableDeclSyntax:
            return decl.hasAccessor

        default:
            return false
        }
    }
}

private extension DeclModifierListSyntax {
    var accessLevel: DefaultAccessLevelRule.AccessLebel? {
        accessLevelModifier.flatMap { modifier in
            switch modifier.name.tokenKind {
            case .keyword(.open):
                return .openOrPublic

            case .keyword(.public):
                return .public

            case .keyword(.internal):
                return .internal

            case .keyword(.fileprivate):
                return .fileprivate

            case .keyword(.private):
                return .private

            default:
                return nil
            }
        }
    }
}
