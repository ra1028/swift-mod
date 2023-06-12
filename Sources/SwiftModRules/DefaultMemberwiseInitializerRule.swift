import SwiftModCore
import SwiftSyntax

public final class DefaultMemberwiseInitializerRule: RuleDefinition {
    public static let description = RuleDescription(
        name: "defaultMemberwiseInitializer",
        priority: .low,
        overview: "Defines a memberwise initializer according to the access level in the type declaration if not present",
        exampleOptions: Options(
            implicitInitializer: false,
            implicitInternal: true,
            ignoreClassesWithInheritance: false
        ),
        exampleBefore: """
            struct Foo {
                var foo: Int
                var bar: String?
            }

            struct Bar {
                var foo: Int

                // Not triggered if initializer is already present
                init() {
                    self.foo = 100
                }
            }
            """,
        exampleAfter: """
            struct Foo {
                var foo: Int
                var bar: String?

                init(
                    foo: Int,
                    bar: String? = nil
                ) {
                    self.foo = foo
                    self.bar = bar
                }
            }

            struct Bar {
                var foo: Int

                // Not triggered if initializer is already present
                init() {
                    self.foo = 100
                }
            }
            """
    )

    public struct Options: Codable {
        public var implicitInitializer: Bool?
        public var implicitInternal: Bool?
        public var ignoreClassesWithInheritance: Bool?

        public init(implicitInitializer: Bool?, implicitInternal: Bool?, ignoreClassesWithInheritance: Bool?) {
            self.implicitInitializer = implicitInitializer
            self.implicitInternal = implicitInternal
            self.ignoreClassesWithInheritance = ignoreClassesWithInheritance
        }
    }

    public final class Rewriter: RuleSyntaxRewriter<Options> {
        public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getModifiers: { $0.modifiers },
                getMembers: { $0.memberBlock },
                replacingMembers: { $0.with(\.memberBlock, $1) },
                visitChildren: super.visit
            )
        }

        public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            visit(
                node,
                getModifiers: { $0.modifiers },
                getMembers: { $0.memberBlock },
                replacingMembers: { $0.with(\.memberBlock, $1) },
                visitChildren: super.visit
            )
        }
    }
}

private extension DefaultMemberwiseInitializerRule.Rewriter {
    struct StoredProperty {
        var identifierPattern: IdentifierPatternSyntax
        var type: TypeSyntax
        var value: ExprSyntax?
    }

    func visit<Node: DeclSyntaxProtocol>(
        _ node: Node,
        getModifiers: (Node) -> ModifierListSyntax?,
        getMembers: (Node) -> MemberDeclBlockSyntax,
        replacingMembers: (Node, MemberDeclBlockSyntax) -> Node,
        visitChildren: (Node) -> DeclSyntax
    ) -> DeclSyntax {
        let implicitInternal = options.implicitInternal ?? true
        let implicitInitializer = options.implicitInitializer ?? false
        let ignoreClassesWithInheritance = options.ignoreClassesWithInheritance ?? false

        let modifiers = getModifiers(node)
        let accessLevelModifier = modifiers?.accessLevelModifier?
            .trimmed
            .assignableToInitializer
        let members = getMembers(node)
        let memberList = members.members

        let storedProperties: [StoredProperty] = memberList.compactMap { item -> StoredProperty? in
            guard let variableDecl = item.decl.as(VariableDeclSyntax.self) else {
                return nil
            }

            let hasStatic = variableDecl.modifiers?.hasStatic ?? false
            let hasAccessor = variableDecl.hasAccessor
            let value = variableDecl.value
            // The variable that defined as `let` and already initialized once is not need a initializer parameter..
            let isAlreadyInitialized = variableDecl.bindingKeyword.isLet && value != nil

            guard !hasStatic && !hasAccessor && !isAlreadyInitialized,
                let identifierPattern = variableDecl.identifier?.trimmed,
                let type = variableDecl.typeAnnotation?.trimmed.type.transformed()
            else {
                return nil
            }

            return StoredProperty(
                identifierPattern: identifierPattern,
                type: type,
                value: value ?? (type.isOptional ? ExprSyntax(NilLiteralExprSyntax()) : nil)
            )
        }

        // Indicating whether use default implicit initializer.
        let shouldSkipStructImplicitInitializer = node is StructDeclSyntax && implicitInitializer && accessLevelModifier?.name.isInternal ?? true
        let shouldSkipClassImplicitInitializer = node is ClassDeclSyntax && implicitInitializer && accessLevelModifier?.name.isInternal ?? true && storedProperties.isEmpty
        let shouldSkipClassWithInheritance = ignoreClassesWithInheritance && (node as? ClassDeclSyntax).map { $0.inheritanceClause != nil } ?? false
        let isInitializerExists = memberList.contains { $0.decl.is(InitializerDeclSyntax.self) }

        if shouldSkipStructImplicitInitializer || shouldSkipClassImplicitInitializer || shouldSkipClassWithInheritance || isInitializerExists {
            return visitChildren(node)
        }

        let parentIndentTrivia = node.firstToken(viewMode: .sourceAccurate)?.leadingTrivia.indentation ?? Trivia()
        let indentTrivia = parentIndentTrivia + format.indent.trivia
        let parameterIndentTrivia = indentTrivia + format.indent.trivia
        let shouldLineBreakParameters = format.lineBreakBeforeEachArgument && storedProperties.count > 1

        // Make parameter clause.
        let parameterClause = ParameterClauseSyntax(
            leftParen: .leftParenToken(),
            parameterList: FunctionParameterListSyntax(
                storedProperties.indices.map { index in
                    let property = storedProperties[index]
                    let isLast = index == storedProperties.index(before: storedProperties.endIndex)
                    return FunctionParameterSyntax(
                        attributes: nil,
                        firstName: property.identifierPattern.identifier.withLeadingTrivia(
                            .newlines(1) + parameterIndentTrivia + property.identifierPattern.identifier.leadingTrivia,
                            condition: shouldLineBreakParameters
                        ),
                        secondName: nil,
                        colon: .colonToken().with(\.trailingTrivia, .spaces(1)),
                        // Assings the attributes to type if needed.
                        type: property.type.attributed(),
                        ellipsis: nil,
                        defaultArgument: property.value.map { value in
                            InitializerClauseSyntax(
                                equal: .equalToken()
                                    .with(\.leadingTrivia, .spaces(1))
                                    .with(\.trailingTrivia, .spaces(1)),
                                value: value
                            )
                        },
                        trailingComma: isLast
                            ? nil
                        : .commaToken()
                            .withTrailingTrivia(.spaces(1), condition: !shouldLineBreakParameters)
                    )
                }
            ),
            rightParen: .rightParenToken().withLeadingTrivia(.newlines(1) + indentTrivia, condition: shouldLineBreakParameters)
        )

        // Make initializer code block.

        let initializerCodeBlock = CodeBlockSyntax(
            leftBrace: .leftBraceToken()
                .with(\.leadingTrivia, .spaces(1))
                .with(\.trailingTrivia, storedProperties.isEmpty ? [] : .newlines(1)),
            statements: CodeBlockItemListSyntax(
                storedProperties.map { property in
                    CodeBlockItemSyntax(
                        item: .expr(ExprSyntax(SequenceExprSyntax(
                                elements: ExprListSyntax([
                                    ExprSyntax(
                                        MemberAccessExprSyntax(
                                            base: ExprSyntax(
                                                IdentifierExprSyntax(
                                                    identifier: .keyword(.self).with(\.leadingTrivia, parameterIndentTrivia),
                                                    declNameArguments: nil
                                                )
                                            ),
                                            dot: .periodToken(),
                                            name: property.identifierPattern
                                                .withoutBackticks()
                                                .identifier
                                                .trimmed,
                                            declNameArguments: nil
                                        )
                                    ),
                                    ExprSyntax(
                                        AssignmentExprSyntax(
                                            assignToken: .equalToken(
                                                leadingTrivia: .spaces(1),
                                                trailingTrivia: .spaces(1)
                                            )
                                        )
                                    ),
                                    ExprSyntax(
                                        IdentifierExprSyntax(
                                            identifier: property.identifierPattern.identifier.appendingTrailingTrivia(.newlines(1)),
                                            declNameArguments: nil
                                        )
                                    ),
                                ])

                        ))),
                        semicolon: nil
                    )
                }
            ),
            rightBrace: .rightBraceToken()
                .withLeadingTrivia(indentTrivia, condition: !storedProperties.isEmpty)
        )

        // Use default access level modifier or make new internal access level modifier if not present.
        let newAcessLevelModifier = (accessLevelModifier ?? DeclModifierSyntax(name: .keyword(.internal)))
            .with(\.leadingTrivia, indentTrivia)
            .with(\.trailingTrivia, .spaces(1))
        // Indicating whether to assign internal access level explicitly.
        let skipAccessLevel = newAcessLevelModifier.name.isInternal && implicitInternal

        // Make initializer declaration.
        let initializerDecl = InitializerDeclSyntax(
            attributes: nil,
            modifiers: skipAccessLevel ? nil : ModifierListSyntax([newAcessLevelModifier]),
            initKeyword: .keyword(.`init`).withLeadingTrivia(indentTrivia, condition: skipAccessLevel),
            optionalMark: nil,
            genericParameterClause: nil,
            signature: FunctionSignatureSyntax(input: parameterClause),
            genericWhereClause: nil,
            body: initializerCodeBlock
        )

        // Make member declatation list.
        let member = MemberDeclListItemSyntax(decl: DeclSyntax(initializerDecl), semicolon: nil)

        // If originally has members.
        if let lastMemberToken = memberList.lastToken(viewMode: .sourceAccurate) {
            let newMemberList =
                TokenSyntax
                .replacingTrivia(memberList, for: lastMemberToken, trailing: .newlines(2))
                .appending(member)
            let newMembers = members.with(\.members, newMemberList)
            let newNode = replacingMembers(node, newMembers)
            return visitChildren(newNode)
        }
        else {
            let leftBrace = members.leftBrace.withTrailingNewLinews(count: 1)
            let rightBrace = members.rightBrace.with(\.leadingTrivia, .newlines(1) + parentIndentTrivia)
            let newMembers = members.addMember(member)
                .with(\.leftBrace, leftBrace)
                .with(\.rightBrace, rightBrace)
            let newNode = replacingMembers(node, newMembers)
            return visitChildren(newNode)
        }
    }
}

private extension TokenSyntax {
    var isLet: Bool {
        tokenKind == .keyword(.let)
    }

    var isInternal: Bool {
        tokenKind == .keyword(.internal)
    }

    func withTrailingNewLinews(count: Int) -> TokenSyntax {
        let newlines = trailingTrivia.numberOfNewlines
        return newlines >= count ? self : with(\.trailingTrivia, .newlines(count - newlines))
    }

    func withLeadingNewlines(count: Int) -> TokenSyntax {
        let newlines = leadingTrivia.numberOfNewlines
        return newlines >= count ? self : with(\.leadingTrivia, .newlines(count - newlines))
    }
}

private extension DeclModifierSyntax {
    var assignableToInitializer: DeclModifierSyntax? {
        switch name.tokenKind {
        case .keyword(.open):
            return with(\.name, .keyword(.public))

        case .keyword(.public):
            return self

        default:
            return nil
        }
    }
}

private extension TypeSyntax {
    func transformed() -> TypeSyntax {
        if let iuo = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return TypeSyntax(
                OptionalTypeSyntax(
                    wrappedType: iuo.wrappedType,
                    questionMark: .postfixQuestionMarkToken()
                )
            )
        }
        else {
            return self
        }
    }

    func attributed() -> TypeSyntax {
        if self.is(FunctionTypeSyntax.self) {
            return TypeSyntax(
                AttributedTypeSyntax(
                    specifier: nil,
                    attributes: AttributeListSyntax([
                        .attribute(
                            AttributeSyntax(
                                atSignToken: .atSignToken(),
                                attributeName: SimpleTypeIdentifierSyntax(name: .identifier("escaping")).with(\.trailingTrivia, .spaces(1))
                            )
                        )
                    ]),
                    baseType: self
                )
            )
        }
        else {
            return self
        }
    }
}
