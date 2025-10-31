using System;
using System.Collections;

namespace Zen;

struct BuiltinFunction
{
	public readonly String Name;
	public readonly uint ArgCount;
	public readonly bool Variadic;

	public this(String name, uint argCount, bool variadic)
	{
		this.Name = name;
		this.ArgCount = argCount;
		this.Variadic = variadic;
	}
}

static
{
	public const BuiltinFunction[?] BuiltinFunctions = .(
		.("print", 1, true),
		.("println", 1, true)
	);
}

class Scoper
{
	private readonly Ast m_ast;

	private readonly Scope m_globalScope ~ delete _;
	private Scope m_currentScope;

	private readonly List<CompilerError> m_errors;

	public this(Ast ast, List<CompilerError> errs)
	{
		this.m_ast = ast;
		this.m_errors = errs;

		m_globalScope = new Scope("Global Scope", null);
		m_currentScope = m_globalScope;

		addGlobalConstant("null", .Basic(BasicType.FromKind(.UntypedNull)), default);
		addGlobalConstant("true", .Basic(BasicType.FromKind(.UntypedBool)), Variant.Create<bool>(true));
		addGlobalConstant("false", .Basic(BasicType.FromKind(.UntypedBool)), Variant.Create<bool>(false));

		// Built in functions
		for (let fun in BuiltinFunctions)
		{
			let token = Token(.Identifier, "", 0, 0, .Empty);
			let entity = new Entity.Builtin(fun.Name, token, .Invalid);
			m_globalScope.Entities.Add(fun.Name, entity);
		}
	}

	private void addGlobalConstant(String name, ZenType type, Variant value)
	{
		let token = Token(.Identifier, name, 0, 0, .Empty);
		let entity = new Entity.Constant(null, value, token, type);
		m_globalScope.Entities.Add(name, entity);
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
		Scope openNewScope(String name, AstNode.Stmt.IScope statement)
		{
			if (!createScope)
				return m_currentScope;

			let newScope = new Scope(name, m_currentScope);
			statement.Scope = newScope;
			m_currentScope = newScope;
			return newScope;
		}

		Scope closeScope()
		{
			if (!createScope)
				return m_currentScope;

			m_currentScope = m_currentScope.Parent.Value;
			return m_currentScope;
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

			scope_tryDeclare(m_currentScope, fun.Name, new Entity.Function(fun, fun.Name, getTypeFromToken(fun.Type)));
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

			scope_tryDeclare(m_currentScope, str.Name, new Entity.TypeName(str, str.Name, .Structure));
		}

		if (let b = node as AstNode.Stmt.Block)
		{
			openNewScope("Block", b);
			addStatementList(b.List);
			closeScope();
		}

		if (let v = node as AstNode.Stmt.VariableDeclaration)
		{
			scope_tryDeclare(m_currentScope, v.Name, new Entity.Variable(v, v.Name, getTypeFromToken(v.Type)));
		}

		if (let c = node as AstNode.Stmt.ConstantDeclaration)
		{
			scope_tryDeclare(m_currentScope, c.Name, new Entity.Constant(c, default, c.Name, .Invalid));
		}

		if (let _if = node as AstNode.Stmt.If)
		{
			openNewScope("If", _if);
			addStatement(_if.ThenBranch, false);
			closeScope();
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

	private bool scope_tryDeclare(Scope _scope, Token name, Entity entity)
	{
		if (_scope.Entities.ContainsKey(name.Lexeme))
		{
			delete entity;
			reportError(name, "Identifier already declared");
			return false;
		}
		_scope.Entities.Add(name.Lexeme, entity);
		// entity.Scope = this;
		return true;
	}

	public static void PrintScopeTree(Scope _scope, int indent = 0)
	{
		let pad = scope String(' ', indent * 2);

		Console.WriteLine(scope $"{pad}Scope: {_scope.Name}");

		for (let e in _scope.Entities)
		{
			Console.WriteLine(scope $"{pad}  - {e.value.GetType().GetName(.. scope .())} {e.key}: {e.value.Type}");
		}

		for (let child in _scope.Children)
		{
			PrintScopeTree(child, indent + 1);
		}
	}

	// @NOTE
	// I'm thinking this should be a separate pass, like "Typer" or something that types all the entities...
	// Maybe this is fine and should change from "Scoper" to "Entity creator" or something? Hmmmm....
	private ZenType getTypeFromToken(Token token)
	{
		let res = BasicType.FromName(token.Lexeme);
		if (res case .Ok(let val))
			return .Basic(val);

		// reportError(token, "Unknown data type.");
		return .Named(token.Lexeme);
	}

	private void reportError(Token token, String message)
	{
		// Log error here.
		m_errors.Add(new .(token, message));
	}
}