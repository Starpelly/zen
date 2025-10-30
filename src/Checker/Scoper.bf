using System;
using System.Collections;

namespace Zen;

class Scoper
{
	private readonly Ast m_ast;

	private readonly Scope m_globalScope ~ delete _;
	private Scope m_currentScope;

	public this(Ast ast, List<CompilerError> errs)
	{
		this.m_ast = ast;
		// this.m_errors = errs;

		m_globalScope = new Scope("Global Scope", null);
		m_currentScope = m_globalScope;
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

	private void addStatement(AstNode.Stmt node)
	{
		if (let fun = node as AstNode.Stmt.FunctionDeclaration)
		{
			openScope(scope $"Function ({fun.Name.Lexeme})", fun);

			// Add parameters to scope
			for (let param in fun.Parameters)
			{
				addStatement(param);
			}
			addStatementList(fun.Body.List);

			closeScope();

			let entity = new Entity.Function();
			entity.Token = fun.Name;
			entity.Decl = fun;
			entity.Type = .Basic(ZenType.GetBasicType(fun.Type.Lexeme));
			m_currentScope.TryDeclare(fun.Name.Lexeme, entity);
		}

		if (let b = node as AstNode.Stmt.Block)
		{
			openScope("Block", b);
			addStatementList(b.List);
			closeScope();
		}

		if (let v = node as AstNode.Stmt.VariableDeclaration)
		{
			let entity = new Entity.Variable();
			entity.Token = v.Name;
			entity.Decl = v;
			entity.Type = .Basic(ZenType.GetBasicType(v.Type.Lexeme));
			m_currentScope.TryDeclare(v.Name.Lexeme, entity);
		}

		if (let _if = node as AstNode.Stmt.If)
		{
			openScope("If", _if);
			addStatement(_if.ThenBranch);
			closeScope();
		}

		if (let _for = node as AstNode.Stmt.For)
		{
			openScope("For", _for);
			addStatement(_for.Body);
			closeScope();
		}
	}

	private Scope openScope(String name, AstNode.Stmt.IScope statement)
	{
		let newScope = new Scope(name, m_currentScope);
		statement.Scope = newScope;
		m_currentScope = newScope;
		return newScope;
	}

	private Scope closeScope()
	{
		m_currentScope = m_currentScope.Parent.Value;
		return m_currentScope;
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
}