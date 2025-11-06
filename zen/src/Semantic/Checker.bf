using System;
using System.Collections;
using System.Diagnostics;

namespace Zen;

class Checker : Visitor
{
	private readonly List<AstNode.Stmt> m_ast;
	private readonly Scope m_globalScope;
	private readonly List<Entity.Function> m_functionStack = new .() ~ delete _;

	public this(List<AstNode.Stmt> ast, Scope globalScope)
	{
		this.m_ast = ast;
		this.m_globalScope = globalScope;
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

	private void checkStatement(AstNode.Stmt stmt, Scope _scope)
	{
		if (let block = stmt as AstNode.Stmt.Block)
		{
			checkStatementList(block.List, block.Scope ?? _scope);
		}

		if (let ns = stmt as AstNode.Stmt.NamespaceDeclaration)
		{
			checkStatementList(ns.Ast, ns.Scope);
			// _scope = ns.Scope;
		}

		if (let fun = stmt as AstNode.Stmt.FunctionDeclaration)
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

		if (let _var = stmt as AstNode.Stmt.VariableDeclaration)
		{
			let entity = _scope.LookupName(_var.Name.Lexeme).Value as Entity.Variable;

			if (_var.Initializer != null)
			{
				let initType = checkExpr(_var.Initializer, _scope, null, entity.ResolvedType);
				if (!checkTypesComparable(entity.ResolvedType, initType))
				{
					reportError(_var.Initializer, scope $"Cannot assign '{initType.GetName(.. scope .())}' to '{entity.ResolvedType.GetName(.. scope .())}'");
				}
			}
		}

		if (let _const = stmt as AstNode.Stmt.ConstantDeclaration)
		{
			let entity = _scope.LookupName(_const.Name.Lexeme).Value as Entity.Constant;

			if (_const.Initializer != null)
			{
				let initType = checkExpr(_const.Initializer, _scope, null, entity.ResolvedType);
				checkTypesComparable(_const.Operator.Value, entity.ResolvedType, initType);
			}
		}

		if (let ret = stmt as AstNode.Stmt.Return)
		{
			if (ret.Value != null)
			{
				let retType = checkExpr(ret.Value, _scope);
				if (!ZenType.AreTypesIdenticalUntyped(m_functionStack.Back.Type, retType))
				{
					reportError(ret.Token, scope $"Return type mismatch: expected '{m_functionStack.Back.Type.GetName(.. scope .())}', got '{retType.GetName(.. scope .())}'");
				}
			}
		}

		if (let _if = stmt as AstNode.Stmt.If)
		{
			checkExpressionIsTruthy(_if.Condition, _scope);
			checkStatement(_if.ThenBranch, _if.ThenBranch.Scope);
			if (_if.ElseBranch case .Ok(let _else))
				checkStatement(_else, _else.Scope);
		}

		if (let _for = stmt as AstNode.Stmt.For)
		{
			if (_for.Initialization != null)
				checkStatement(_for.Initialization, _for.Scope);

			if (_for.Condition != null)
				checkExpressionIsTruthy(_for.Condition, _for.Scope);

			if (_for.Updation != null)
				checkExpr(_for.Updation, _for.Scope);

			checkStatement(_for.Body, _for.Scope);
		}

		if (let _while = stmt as AstNode.Stmt.While)
		{
			checkExpressionIsTruthy(_while.Condition, _while.Scope);
			checkStatement(_while.Body, _while.Scope);
		}

		if (let _struct = stmt as AstNode.Stmt.StructDeclaration)
		{
			for (let field in _struct.Fields)
			{
				checkStatement(field, _struct.Scope);
			}
		}

		if (let expr = stmt as AstNode.Stmt.ExpressionStmt)
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

	private ZenType checkExpr(AstNode.Expression expr, Scope _scope, Scope callScope = null, ZenType? expectedTypeQ = null)
	{
		switch (expr.GetKind())
		{
		case .Literal(let lit):
			return lit.GetLiteralType();

		case .Binary(let bin):
			// First we'll check the x and y expressions, we MIGHT return a boolean depending on the operator type.
			// But this is just so we can resolve these expressions for checking purposes (and also the generator).
			let x = checkExpr(bin.Left, _scope);
			let y = checkExpr(bin.Right, _scope);

			// Check if it's a conditional boolean value.
			switch (bin.Op.Kind)
			{
			case .Less,			// <
				 .LessEqual,	// <=
				 .Greater,		// >
				 .GreaterEqual,	// >=
				 .EqualEqual,	// ==
				 .BangEqual:	// !=
				return ZenType.Basic(BasicType.FromKind(.UntypedBool));
			default:
			}

			checkTypesComparable(bin.Op, x, y);

			// If X and Y matches, we can just return X because they're the same type.
			return x;

		case .Variable(let variable):
			let entity = lookupScopeForIdentifier(_scope, variable.Name);
			if (entity case .Err)
			{
				return .Invalid;
			}

			if (entity.Value.GetKind() case .Variable(let _var))
			{
				return _var.ResolvedType;
			}
			else if (entity.Value.GetKind() case .Constant(let _const))
			{
				if (_const.Decl case .Normal)
				{
					return _const.ResolvedType;
				}
			}

			return entity.Value.Type;

		case .Call(let call):
			let entity = lookupScopeForIdentifier(_scope, call.Callee.Name);
			if (entity case .Err)
			{
				return .Invalid;
			}

			if (let calleeFun = entity.Value as Entity.Function)
			{
				if (call.Arguments.Count > calleeFun.Decl.Parameters.Count)
				{
					reportError(call.Close, scope $"Too many arguments, expected {call.Arguments.Count - calleeFun.Decl.Parameters.Count} fewer.");
					return entity.Value.Type;
				}
				else if (call.Arguments.Count < calleeFun.Decl.Parameters.Count)
				{
					reportError(call.Close, scope $"Not enough arguments, expected {calleeFun.Decl.Parameters.Count - call.Arguments.Count} more.");
					return entity.Value.Type;
				}

				// for (let arg in call.Arguments)
				// Runtime.FatalError("please finish this");
				for (let i < call.Arguments.Count)
				{
					let arg = call.Arguments[i];

					let argType = checkExpr(arg, callScope ?? _scope);
					let calleeParamType = checkExpr(calleeFun.Decl.Parameters[i].Type, _scope);

					// Check if the two types are compatible
					checkTypesComparable(call.Close, argType, calleeParamType);
				}

				return calleeFun.ResolvedType;
			}

			Debug.Assert(false);
			return .Invalid;

		case .Assign(let ass):
			let x = checkExpr(ass.Assignee, _scope);
			let y = checkExpr(ass.Value, _scope, null, x);
			checkTypesComparable(ass.Op, x, y);

			return x;

		case .Get(let get):
			let objType = checkExpr(get.Object, _scope);

			// Runtime.Assert(objType case .Structure, "You can only get on structs");

			mixin doStruct(ZenType type)
			{
				// I couldn't figure out how to pass this by type in parameters...
				Runtime.Assert(type case ZenType.Structure(let _struct));

				// @TEMP @HACK
				if (objType.IsTypePointer())
				{
					get.IsPointer = true;
				}

				// Look inside this struct for the member variable we're getting.
				let entity = lookupScopeForIdentifier(_struct.Scope, get.Name);
				if (entity case .Ok(let val))
				{
					if (let _var = val as Entity.Variable)
					{
						// if (_var.ResolvedType != null)
						return _var.ResolvedType;
					}
					return val.Type;
				}
			}

			if (objType case .Structure)
			{
				doStruct!(objType);
			}
			else if (objType case .Pointer(let element))
			{
				let value = *element;
				if (value case .Structure)
				{
					doStruct!(value);
				}
			}
			else
			{
				reportError(get.Name, "You can only get on structs.");
			}

			return ZenType.Invalid;

		case .Set(let set):
			break;

		case .Logical(let log):
			// @TODO is this important?
			//let op = log.Op;

			let leftType = checkExpr(log.Left, _scope);
			let rightType = checkExpr(log.Right, _scope);

			if (!leftType.IsTypeBoolean())
			{
				reportError(log.Left, "Conditional expression isn't a boolean");
			}
			if (!rightType.IsTypeBoolean())
			{
				reportError(log.Right, "Conditional expression isn't a boolean");
			}

			return .Basic(.FromKind(.UntypedBool));

		case .Unary(let un):
			let op = un.Operator;
			var rightType = checkExpr(un.Right, _scope);
			un.StoredType = rightType;

			switch (op.Kind)
			{ 
			case .Ampersand:
				return ZenType.Pointer(&un.StoredType);
			case .Star:
				if (!rightType.IsTypePointer())
				{
					reportError(op, "Cannot de-reference a non-pointer type");
				}
				return rightType;
			case .Bang:
				if (!rightType.IsTypeBoolean())
				{
					reportError(op, "Conditional expression isn't a boolean");
				}
				// Actually reversing it is the compiler and/or interpreter's job.
				return rightType;
			case .Minus:
				if (!rightType.IsTypeNumeric())
				{
					reportError(op, "Expression doesn't evaluate to a numeric value");
				}
				return rightType;

			default:
				Runtime.Assert(false);
			}

		case .Grouping(let group):
			return checkExpr(group.Expression, _scope);

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
						return val;
					}
				}
			}

			return ZenType.Invalid;

		case .NamedType(let type):
			switch (type.Kind)
			{
			case .Simple(let name):
				let res = BasicType.FromName(name.Lexeme);
				if (res case .Ok(let val))
					return .Basic(val);

				mixin lookupScope(Scope _scope, Token name)
				{
					let tres = lookupScopeForIdentifier(_scope, name);
					if (tres case .Ok(let found))
					{
						if (let typename = found as Entity.TypeName)
						{
							Runtime.Assert(typename.Decl is AstNode.Stmt.StructDeclaration);
							return typename.Type;
						}
					}
				}

				lookupScope!(_scope, name);

				break;

			case .Qualified(let qualified):
				return checkExpr(qualified, _scope);

			case .Pointer(let innerType):
				var a = checkExpr(innerType, _scope);
				return ZenType.Pointer(&a);

			case .Array(let innerType, let countExpr):
				return checkExpr(innerType, _scope);
			}

		case .Cast(let cast):
			// @TODO
			// This switch statement should really be separated into separate functions just for sanity purposes
			// It just goes to the named type procedure.... whatever.
			let castType = checkExpr(cast.TargetType, _scope);

			// Remember to check the actual cast value
			checkExpr(cast.Value, _scope);

			// @TODO
			// We should actually validate that this cast is valid, but I'm lazy
			// so for now, we'll assume you can cast anything into anything (even if it's nonsensical)
			return castType;

		case .Index(let index):
			let arrayType = checkExpr(index.Array, _scope);
			let indexType = checkExpr(index.Index, _scope);

			// @TODO - pelly, 11/3/25
			// Check if we're trying to get a negative index, that obviously makes no sense...
			// Also if we're indexing above the count, that's out of bounds

			if (!indexType.IsTypeInteger())
				reportError(index, "Array index must be an integer type");

			if (arrayType case .Array(let arrayE, let count))
				return *arrayE;

			if (arrayType case .Pointer(let pointerE))
				return *pointerE;

			reportError(index.Array, "Cannot index into a non-array type");
			return ZenType.Invalid;

		case .CompositeLiteral(let composite):
			if (expectedTypeQ == null)
			{
				// @TODO
				// Wrong token
				reportError(composite, "Composite literal is context dependent, so we'll need an expected type!");
				return .Invalid;
			}

			// Debug.Assert(expectedTypeQ != null, "Composite literal is context dependent, so we'll need an expected type!");
			let expectedType = expectedTypeQ.Value;

			if (expectedType case .Structure(let _struct))
			{
				let fields = _struct.Fields;

				if (composite.Elements.Count != fields.Count)
				{
					reportError(composite, scope $"Struct {_struct.Name.Lexeme} expects {fields.Count} fields but got {composite.Elements.Count}");
					return ZenType.Invalid;
				}

				for (let i < fields.Count)
				{
					let fieldType = checkExpr(fields[i].Type, _scope, callScope);
					let elemType = checkExpr(composite.Elements[i], _scope, callScope, fieldType);

					// @TODO
					// Wrong token
					checkTypesComparable(composite.Elements[i], fieldType, elemType);
				}

				composite.ResolvedInferredType = expectedType;
				return expectedType;
			}
			else
			{
				reportError(composite.LBrace, "Composite literal not allowed for this type");
				return ZenType.Invalid;
			}
		}

		Runtime.FatalError("Uh oh! How did you get here?");
	}

	private bool checkTypesComparable(ZenType x, ZenType y)
	{
		// @HACK
		if (!ZenType.AreTypesIdenticalUntyped(x, y))
		{
			if (x case .Pointer && y case .Basic(let basic))
			{
				// This allows pointers to be assigned as NULL, not valid for other types I assume.
				if (basic.Kind == .UntypedNull)
					return true;
			}

			return false;
		}

		return true;
	}

	private void checkTypesComparable(Token token, ZenType x, ZenType y)
	{
		if (!checkTypesComparable(x, y))
		{
			// @FIX
			// Bad error message
			reportError(token, scope $"Types mismatch ({x.GetName(.. scope .())}) to ({y.GetName(.. scope .())})");
		}
	}

	private void checkTypesComparable(AstNode.Expression expr, ZenType x, ZenType y)
	{
		if (!checkTypesComparable(x, y))
		{
			// @FIX
			// Bad error message
			reportError(expr, scope $"Types mismatch ({x.GetName(.. scope .())}) to ({y.GetName(.. scope .())})");
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
}