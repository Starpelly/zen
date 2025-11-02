using System;
using System.Collections;

namespace Zen;

public interface IEntityDeclaration
{
	public AstNode.Stmt Decl { get; }
}

public interface IEntityNamespaceParent
{
	public readonly Entity.Namespace NamespaceParent { get; }
}

enum EntityKind
{
	case Constant(Entity.Constant);
	case Variable(Entity.Variable);
	case TypeName(Entity.TypeName);
	case Function(Entity.Function);
	case Builtin(Entity.Builtin);
	case Namespace(Entity.Namespace);
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

	public abstract EntityKind GetKind();

	public class Constant : Entity, IEntityDeclaration
	{
		public enum ConstantDecl
		{
			case Untyped;
			case Basic(AstNode.Stmt.ConstantDeclaration decl);
			case EnumField(AstNode.Stmt.EnumFieldValue field);
		}

		public readonly ConstantDecl Node;
		public readonly Variant Value ~ _.Dispose();

		public this(ConstantDecl node, Variant value, Token token, ZenType type) : base(token, type)
		{
			this.Node = node;
			this.Value = Value;
		}

		public AstNode.Stmt IEntityDeclaration.Decl
		{
			get
			{
				switch (Node)
				{
				case .Untyped: return null;
				case .Basic(let decl): return decl;
				case .EnumField(let decl): return decl;
				}
			}
		}
		public override EntityKind GetKind() => .Constant(this);
	}

	public class Variable : Entity, IEntityDeclaration
	{
		public readonly AstNode.Stmt.VariableDeclaration Decl;
		public Entity ResolvedTypeEntity;

		public this(AstNode.Stmt.VariableDeclaration decl, Token token, ZenType type) : base(token, type)
		{
			this.Decl = decl;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
		public override EntityKind GetKind() => .Variable(this);
	}

	public class TypeName : Entity, IEntityDeclaration, IEntityNamespaceParent
	{
		public readonly AstNode.Stmt Decl;
		public readonly Namespace NamespaceParent;

		public this(AstNode.Stmt decl, Namespace namespaceParent, Token token, ZenType type) : base(token, type)
		{
			this.Decl = decl;
			this.NamespaceParent = namespaceParent;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
		public Namespace IEntityNamespaceParent.NamespaceParent => NamespaceParent;
		public override EntityKind GetKind() => .TypeName(this);
	}

	public class Function : Entity, IEntityDeclaration, IEntityNamespaceParent
	{
		public readonly AstNode.Stmt.FunctionDeclaration Decl;
		public readonly Namespace NamespaceParent;

		public this(AstNode.Stmt.FunctionDeclaration decl, Namespace namespaceParent, Token token, ZenType type) : base(token, type)
		{
			this.Decl = decl;
			this.NamespaceParent = namespaceParent;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
		public Namespace IEntityNamespaceParent.NamespaceParent => NamespaceParent;
		public override EntityKind GetKind() => .Function(this);
	}

	public class Builtin : Entity
	{
		public readonly StringView Name;

		public this(StringView name, Token token, ZenType type) : base(token, type)
		{
			this.Name = name;
		}

		public override EntityKind GetKind() => .Builtin(this);
	}

	public class Namespace : Entity, IEntityDeclaration
	{
		public readonly AstNode.Stmt.NamespaceDeclaration Decl;

		public this(AstNode.Stmt.NamespaceDeclaration decl, Token token, ZenType type) : base(token, type)
		{
			this.Decl = decl;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
		public override EntityKind GetKind() => .Namespace(this);
	}
}