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

			if (fun.Kind == .Extern)
			{
				return;
			}

			m_functionStack.Add(entity);

			checkStatementList(fun.Body.List, fun.Scope);

			// @HACK, @TODO
			// Just to remember this should be an error, functions that don't have a "void" value should always return a value.
			// Generally this is not taking into account other scopes and ifs and stuff, so we definitely need to do that.
			if ((fun.Body.List.IsEmpty || !fun.Body.List.Back is AstNode.Stmt.Return) && !entity.Type.IsTypeVoid())
			{
				reportError(fun.Body.Close, scope $"Function of type '{entity.Type.GetName()}' must return value");
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
			if (!ZenType.AreTypesIdenticalUntyped(m_functionStack.Back.Type, retType))
			{
				reportError(ret.Token, scope $"Return type mismatch: expected '{m_functionStack.Back.Type.GetName()}', got '{retType.GetName()}'");
			}
		}

		if (let _if = node as AstNode.Stmt.If)
		{
			checkExpressionIsTruthy(_if.Condition, _scope);
			checkStatement(_if.ThenBranch, _scope);
		}

		if (let _for = node as AstNode.Stmt.For)
		{
			if (_for.Initialization != null)
				checkStatement(_for.Initialization, _for.Scope);

			if (_for.Condition != null)
				checkExpressionIsTruthy(_for.Condition, _for.Scope);

			if (_for.Updation != null)
				checkExpr(_for.Updation, _for.Scope);

			checkStatement(_for.Body, _for.Scope);
		}

		if (let _while = node as AstNode.Stmt.While)
		{
			checkExpressionIsTruthy(_while.Condition, _while.Scope);
			checkStatement(_while.Body, _while.Scope);
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
		mixin returnVal(ZenType type)
		{
			expr.Type = type;
			return type;
		}

		if (let lit = expr as AstNode.Expression.Literal)
		{
			BasicKind kind = .Invalid;
			Token basic_lit = lit.Token;

			switch (basic_lit.Kind)
			{
			case .Number_Int:
				kind = .UntypedInteger; break;
			case .Number_Float:
				kind = .UntypedFloat; break;
			case .String:
				kind = .UntypedString; break;
			default:
				Runtime.FatalError("Unknown literal!");
			}

			returnVal!(ZenType.Basic(BasicType.FromKind(kind)));
		}

		if (let bin = expr as AstNode.Expression.Binary)
		{
			// Check if it's a conditional boolean value.
			switch (bin.Op.Kind)
			{
			case .Less,			// <
				 .LessEqual,	// <=
				 .Greater,		// >
				 .GreaterEqual,	// >=
				 .EqualEqual,	// ==
				 .BangEqual:	// !=
				return .Basic(BasicType.FromKind(.UntypedBool));
			default:
			}

			let x = checkExpr(bin.Left, _scope);
			let y = checkExpr(bin.Right, _scope);
			checkTypesComparable(bin.Op, x, y);

			// If X and Y matches, we can just return X because they're the same type.
			returnVal!(x);
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

			returnVal!(entity.Value.Type);
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

			returnVal!(entity.Value.Type);
		}

		if (let ass = expr as AstNode.Expression.Assign)
		{
			let x = checkExpr(ass.Assignee, _scope);
			let y = checkExpr(ass.Value, _scope);
			checkTypesComparable(ass.Op, x, y);

			returnVal!(x);
		}

		Runtime.FatalError("Uh oh! How did you get here?");
	}

	private void checkTypesComparable(Token token, ZenType x, ZenType y)
	{
		// @HACK
		if (!ZenType.AreTypesIdenticalUntyped(x, y))
		{
			// @FIX
			// Bad error message
			reportError(token, scope $"Types mismatch ({x.GetName()}) to ({y.GetName()})");
		}
	}

	private void checkExpressionIsTruthy(AstNode.Expression expr, Scope _scope)
	{
		let t = checkExpr(expr, _scope);
		if (!t.IsTypeBoolean())
		{
			// @FIX
			// Bad error message
			reportError(expr, "Conditional expression isn't a boolean");
		}
	}

	private void reportError(Token token, String message)
	{
		m_errors.Add(new .(token, message));
	}

	private void reportError(AstNode.Expression expr, String message)
	{
		// @TODO
		// What the fuck?
		if (let lit = expr as AstNode.Expression.Variable)
		{
			m_errors.Add(new .(lit.Name, message));
		}
		else
		{
			Runtime.FatalError("Not implemented yet!! :*(");
		}
	}
}