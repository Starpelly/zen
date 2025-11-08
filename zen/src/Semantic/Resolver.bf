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

	public Result<void> Run()
	{
		resolveStatementList(m_ast, m_globalScope);
		return HadErrors ? .Err : .Ok;
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
			/*
			Console.ForegroundColor = .Yellow;
			Console.WriteLine("please type check me!");
			Console.ResetColor();
			*/
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
		entity.ResolvedType = resolveEntity(entity.Type, _scope);
	}

	private void resolveConstant(AstNode.Stmt.ConstantDeclaration constDecl, Scope _scope)
	{
		let entity = _scope.LookupName(constDecl.Name.Lexeme).Value as Entity.Constant;
		entity.ResolvedType = resolveEntity(entity.Type, _scope);
	}

	private void resolveFunction(AstNode.Stmt.FunctionDeclaration funcDecl, Scope _scope)
	{
		let entity = _scope.LookupName(funcDecl.Name.Lexeme).Value as Entity.Function;
		entity.ResolvedType = resolveEntity(entity.Type, _scope);
	}

	private ZenType resolveEntity(ZenType entityType, Scope _scope)
	{
		// We can't do anything if it's a type invalid. This should NEVER be the case unless the Binder didn't do its job!
		// But of course, better safe than sorry. That's what asserts are for.
		Runtime.Assert(entityType != .Invalid);

		// We'll create a copy of the entity type as that's the base we're working with (and also we don't want to modify the base type we have, we want to return a new value).
		ZenType resolvedType = entityType;
		resolveType(ref resolvedType, _scope); 

		/// Should never be the case, but again, better safe than sorry.
		// Debug.Assert(resolvedType != .Invalid);

		return resolvedType;
	}

	/// Takes a type and swaps the "BasicNamed" and "QualifiedNamed" for symbol types.
	/// So for example, if there's a struct named "Foo", and the type is a kind ".SimpleNamed", it will swap it from SimpleNamed to the struct called that if it finds it.
	/// This also works with pointers. Note that this manipulates a ZenType already in memory!
	private void resolveType(ref ZenType unresolvedType, Scope _scope)
	{
		if (unresolvedType case .Basic)
		{
			// Basic types are defined globally, so we don't need to do anything here.
		}
		else if (unresolvedType case .SimpleNamed(let simpleName))
		{
			let lookup = lookupScopeForIdentifier(_scope, simpleName);
			if (lookup case .Ok(let res))
			{
				unresolvedType = res.Type;
				return;
			}
			unresolvedType = .Invalid;
		}
		else if (unresolvedType case .QualifiedNamed(let qualifiedName))
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
							unresolvedType = res.Type;
							return;
						}
					}
				}
			}

			unresolvedType = .Invalid;
		}
		else if (unresolvedType case .Pointer(var ptr))
		{
			// Here we're swapping the pointer of the element from whatever we had before to the new resolved type.
			// So this could be a pointer again or an array or an actual resolved type (handled in cases .SimpleNamed and .QualifiedNamed.
			resolveType(ref *ptr.Element, _scope);
		}
		else if (unresolvedType case .Array(var arr))
		{
			resolveType(ref *arr.Element, _scope);
		}
		else
		{
			Runtime.FatalError(scope $"What are you?!!!");
		}
	}
}