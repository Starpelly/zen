using System;
using System.Collections;

namespace Zen;

/// This pass is responsible for binding identifiers (Functions, Structs, Enums, etc.) to
/// entities in scopes.
class Binder
{
	private readonly Ast m_ast;
	private readonly List<CompilerError> m_errors;

	private readonly Scope m_globalScope ~ delete _;
	private Scope m_currentScope;

	private List<Namespace> m_namespaceStackFileScope = new .() ~ delete _;

	private struct Namespace
	{
		public AstNode.Stmt.NamespaceDeclaration Node;
		public Entity.Namespace Entity;
	}

	public this(Ast ast, List<CompilerError> errs)
	{
		this.m_ast = ast;
		this.m_errors = errs;

		m_globalScope = new Scope("Global Scope", null, null);
		m_currentScope = m_globalScope;

		addGlobalConstant("null", .Basic(BasicType.FromKind(.UntypedNull)), default);
		addGlobalConstant("true", .Basic(BasicType.FromKind(.UntypedBool)), Variant.Create<bool>(true));
		addGlobalConstant("false", .Basic(BasicType.FromKind(.UntypedBool)), Variant.Create<bool>(false));

		// Built in functions
		for (let fun in BuiltinFunctions)
		{
			let token = Token(.Identifier, "", 0, 0, .Empty);
			let entity = new Entity.Builtin(fun.Name, token, fun.TempType);
			m_globalScope.DeclareWithName(entity, fun.Name);
		}
	}

	private void addGlobalConstant(String name, ZenType type, Variant value)
	{
		let token = Token(.Identifier, name, 0, 0, .Empty);
		let entity = new Entity.Constant(.Builtin, value, token, type);
		m_globalScope.DeclareWithName(entity, name);
	}

	public Result<Scope> Run()
	{
		addStatementList(m_ast);
		return .Ok(m_globalScope);
	}

	private void addStatementList(List<AstNode.Stmt> list)
	{
		for (let node in list)
		{
			addStatement(node);
		}
	}

	private void addStatement(AstNode.Stmt node, bool createScope = true)
	{
		Entity.Namespace getNamespaceParent()
		{
			if (!m_namespaceStackFileScope.IsEmpty)
				return m_namespaceStackFileScope.Back.Entity;
			return null;
		}

		Scope openNewScope(String name, AstNode.Stmt.IScope statement)
		{
			if (!createScope)
				return m_currentScope;

			let newScope = new Scope(name, m_currentScope, getNamespaceParent());
			statement.Scope = newScope;
			m_currentScope = newScope;
			return newScope;
		}

		Scope enterExistingScope(Scope _scope)
		{
			m_currentScope = _scope;
			return _scope;
		}

		Scope closeScope()
		{
			if (!createScope)
				return m_currentScope;

			m_currentScope = m_currentScope.Parent.Value;
			return m_currentScope;
		}

		if (let namespc = node as AstNode.Stmt.NamespaceDeclaration)
		{
			// Look if this namespace entity already exists, and if it does, we can just "piggyback" on this one.
			if (m_currentScope.LookupName<Entity.Namespace>(namespc.Name.Lexeme) case .Ok(let res))
			{
				enterExistingScope(res.Decl.Scope);

				// Remember to set the namespace's scope so we don't crash later lol
				namespc.Scope = res.Decl.Scope;

				m_namespaceStackFileScope.Add(.()
					{
						Node = namespc,
						Entity = res
					});

				addStatementList(namespc.Ast);

				m_namespaceStackFileScope.Clear();
				closeScope();
			}
			else
			{
				let entity = new Entity.Namespace(namespc, namespc.Name, .Namespace(namespc));
				scope_tryDeclare(m_currentScope, namespc.Name, entity, namespc);

				openNewScope(scope $"Namespace ({namespc.Name.Lexeme})", namespc);
				m_namespaceStackFileScope.Add(.()
					{
						Node = namespc,
						Entity = entity
					});

				addStatementList(namespc.Ast);

				m_namespaceStackFileScope.Clear();
				closeScope();
			}
		}

		/*
		if (node is AstNode.Stmt.EOF)
		{
			for (let ns in m_namespaceStackFileScope)
			{
				closeScope();
			}
		}
		*/

		if (let b = node as AstNode.Stmt.Block)
		{
			openNewScope("Block", b);
			addStatementList(b.List);
			closeScope();
		}

		if (let fun = node as AstNode.Stmt.FunctionDeclaration)
		{
			openNewScope(scope $"Function ({fun.Name.Lexeme})", fun);

			// Add parameters to scope
			for (let param in fun.Parameters)
			{
				addStatement(param);
			}
			if (fun.Kind == .Normal)
			addStatementList(fun.Body.List);

			closeScope();

			scope_tryDeclare(m_currentScope, fun.Name, new Entity.Function(fun, getNamespaceParent(), fun.Name, getZenTypeFromNamedTypeExpr(fun.Type)), fun);
		}

		if (let str = node as AstNode.Stmt.StructDeclaration)
		{
			openNewScope(scope $"Struct ({str.Name.Lexeme})", str);

			// Add fields to scope
			for (let field in str.Fields)
			{
				addStatement(field);
			}

			closeScope();

			scope_tryDeclare(m_currentScope, str.Name, new Entity.TypeName(str, getNamespaceParent(), str.Name, .Structure(str)), str);
		}

		if (let _enum = node as AstNode.Stmt.EnumDeclaration)
		{
			openNewScope(scope $"Enum ({_enum.Name.Lexeme})", _enum);

			// Add values to scope
			for (let value in _enum.Values)
			{
				addStatement(value);
			}

			closeScope();

			scope_tryDeclare(m_currentScope, _enum.Name, new Entity.TypeName(_enum, getNamespaceParent(), _enum.Name, .Enum(_enum)), _enum);
		}

		if (let enumVal = node as AstNode.Stmt.EnumFieldValue)
		{
			scope_tryDeclare(m_currentScope, enumVal.Name, new Entity.Constant(.EnumField(enumVal), default, enumVal.Name, .Basic(.FromKind(.UntypedInteger))), node);
		}

		if (let vari = node as AstNode.Stmt.VariableDeclaration)
		{
			scope_tryDeclare(m_currentScope, vari.Name, new Entity.Variable(vari, vari.Name, getZenTypeFromNamedTypeExpr(vari.Type)), vari);
		}

		if (let constant = node as AstNode.Stmt.ConstantDeclaration)
		{
			scope_tryDeclare(m_currentScope, constant.Name, new Entity.Constant(.Basic(constant), default, constant.Name, getZenTypeFromNamedTypeExpr(constant.Type)), constant);
		}

		if (let _if = node as AstNode.Stmt.If)
		{
			openNewScope("If Then", _if.ThenBranch);
			addStatement(_if.ThenBranch, false);
			closeScope();

			if (_if.ElseBranch case .Ok(let _else))
			{
				openNewScope("If Else", _else);
				addStatement(_else, false);
				closeScope();
			}
		}

		if (let _for = node as AstNode.Stmt.For)
		{
			openNewScope("For", _for);
			addStatement(_for.Initialization);
			addStatement(_for.Body, false);
			closeScope();
		}

		if (let _while = node as AstNode.Stmt.While)
		{
			openNewScope("While", _while);
			addStatement(_while.Body, false);
			closeScope();
		}
	}

	private bool scope_tryDeclare(Scope _scope, Token name, Entity entity, AstNode.Stmt stmt)
	{
		if (_scope.EntityMap.ContainsKey(name.Lexeme))
		{
			delete entity;
			reportError(name, "Identifier has already been declared");
			return false;
		}

		_scope.DeclareWithAstNode(entity, name.Lexeme, stmt);
		// entity.Scope = this;
		return true;
	}

	public static void PrintScopeTree(Scope _scope, int indent = 0)
	{
		let pad = scope String(' ', indent * 2);

		Console.WriteLine(scope $"{pad}Scope: {_scope.Name}");

		for (let e in _scope.EntityMap)
		{
			Console.WriteLine(scope $"{pad}  - {e.value.GetType().GetName(.. scope .())} {e.key}: type({e.value.Type})");
		}

		for (let child in _scope.Children)
		{
			PrintScopeTree(child, indent + 1);
		}
	}

	private ZenType getZenTypeFromNamedTypeExpr(AstNode.Expression.NamedType type)
	{
		switch (type.Kind)
		{
		case .Simple(let name):
			return getTypeFromToken(name);

		case .Qualified(let qualified):
			return .QualifiedNamed(qualified);

		case .Pointer(let innerType):
			// @FIX @REFACTOR
			// I don't feel comfortable messing with the AST here.
			type.StoredType = getZenTypeFromNamedTypeExpr(innerType);
			return .Pointer(&type.StoredType);

		case .Array(let innerExpr, let countExpr):
			// @FIX @REFACTOR
			// I don't feel comfortable messing with the AST here.
			type.StoredType = getZenTypeFromNamedTypeExpr(innerExpr);

			// @HACK, we're assuming it can only be a literal
			// This might always be true for static arrays, but dynamic arrays will need to support variables and stuff.

			int getCount()
			{
				switch (countExpr.GetKind())
				{
				case .Literal(let lit):
					return lit.Value.Get<int>();
				case .Binary(let bin):
					switch (bin.Op.Kind)
					{
					default:
						reportError(bin.Op, "Unhandled binary operator.");
						return -1;
					}
				default:
					// reportError()
					return -1;
				}
			}

			return .Array(&type.StoredType, getCount());
		}
	}

	// @NOTE
	// I'm thinking this should be a separate pass, like "Typer" or something that types all the entities...
	// Maybe this is fine and should change from "Binder" to "Entity creator" or something? Hmmmm....
	private ZenType getTypeFromToken(Token token)
	{
		let res = BasicType.FromName(token.Lexeme);
		if (res case .Ok(let val))
			return .Basic(val);

		// reportError(token, "Unknown data type.");
		return .SimpleNamed(token);
	}

	private void reportError(Token token, String message)
	{
		// Log error here.
		m_errors.Add(new .(token, message));
	}
}