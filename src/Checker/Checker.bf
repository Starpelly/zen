using System;
using System.Collections;

namespace Zen;

class Checker
{
	private readonly List<AstNode.Stmt> m_ast;
	private readonly Scope m_globalScope;
	private readonly List<CompilerError> m_errors;
	private readonly List<Entity.Function> m_functionStack = new .() ~ delete _;

	public this(List<AstNode.Stmt> ast, Scope globalScope, List<CompilerError> errs)
	{
		this.m_ast = ast;
		this.m_globalScope = globalScope;
		this.m_errors = errs;
	}

	public Result<void> Run()
	{
		checkStatementList(m_ast, m_globalScope);

		return .Ok;
	}

	private void checkStatementList(List<AstNode.Stmt> ast, Scope _scope)
	{
		for (let node in ast)
			checkStatement(node, _scope);
	}

	private void checkStatement(AstNode.Stmt node, Scope _scope)
	{
		if (let block = node as AstNode.Stmt.Block)
		{
			checkStatementList(block.List, _scope);
		}

		if (let fun = node as AstNode.Stmt.FunctionDeclaration)
		{
			let entity = fun.Scope.Lookup(fun.Name.Lexeme).Value as Entity.Function;

			m_functionStack.Add(entity);

			checkStatementList(fun.Body.List, fun.Scope);

			// @HACK, @TODO
			// Just to remember this should be an error, functions that don't have a "void" value should always return a value.
			// Generally this is not taking into account other scopes and ifs and stuff, so we definitely need to do that.
			if (!fun.Body.List.Back is AstNode.Stmt.Return && !entity.Type.IsTypeVoid())
			{
				reportError(fun.Body.Close, "Function must return value");
			}

			m_functionStack.PopBack();
		}

		if (let _var = node as AstNode.Stmt.VariableDeclaration)
		{
			checkExpr(_var.Initializer, _scope);
		}

		if (let ret = node as AstNode.Stmt.Return)
		{
			let retType = checkExpr(ret.Value, _scope);
			if (!ZenType.AreTypesIdentical(m_functionStack.Back.Type, retType))
			{
				reportError(ret.Token, scope $"Return type mismatch: expected '{m_functionStack.Back.Type.GetName()}', got '{retType.GetName()}'");
			}
		}

		if (let _if = node as AstNode.Stmt.If)
		{
			checkExpr(_if.Condition, _scope);
			checkStatement(_if.ThenBranch, _scope);
		}

		if (let expr = node as AstNode.Stmt.ExpressionStmt)
		{
			checkExpr(expr.InnerExpr, _scope);
		}
	}

	private void checkEntity(Scope _scope, StringView name, Entity entity)
	{
		if (let v = entity as Entity.Variable)
		{
			if (v.Decl.Initializer != null)
				checkExpr(v.Decl.Initializer, _scope);
		}
	}

	private ZenType checkExpr(AstNode.Expression expr, Scope _scope)
	{
		if (let lit = expr as AstNode.Expression.Literal)
		{
			BasicKind kind = .Invalid;
			Token basic_lit = lit.Token;

			switch (basic_lit.Kind)
			{
			case .Number_Int:
				kind = .Int; break;
			case .Number_Float:
				kind = .Float32; break;
			case .String:
				kind = .String; break;
			default:
				Runtime.FatalError("Unknown literal!");
			}

			return .Basic(BasicType.FromKind(kind));
		}

		if (let bin = expr as AstNode.Expression.Binary)
		{
			let x = checkExpr(bin.Left, _scope);
			let y = checkExpr(bin.Right, _scope);
			if (!ZenType.AreTypesIdentical(x, y))
			{
				reportError(bin.Op, scope $"Type mismatch in binary op '{bin.Op.Lexeme}'");
			}
			return x;
		}

		if (let @var = expr as AstNode.Expression.Variable)
		{
			let entity = _scope.Lookup(@var.Name.Lexeme);
			if (entity case .Err)
			{
				reportError(@var.Name, scope $"Undeclared identifier '{@var.Name.Lexeme}'");
				return .Invalid;
			}

			if (let constant = entity.Value as Entity.Constant)
			{
			}

			return entity.Value.Type;
		}

		if (let funCall = expr as AstNode.Expression.Call)
		{
			let entity = _scope.Lookup(funCall.Callee.Name.Lexeme);
			if (entity case .Err)
			{
				reportError(funCall.Callee.Name, scope $"Undeclared identifier '{funCall.Callee.Name.Lexeme}'");
				return .Invalid;
			}

			for (let arg in funCall.Arguments)
			{
				checkExpr(arg, _scope);
			}

			return entity.Value.Type;
		}

		if (let ass = expr as AstNode.Expression.Assign)
		{
			let x = checkExpr(ass.Assignee, _scope);
			let y = checkExpr(ass.Value, _scope);
			if (!ZenType.AreTypesIdentical(x, y))
			{
				// @TODO
				// Bad error message
				reportError(ass.Op, scope $"Type mismatch in binary op");
			}
			return x;
		}

		Runtime.FatalError("Uh oh! How did you get here?");
	}

	private void reportError(Token token, String message)
	{
		// Log error here.
		m_errors.Add(new .(token, message));
	}
}