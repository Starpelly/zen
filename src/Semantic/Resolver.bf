using System;
using System.Collections;
using System.Diagnostics;

namespace Zen;

/// This pass is responsible for resolving types on entities.
/// For example, Entity.Variables will get the type of the object they're storing resolved here,
/// so we don't have to look up the tree for it again.
class Resolver
{
	private readonly List<AstNode.Stmt> m_ast;
	private readonly List<CompilerError> m_errors;
	private readonly Scope m_globalScope;

	public this(List<AstNode.Stmt> ast, Scope globalScope, List<CompilerError> errs)
	{
		this.m_ast = ast;
		this.m_globalScope = globalScope;
		this.m_errors = errs;
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
		if (let block = stmt as AstNode.Stmt.Block)
		{
			resolveStatementList(block.List, block.Scope ?? _scope);
		}

		if (let ns = stmt as AstNode.Stmt.NamespaceDeclaration)
		{
			resolveStatementList(ns.Ast, ns.Scope);
		}

		if (let _struct = stmt as AstNode.Stmt.StructDeclaration)
		{
			for (let field in _struct.Fields)
			{
				resolveStatement(field, _struct.Scope);
			}
		}

		if (let _if = stmt as AstNode.Stmt.If)
		{
			resolveStatementList(_if.ThenBranch.List, _if.ThenBranch.Scope);
			if (_if.ElseBranch case .Ok(let _else))
			{
				resolveStatementList(_else.List, _else.Scope);
			}
		}

		if (let fun = stmt as AstNode.Stmt.FunctionDeclaration)
		{
			if (fun.Kind == .Extern)
				return;

			for (let param in fun.Parameters)
			{
				resolveStatement(param, fun.Scope);
			}
			resolveStatementList(fun.Body.List, fun.Scope);
		}

		if (let _var = stmt as AstNode.Stmt.VariableDeclaration)
		{
			if (_var.Name.Lexeme == "sin")
			{
				var a = 0;
			}

			resolveVariable(_var, _scope);
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

	private void reportError(Token token, String message)
	{
		m_errors.Add(new .(token, message));
	}

	private void resolveVariable(AstNode.Stmt.VariableDeclaration varDecl, Scope _scope)
	{
		let entity = _scope.LookupName(varDecl.Name.Lexeme).Value as Entity.Variable;
		if (entity.Type case .SimpleNamed(let simpleName))
		{
			let lookup = lookupScopeForIdentifier(_scope, simpleName);
			if (lookup case .Ok(let res))
			{
				entity.ResolvedType = res.Type;
			}
		}
		else if (entity.Type case .QualifiedNamed(let qualifiedName))
		{
			let leftScope = _scope.LookupName(qualifiedName.Left.Lexeme);

			if (leftScope case .Ok(let leftEntity))
			{
				if (let decl = leftEntity as IEntityDeclaration)
				{
					if (let iScope = decl.Decl as AstNode.Stmt.IScope)
					{
						Runtime.Assert(qualifiedName.Right is AstNode.Expression.Variable);
						let _var = qualifiedName.Right as AstNode.Expression.Variable;
						let lookup = lookupScopeForIdentifier(iScope.Scope, _var.Name);
						if (lookup case .Ok(let res))
						{
							entity.ResolvedType = res.Type;
						}

						// let lookup = lookupScopeForIdentifier(iScope.Scope, qualifiedName.r)
						// let val = checkExpr(qualifiedName.Right, iScope.Scope, _scope);
						// returnVal!(val);
					}
				}
			}
			// checkExpr(qualifiedName, _scope);
		}
		else if (entity.Type case .Basic)
		{
			entity.ResolvedType = entity.Type;
		}
		else
		{
			Runtime.FatalError("What are you?");
		}
	}
}