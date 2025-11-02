using System;
using System.Collections;
using System.Diagnostics;

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
			let entity = fun.Scope.LookupName(fun.Name.Lexeme).Value as Entity.Function;

			if (fun.Kind == .Extern)
			{
				return;
			}

			m_functionStack.Add(entity);

			checkStatementList(fun.Body.List, fun.Scope);

			// @HACK, @TODO
			// Just to remember this should be an error, functions that don't have a "void" value should always return a value.
			// Generally this is not taking into account other scopes and ifs and stuff, so we definitely need to do that.
			/*
			if ((fun.Body.List.IsEmpty || !fun.Body.List.Back is AstNode.Stmt.Return) && !entity.Type.IsTypeVoid())
			{
				reportError(fun.Body.Close, scope $"Function of type '{entity.Type.GetName()}' must return a value");
			}
			*/

			m_functionStack.PopBack();
		}

		if (let _var = node as AstNode.Stmt.VariableDeclaration)
		{
			let entity = _scope.LookupName(_var.Name.Lexeme).Value as Entity.Variable;
			if (entity.Type case .SimpleNamed(let simpleName))
			{
				let lookup = lookupScopeForIdentifier(_scope, simpleName);
				if (lookup case .Ok(let res))
				{
					entity.ResolvedTypeEntity = res;
				}
			}
			if (entity.Type case .QualifiedNamed(let qualifiedName))
			{
				checkExpr(qualifiedName, _scope);
			}

			if (_var.Initializer != null)
			{
				let initType = checkExpr(_var.Initializer, _scope);
				checkTypesComparable(_var.Operator.Value, entity.Type, initType);
			}
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
			checkStatement(_if.ThenBranch, _if.ThenBranch.Scope);
			if (_if.ElseBranch case .Ok(let _else))
				checkStatement(_else, _else.Scope);
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

		if (let _struct = node as AstNode.Stmt.StructDeclaration)
		{
			for (let field in _struct.Fields)
			{
				checkStatement(field, _struct.Scope);
			}
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

	private ZenType checkExpr(AstNode.Expression expr, Scope _scope, Scope callScope = null)
	{
		mixin returnVal(ZenType type)
		{
			expr.Type = type;
			return type;
		}

		switch (expr.GetKind())
		{
		case .Literal(let lit):
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

		case .Binary(let bin):
			// Check if it's a conditional boolean value.
			switch (bin.Op.Kind)
			{
			case .Less,			// <
				 .LessEqual,	// <=
				 .Greater,		// >
				 .GreaterEqual,	// >=
				 .EqualEqual,	// ==
				 .BangEqual:	// !=
				returnVal!(ZenType.Basic(BasicType.FromKind(.UntypedBool)));
			default:
			}

			let x = checkExpr(bin.Left, _scope);
			let y = checkExpr(bin.Right, _scope);
			checkTypesComparable(bin.Op, x, y);

			// If X and Y matches, we can just return X because they're the same type.
			returnVal!(x);

		case .Variable(let variable):
			let entity = lookupScopeForIdentifier(_scope, variable.Name);
			if (entity case .Err)
			{
				return .Invalid;
			}

			// @FIX
			// Idk how I feel about this, but basically we look at the variable's declaration to check what type it is.
			// If it's an enum, we can just return an integer, since they're pretty much the same.
			// I don't think we should do this here, Enums should probably be comparable to ints when we actually compare them.
			// Especially when enums get the ability to specify their types. But this is OK for now.
			/*
			if (let _var = entity.Value as Entity.Variable)
			{
				if (_scope.Lookup(_var.Decl.Type.Lexeme) case .Ok(let foundEntity))
				{
					if (foundEntity.Type == .Enum)
					{
						returnVal!(ZenType.Basic(.FromKind(.UntypedInteger)));
					}
				}
			}
			*/

			returnVal!(entity.Value.Type);

		case .Call(let call):
			let entity = lookupScopeForIdentifier(_scope, call.Callee.Name);
			if (entity case .Err)
			{
				return .Invalid;
			}

			for (let arg in call.Arguments)
			{
				checkExpr(arg, (callScope == null) ? _scope : callScope);
			}

			returnVal!(entity.Value.Type);

		case .Assign(let ass):
			let x = checkExpr(ass.Assignee, _scope);
			let y = checkExpr(ass.Value, _scope);
			checkTypesComparable(ass.Op, x, y);

			returnVal!(x);

		case .Get(let get):
			let objType = checkExpr(get.Object, _scope);

			mixin lookupScope(Scope _scope, Token name)
			{
				let tres = lookupScopeForIdentifier(_scope, name);
				if (tres case .Ok(let found))
				{
					if (let typename = found as Entity.TypeName)
					{
						if (let declScope = typename.Decl as AstNode.Stmt.IScope)
						{
							if (typename.Decl is AstNode.Stmt.StructDeclaration)
							{
								let entity = lookupScopeForIdentifier(declScope.Scope, get.Name);
								if (entity case .Ok(let val))
								{
									returnVal!(val.Type);
								}
							}
							else
							{
								reportError(get.Name, "Expression must have a struct type.");
							}
						}
					}
				}
			}

			if (objType case .SimpleNamed(let simpleName))
			{
				// @FIX
				// I don't know if this is guaranteed or not...
				lookupScope!(_scope, simpleName);
			}
			if (objType case .QualifiedNamed(let qualifiedName))
			{
				let leftNamespaceScope = lookupScopeForIdentifier(_scope, qualifiedName.Left);

				if (leftNamespaceScope case .Ok(let leftNamespaceEntity))
				{
					if (let decl = leftNamespaceEntity as IEntityDeclaration)
					{
						if (let iScope = decl.Decl as AstNode.Stmt.IScope)
						{
							Debug.Assert(qualifiedName.Right is AstNode.Expression.Variable);
							let _var = qualifiedName.Right as AstNode.Expression.Variable;
							lookupScope!(iScope.Scope, _var.Name);
						}
					}
				}
			}

			returnVal!(ZenType.Invalid);

		case .Set(let set):
			break;
		case .Logical(let log):
			break;
		case .Unary(let un):
			break;
		case .Grouping(let group):
			break;
		case .This(let _this):
			break;

		case .QualifiedName(let qn):
			let leftScope = _scope.LookupName(qn.Left.Lexeme);

			if (leftScope case .Ok(let leftEntity))
			{
				if (let decl = leftEntity as IEntityDeclaration)
				{
					if (let iScope = decl.Decl as AstNode.Stmt.IScope)
					{
						let val = checkExpr(qn.Right, iScope.Scope, _scope);
						returnVal!(val);
					}
				}
			}

			returnVal!(ZenType.Invalid);

		case .NamedType(let type):

			/*
			switch (type.Kind)
			{
			case .Simple(let name):
				returnVal!();
			case .Qualified(let qualified):
				returnVal!(checkExpr(qualified, _scope));
			}*/
			break;
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

	private Result<Entity> lookupScopeForIdentifier(Scope _scope, Token name)
	{
		let entity = _scope.LookupName(name.Lexeme);
		if (entity case .Err)
		{
			reportError(name, scope $"Undeclared identifier '{name.Lexeme}'");
			return .Err;
		}

		return .Ok(entity);
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