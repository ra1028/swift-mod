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
        getModifiers: (Node) -> DeclModifierListSyntax?,
        getMembers: (Node) -> MemberBlockSyntax,
        replacingMembers: (Node, MemberBlockSyntax) -> Node,
        visitChildren: (Node) -> DeclSyntax
    ) -> DeclSyntax {
        let implicitInternal = options.implicitInternal ?? true
        let implicitInitializer = options.implicitInitializer ?? false
        let ignoreClassesWithInheritance = options.ignoreClassesWithInheritance ?? false

        let modifiers = getModifiers(node)
        let accessLevelModifier = modifiers?.accessLevelModifier?
            .with(\.leadingTrivia, [])
            .with(\.trailingTrivia, [])
            .assignableToInitializer
        let members = getMembers(node)
        let memberList = members.members

        let storedProperties: [StoredProperty] = memberList.compactMap { item in
            guard let variableDecl = item.decl.as(VariableDeclSyntax.self) else {
                return nil
            }

            let hasStatic = variableDecl.modifiers.hasStatic
            let hasAccessor = variableDecl.hasAccessor
            let value = variableDecl.value
            // The variable that defined as `let` and already initialized once is not need a initializer parameter..
            let isAlreadyInitialized = variableDecl.bindingSpecifier.isLet && value != nil

            guard !hasStatic && !hasAccessor && !isAlreadyInitialized,
                let identifierPattern = variableDecl.identifier?.trimmed,
                let type = variableDecl.typeAnnotation?.trimmed.type.transformed()
            else {
                return nil
            }

            return StoredProperty(
                identifierPattern: identifierPattern,
                type: type,
                value: value ?? (type.isOptional ? ExprSyntax(NilLiteralExprSyntax(nilKeyword: .keyword(.nil))) : nil)
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
        let parameterClause = FunctionParameterClauseSyntax(
            leftParen: .leftParenToken(),
            parameters: FunctionParameterListSyntax(
                storedProperties.indices.map { index in
                    let property = storedProperties[index]
                    let isLast = index == storedProperties.index(before: storedProperties.endIndex)
                    return FunctionParameterSyntax(
                        attributes: [],
                        firstName: property.identifierPattern.identifier.withLeadingTrivia(
                            .newlines(1) + parameterIndentTrivia + property.identifierPattern.identifier.leadingTrivia,
                            condition: shouldLineBreakParameters
                        ),
                        secondName: nil,
                        colon: .colonToken(trailingTrivia: .space),
                        // Assings the attributes to type if needed.
                        type: property.type.attributed(),
                        ellipsis: nil,
                        defaultValue: property.value.map { value in
                            InitializerClauseSyntax(
                                equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                                value: value
                            )
                        },
                        trailingComma: isLast
                            ? nil
                            : .commaToken().withTrailingTrivia(.space, condition: !shouldLineBreakParameters)
                    )
                }
            ),
            rightParen: TokenSyntax.rightParenToken()
                .withLeadingTrivia(.newline + indentTrivia, condition: shouldLineBreakParameters)
        )

        // Make initializer code block.
        let initializerCodeBlock = CodeBlockSyntax(
            leftBrace: TokenSyntax.leftBraceToken(
                leadingTrivia: .space,
                trailingTrivia: storedProperties.isEmpty ? [] : .newline
            ),
            statements: CodeBlockItemListSyntax(
                storedProperties.map { property in
                    CodeBlockItemSyntax(
                        item: .expr(
                            ExprSyntax(
                                SequenceExprSyntax(
                                    elements: ExprListSyntax([
                                        ExprSyntax(
                                            MemberAccessExprSyntax(
                                                base: ExprSyntax(
                                                    DeclReferenceExprSyntax(
                                                        baseName: TokenSyntax.keyword(.`self`).with(\.leadingTrivia, parameterIndentTrivia),
                                                        argumentNames: nil
                                                    )
                                                ),
                                                dot: TokenSyntax.periodToken(),
                                                name: property.identifierPattern
                                                    .withoutBackticks()
                                                    .identifier
                                                    .trimmed,
                                                declNameArguments: nil
                                            )
                                        ),
                                        ExprSyntax(
                                            AssignmentExprSyntax(
                                                equal: TokenSyntax.equalToken(
                                                    leadingTrivia: .space,
                                                    trailingTrivia: .space
                                                )
                                            )
                                        ),
                                        ExprSyntax(
                                            DeclReferenceExprSyntax(
                                                baseName: property.identifierPattern.identifier.appendingTrailingTrivia(.newlines(1)),
                                                argumentNames: nil
                                            )
                                        ),
                                    ])
                                )
                            )
                        )
                    )
                }
            ),
            rightBrace: TokenSyntax.rightBraceToken()
                .withLeadingTrivia(indentTrivia, condition: !storedProperties.isEmpty)
        )

        // Use default access level modifier or make new internal access level modifier if not present.
        let newAcessLevelModifier = (accessLevelModifier ?? DeclModifierSyntax(name: TokenSyntax.keyword(.internal)))
            .with(\.leadingTrivia, indentTrivia)
            .with(\.trailingTrivia, .space)
        // Indicating whether to assign internal access level explicitly.
        let skipAccessLevel = newAcessLevelModifier.name.isInternal && implicitInternal

        // Make initializer declaration.
        let initializerDecl = InitializerDeclSyntax(
            attributes: [],
            modifiers: skipAccessLevel ? [] : DeclModifierListSyntax([newAcessLevelModifier]),
            initKeyword: TokenSyntax.keyword(.`init`).withLeadingTrivia(indentTrivia, condition: skipAccessLevel),
            optionalMark: nil,
            genericParameterClause: nil,
            signature: FunctionSignatureSyntax(parameterClause: parameterClause),
            genericWhereClause: nil,
            body: initializerCodeBlock
        )

        // Make member declatation list.
        let member = MemberBlockItemSyntax(decl: DeclSyntax(initializerDecl), semicolon: nil)

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
            let rightBrace = members.rightBrace.with(\.leadingTrivia, .newline + parentIndentTrivia)
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
                    questionMark: TokenSyntax.postfixQuestionMarkToken()
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
                                atSign: TokenSyntax.atSignToken(),
                                attributeName: IdentifierTypeSyntax(name: .identifier("escaping"))
                                    .with(\.trailingTrivia, .space)
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
