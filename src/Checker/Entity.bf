using System;
using System.Collections;

namespace Zen;

public interface IEntityDeclaration
{
	public AstNode.Stmt Decl { get; }
}

/// An entity is a named "thing" in the language.
abstract class Entity
{
	public readonly Token Token;
	public readonly ZenType Type;

	public this(Token token, ZenType type)
	{
		this.Token = token;
		Type = type;
	}

	public class Constant : Entity, IEntityDeclaration
	{
		public readonly AstNode.Stmt Decl;
		public readonly Variant Value ~ _.Dispose();

		public this(AstNode.Stmt decl, Variant value, Token token, ZenType type) : base(token, type)
		{
			this.Decl = decl;
			this.Value = Value;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
	}

	public class Variable : Entity, IEntityDeclaration
	{
		public readonly AstNode.Stmt.VariableDeclaration Decl;

		public this(AstNode.Stmt.VariableDeclaration decl, Token token, ZenType type) : base(token, type)
		{
			this.Decl = decl;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
	}

	public class TypeName : Entity, IEntityDeclaration
	{
		public readonly AstNode.Stmt Decl;

		public this(AstNode.Stmt decl, Token token, ZenType type) : base(token, type)
		{
			this.Decl = decl;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
	}

	public class Function : Entity, IEntityDeclaration
	{
		public readonly AstNode.Stmt.FunctionDeclaration Decl;

		public this(AstNode.Stmt.FunctionDeclaration decl, Token token, ZenType type) : base(token, type)
		{
			this.Decl = decl;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
	}

	public class Builtin : Entity
	{
		public readonly StringView Name;

		public this(StringView name, Token token, ZenType type) : base(token, type)
		{
			this.Name = name;
		}
	}
}