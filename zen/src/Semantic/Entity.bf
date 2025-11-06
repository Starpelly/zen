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
	public readonly Scope Scope;
	public readonly Token Token;
	public readonly ZenType Type => m_type;
	public ZenType* TypePtr => &m_type;

	private ZenType m_type;

	public this(Scope _scope, Token token, ZenType type)
	{
		this.Scope = _scope;
		this.Token = token;
		this.m_type = type;
	}

	public abstract EntityKind GetKind();

	public class Constant : Entity, IEntityDeclaration, IEntityNamespaceParent
	{
		public enum ConstantDecl
		{
			case Builtin;
			case Normal(AstNode.Stmt.ConstantDeclaration decl);
			case EnumField(AstNode.Stmt.EnumFieldValue field);
		}

		public readonly ConstantDecl Decl;
		public readonly Variant Value ~ _.Dispose();
		public readonly Namespace NamespaceParent;

		/// The type the variable is holding, not to be confused with Variable.Type
		public ZenType ResolvedType;

		public this(Scope _scope, ConstantDecl node, Namespace namespaceParent, Variant value, Token token, ZenType type) : base(_scope, token, type)
		{
			this.Decl = node;
			this.Value = Value;
			this.NamespaceParent = namespaceParent;
		}

		public AstNode.Stmt IEntityDeclaration.Decl
		{
			get
			{
				switch (Decl)
				{
				case .Builtin: return null;
				case .Normal(let decl): return decl;
				case .EnumField(let decl): return decl;
				}
			}
		}

		public Namespace IEntityNamespaceParent.NamespaceParent => NamespaceParent;
		public override EntityKind GetKind() => .Constant(this);
	}

	public class Variable : Entity, IEntityDeclaration, IEntityNamespaceParent
	{
		public readonly AstNode.Stmt.VariableDeclaration Decl;
		public readonly Namespace NamespaceParent;

		/// The type the variable is holding, not to be confused with Variable.Type
		public ZenType ResolvedType;

		public this(Scope _scope, AstNode.Stmt.VariableDeclaration decl, Namespace namespaceParent, Token token, ZenType type) : base(_scope, token, type)
		{
			this.Decl = decl;
			this.NamespaceParent = namespaceParent;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
		public Namespace IEntityNamespaceParent.NamespaceParent => NamespaceParent;
		public override EntityKind GetKind() => .Variable(this);
	}

	public class TypeName : Entity, IEntityDeclaration, IEntityNamespaceParent
	{
		public readonly AstNode.Stmt Decl;
		public readonly Namespace NamespaceParent;

		public this(Scope _scope, AstNode.Stmt decl, Namespace namespaceParent, Token token, ZenType type) : base(_scope, token, type)
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

		/// The type the function returns, not to be confused with Function.Type
		public ZenType ResolvedType;

		public this(Scope _scope, AstNode.Stmt.FunctionDeclaration decl, Namespace namespaceParent, Token token, ZenType type) : base(_scope, token, type)
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

		public this(Scope _scope, StringView name, Token token, ZenType type) : base(_scope, token, type)
		{
			this.Name = name;
		}

		public override EntityKind GetKind() => .Builtin(this);
	}

	public class Namespace : Entity, IEntityDeclaration
	{
		public readonly AstNode.Stmt.NamespaceDeclaration Decl;

		public this(Scope _scope, AstNode.Stmt.NamespaceDeclaration decl, Token token, ZenType type) : base(_scope, token, type)
		{
			this.Decl = decl;
		}

		public AstNode.Stmt IEntityDeclaration.Decl => Decl;
		public override EntityKind GetKind() => .Namespace(this);
	}
}