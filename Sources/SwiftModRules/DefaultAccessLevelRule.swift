import SwiftModCore
import SwiftSyntax

public final class DefaultAccessLevelRule: RuleDefinition {
    public static let description = RuleDescription(
        identifier: "defaultAccessLevel",
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

    public enum AccessLebel: String, Codable {
        case openOrPublic
        case `public`
        case `internal`
        case `fileprivate`
        case `private`
    }

    public struct Options: Codable {
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
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.classKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.enumKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.extensionKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.typealiasKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: AssociatedtypeDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.associatedtypeKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.protocolKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.letOrVarKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.funcKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.subscriptKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
                visitChildren: nil
            )
        }

        public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getDeclKeyword: { $0.initKeyword },
                getModifiers: { $0.modifiers },
                replacingModifiers: { $0.withModifiers($1) },
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

    func visit<Node: DeclSyntax>(
        _ node: Node,
        getDeclKeyword: (Node) -> TokenSyntax,
        getModifiers: (Node) -> ModifierListSyntax?,
        replacingModifiers: (Node, ModifierListSyntax) -> Node,
        visitChildren: ((Node) -> DeclSyntax)?
    ) -> DeclSyntax {
        let implicitInternal = options.implicitInternal ?? true

        let modifiers = getModifiers(node) ?? SyntaxFactory.makeModifierList([])
        let visitFinally = visitChildren ?? { $0 }
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
                    ? SyntaxFactory.makeOpenKeyward()
                    : SyntaxFactory.makePublicKeyword()
                actualAccessLevel = shouldOpen ? .openOrPublic : .public

            case .public:
                modifierTokenToAssign = SyntaxFactory.makePublicKeyword()
                actualAccessLevel = .public

            case .internal:
                modifierTokenToAssign = implicitInternal ? nil : SyntaxFactory.makeInternalKeyword()
                actualAccessLevel = .internal

            case .fileprivate:
                modifierTokenToAssign = SyntaxFactory.makeFileprivateKeyword()
                actualAccessLevel = .fileprivate

            case .private:
                modifierTokenToAssign = SyntaxFactory.makePrivateKeyword()
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
            DeclModifierSyntax { builder in
                builder.useName(token.withTrailingTrivia(.spaces(1)))
            }
        }

        // If originally has modifiers.
        if let modifier = modifier, let firstModifier = modifiers.first, let firstModifierToken = firstModifier.firstToken {
            // Prepends an access level modifier that exchanged the leading trivia.
            let (leading, trailing) = SyntaxFactory.movingLeadingTrivia(
                leading: modifier,
                for: modifier.name,
                trailing: firstModifier,
                for: firstModifierToken
            )
            let newModifiers = SyntaxFactory.makeModifierList([leading, trailing] + Array(modifiers.dropFirst()))
            return visitFinally(replacingModifiers(node, newModifiers))
        }
        else if let modifier = modifier, let nodeToken = getDeclKeyword(node).firstToken {
            // Assigns an access level modifier that exchanged the leading trivia.
            let (newModifier, newNode) = SyntaxFactory.movingLeadingTrivia(
                leading: modifier,
                for: modifier.name,
                trailing: node,
                for: nodeToken
            )
            let newModifiers = SyntaxFactory.makeModifierList([newModifier])
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

private extension DeclSyntax {
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

private extension ModifierListSyntax {
    var accessLevel: DefaultAccessLevelRule.AccessLebel? {
        accessLevelModifier.flatMap { modifier in
            switch modifier.name.tokenKind {
            case .openKeyward:
                return .openOrPublic

            case .publicKeyword:
                return .public

            case .internalKeyword:
                return .internal

            case .fileprivateKeyword:
                return .fileprivate

            case .privateKeyword:
                return .private

            default:
                return nil
            }
        }
    }
}
