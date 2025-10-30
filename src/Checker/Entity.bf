using System;
using System.Collections;

namespace Zen;

public enum EntityKind
{
	Invalid,
	Constant,
	Variable,
	TypeName,
	Function,
	Builtin
}

/// An entity is a named "thing" in the language.
abstract class Entity
{
	public Token Token;
	public ZenType Type;

	public class Function : Entity
	{
		public AstNode.Stmt.FunctionDeclaration Decl;
	}

	public class Variable : Entity
	{
		public AstNode.Stmt.VariableDeclaration Decl;
	}

	public class Constant : Entity
	{
		public AstNode.Stmt.ConstantDeclaration Decl;
		public Variant Value ~ _.Dispose();
	}

	public class Builtin : Entity
	{
		public StringView Name;
	}
}