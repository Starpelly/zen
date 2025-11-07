using System;
using System.Collections;
using System.Diagnostics;

namespace Zen;

/// This pass is responsible for resolving types on entities.
/// For example, Entity.Variables will get the type of the object they're storing resolved here,
/// so we don't have to look up the tree for it again.
class Resolver : Visitor
{
	private readonly List<AstNode.Stmt> m_ast;
	private readonly Scope m_globalScope;

	public this(List<AstNode.Stmt> ast, Scope globalScope)
	{
		this.m_ast = ast;
		this.m_globalScope = globalScope;
	}

	public void Run()
	{
		resolveStatementList(m_ast, m_globalScope);
	}

	private void resolveStatementList(List<AstNode.Stmt> ast, Scope _scope)
	{
		for (let stmt in ast)
		{
			resolveStatement(stmt, _scope);
		}
	}

	private void resolveStatement(AstNode.Stmt stmt, Scope _scope)
	{
		switch (stmt.GetKind())
		{
		case .Block(let block):
			resolveStatementList(block.List, block.Scope ?? _scope);
			return;
		case .NamespaceDecl(let ns):
			resolveStatementList(ns.Ast, ns.Scope);
			return;
		case .StructDecl(let _struct):
			for (let field in _struct.Fields)
			{
				resolveStatement(field, _struct.Scope);
			}
			return;
		case .EnumDecl(let _enum):
			for (let value in _enum.Values)
			{
				resolveStatement(value, _enum.Scope);
			}
			return;
		case .EnumField(let field):
			Console.ForegroundColor = .Yellow;
			Console.WriteLine("please type check me!");
			Console.ResetColor();
			return;
			
		case .If(let _if):
			resolveStatementList(_if.ThenBranch.List, _if.ThenBranch.Scope);
			if (_if.ElseBranch case .Ok(let _else))
			{
				resolveStatementList(_else.List, _else.Scope);
			}
			return;
		case .While(let _while):
			resolveStatement(_while.Body, _while.Scope);
			return;
		case .For(let _for):
			resolveStatement(_for.Initialization, _for.Scope);
			resolveStatement(_for.Body, _for.Scope);
			return;
		case .FunctionDecl(let fun):
			resolveFunction(fun, _scope);

			for (let param in fun.Parameters)
			{
				resolveStatement(param, fun.Scope);
			}

			if (fun.Kind == .Extern)
				return;
			resolveStatementList(fun.Body.List, fun.Scope);
			return;
		case .VarDecl(let _var):
			resolveVariable(_var, _scope);
			return;
		case .ConstDecl(let _const):
			resolveConstant(_const, _scope);
			return;

		case
			 .Expression,
			 .EOF,
			 .Return
			 :
			return;

		default:
			Runtime.FatalError("You didn't handle a statement case!");
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


	// @TODO @FIX @REFACTOR
	// This could be one function lol
	private void resolveVariable(AstNode.Stmt.VariableDeclaration varDecl, Scope _scope)
	{
		let entity = _scope.LookupName(varDecl.Name.Lexeme).Value as Entity.Variable;

		if (entity.Type case .Pointer(let inner))
		{
			entity.ResolvedType = .Pointer(resolveInnerType(*inner, _scope).1);
		}
		else if (entity.Type case .Array(let element, let count))
		{
			entity.ResolvedType = .Array(resolveInnerType(*element, _scope).1, count);
			// Debug.Assert(false);
		}
		else
		{
			entity.ResolvedType = resolveInnerType(entity.Type, _scope).0;
		}
	}

	private void resolveConstant(AstNode.Stmt.ConstantDeclaration constDecl, Scope _scope)
	{
		let entity = _scope.LookupName(constDecl.Name.Lexeme).Value as Entity.Constant;

		if (entity.Type case .Pointer(let inner))
		{
			entity.ResolvedType = .Pointer(resolveInnerType(*inner, _scope).1);
		}
		else if (entity.Type case .Array(let element, let count))
		{
			entity.ResolvedType = .Array(resolveInnerType(*element, _scope).1, count);
			// Debug.Assert(false);
		}
		else
		{
			entity.ResolvedType = resolveInnerType(entity.Type, _scope).0;
		}
	}

	private void resolveFunction(AstNode.Stmt.FunctionDeclaration funcDecl, Scope _scope)
	{
		let entity = _scope.LookupName(funcDecl.Name.Lexeme).Value as Entity.Function;

		if (entity.Type case .Pointer(let inner))
		{
			entity.ResolvedType = .Pointer(resolveInnerType(*inner, _scope).1);
		}
		else if (entity.Type case .Array(let element, let count))
		{
			entity.ResolvedType = .Array(resolveInnerType(*element, _scope).1, count);
			// Debug.Assert(false);
		}
		else
		{
			entity.ResolvedType = resolveInnerType(entity.Type, _scope).0;
		}
	}

	(ZenType, ZenType*) resolveInnerType(ZenType type, Scope _scope)
	{
		Runtime.Assert(type != .Invalid);

		if (type case .SimpleNamed(let simpleName))
		{
			let lookup = lookupScopeForIdentifier(_scope, simpleName);
			if (lookup case .Ok(let res))
			{
				/*
				if (isPointer)
					return .Pointer(res.TypePtr);
				if (isArray)
					return .Array(res.TypePtr, arrayCount);
				*/
				return (res.Type, res.TypePtr);
			}
			else
			{
				return (.Invalid, null);
			}
		}
		else if (type case .QualifiedNamed(let qualifiedName))
		{
			let leftScope = lookupScopeForIdentifier(_scope, qualifiedName.Left);

			if (leftScope case .Ok(let leftEntity))
			{
				if (let decl = leftEntity as IEntityDeclaration)
				{
					if (let iScope = decl.Decl as AstNode.Stmt.IScope)
					{
						Runtime.Assert(qualifiedName.Right is AstNode.Expression.Variable);
						let _var = qualifiedName.Right as AstNode.Expression.Variable;
						let lookup = lookupScopeForIdentifier(iScope.Scope, _var.Name);
						if (lookup case .Ok(var res))
						{
							/*
							if (isPointer)
								return .Pointer(res.TypePtr);
							if (isArray)
								return .Array(res.TypePtr, arrayCount);
							*/
							return (res.Type, res.TypePtr);
						}

						// let lookup = lookupScopeForIdentifier(iScope.Scope, qualifiedName.r)
						// let val = checkExpr(qualifiedName.Right, iScope.Scope, _scope);
						// returnVal!(val);
					}
				}
			}
			// checkExpr(qualifiedName, _scope);

			return (.Invalid, null);
		}
		else if (type case .Basic)
		{
#pragma warning disable 4204
			return (type, &type);
		}

		Runtime.FatalError(scope $"What are you?");
	}
}