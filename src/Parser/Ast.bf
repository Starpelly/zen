using System;
using System.Collections;

namespace Zen;

enum DeclarationKind
{
	Invalid,
	Mutable,
	Immutable,
	Count
}

enum StmtKind
{
	case Return(AstNode.Stmt.Return);
	case Block(AstNode.Stmt.Block);
	case EOF(AstNode.Stmt.EOF);
	case FunctionDecl(AstNode.Stmt.FunctionDeclaration);
	case StructDecl(AstNode.Stmt.StructDeclaration);
	case EnumDecl(AstNode.Stmt.EnumDeclaration);
	case EnumField(AstNode.Stmt.EnumFieldValue);
	case VarDecl(AstNode.Stmt.VariableDeclaration);
	case ConstDecl(AstNode.Stmt.ConstantDeclaration);
	case NamespaceDecl(AstNode.Stmt.NamespaceDeclaration);
	case If(AstNode.Stmt.If);
	case For(AstNode.Stmt.For);
	case While(AstNode.Stmt.While);
	case Expression(AstNode.Stmt.ExpressionStmt);
	case BasicDirective(AstNode.Stmt.BasicDirective);
}

enum ExpressionKind
{
	case Binary(AstNode.Expression.Binary);
	case Variable(AstNode.Expression.Variable);
	case Call(AstNode.Expression.Call);
	case Logical(AstNode.Expression.Logical);
	case Literal(AstNode.Expression.Literal);
	case Unary(AstNode.Expression.Unary);
	case Get(AstNode.Expression.Get);
	case Set(AstNode.Expression.Set);
	case This(AstNode.Expression.This);
	case Grouping(AstNode.Expression.Grouping);
	case Assign(AstNode.Expression.Assign);
	case QualifiedName(AstNode.Expression.QualifiedName);
	case NamedType(AstNode.Expression.NamedType);
	case Cast(AstNode.Expression.Cast);
	case Index(AstNode.Expression.Index);
}

abstract class AstNode
{
	/// Statement nodes.
	public abstract class Stmt : AstNode
	{
		public interface IScope
		{
			public Scope Scope { get; set; }
		}

		public abstract StmtKind GetKind();

		public class Return : Stmt
		{
			public readonly Token Token;
			public readonly Expression Value ~ delete _;

			public this(Token token, Expression value)
			{
				this.Token = token;
				this.Value = value;
			}

			public override StmtKind GetKind() => .Return(this);
		}

		public class Block : Stmt, IScope
		{
			public readonly List<AstNode.Stmt> List ~ DeleteContainerAndItems!(_);
			public readonly Token Open, Close;

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(List<AstNode.Stmt> list, Token open, Token close)
			{
				this.List = list;
				this.Open = open;
				this.Close = close;
			}

			public override StmtKind GetKind() => .Block(this);
		}

		public class EOF : Stmt
		{
			public override StmtKind GetKind() => .EOF(this);
		}

		public class FunctionDeclaration : Stmt, IScope
		{
			public enum FunctionKind
			{
				Normal,
				Extern
			}

			public readonly FunctionKind Kind;
			public readonly Token Name;
			public readonly Expression.NamedType Type ~ delete _;
			public readonly Block Body ~ delete _;
			public List<AstNode.Stmt.VariableDeclaration> Parameters ~ DeleteContainerAndItems!(_);

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(FunctionKind kind, Token name, Expression.NamedType type, Block body, List<AstNode.Stmt.VariableDeclaration> parameters)
			{
				this.Kind = kind;
				this.Name = name;
				this.Type = type;
				this.Body = body;
				this.Parameters = parameters;
			}

			public override StmtKind GetKind() => .FunctionDecl(this);
		}

		public class StructDeclaration : Stmt, IScope
		{
			public enum StructKind
			{
				Normal,
				Extern
			}

			public readonly StructKind Kind;
			public readonly Token Name;
			public readonly List<VariableDeclaration> Fields ~ DeleteContainerAndItems!(_);

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(StructKind kind, Token name, List<VariableDeclaration> fields)
			{
				this.Kind = kind;
				this.Name = name;
				this.Fields = fields;
			}

			public override StmtKind GetKind() => .StructDecl(this);
		}

		public class EnumDeclaration : Stmt, IScope
		{
			public enum EnumKind
			{
				Normal,
				Extern
			}

			public readonly EnumKind Kind;
			public readonly Token Name;
			public readonly List<EnumFieldValue> Values ~ DeleteContainerAndItems!(_);

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(EnumKind kind, Token name, List<EnumFieldValue> values)
			{
				this.Kind = kind;
				this.Name = name;
				this.Values = values;
			}

			public override StmtKind GetKind() => .EnumDecl(this);
		}

		public class EnumFieldValue : Stmt
		{
			public readonly Token Name;
			public readonly Expression Value ~ delete _;

			public this(Token name, Expression value)
			{
				this.Name = name;
				this.Value = value;
			}

			public override StmtKind GetKind() => .EnumField(this);
		}

		public class VariableDeclaration : Stmt
		{
			public readonly DeclarationKind Kind;
			public readonly Token Name;
			public readonly Expression.NamedType Type ~ delete _;
			public readonly Token? Operator;
			public readonly Expression Initializer ~ if (_ != null) delete _;

			public this(DeclarationKind kind, Token name, Expression.NamedType type, Token? op, Expression init)
			{
				this.Kind = kind;
				this.Name = name;
				this.Type = type;
				this.Operator = op;
				this.Initializer = init;
			}

			public override StmtKind GetKind() => .VarDecl(this);
		}

		public class ConstantDeclaration : Stmt
		{
			public readonly Token Name;
			public readonly Expression.NamedType Type ~ delete _;
			public readonly Expression Initializer ~ delete _;

			public this(Token name, Expression.NamedType type, Expression init)
			{
				this.Name = name;
				this.Type = type;
				this.Initializer = init;
			}

			public override StmtKind GetKind() => .ConstDecl(this);
		}

		public class NamespaceDeclaration : Stmt, IScope
		{
			public readonly Token Name;
			public readonly Token Token;
			public readonly List<AstNode.Stmt> Ast ~ DeleteContainerAndItems!(_);

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(Token name, Token token, List<AstNode.Stmt> ast)
			{
				this.Name = name;
				this.Token = token;
				this.Ast = ast;
			}

			public override StmtKind GetKind() => .NamespaceDecl(this);
		}

		public class If : Stmt
		{
			public readonly Expression Condition ~ delete _;
			public readonly Block ThenBranch ~ delete _;
			public readonly Result<Block> ElseBranch = .Err ~ if (ElseBranch case .Ok) delete _.Value;

			public this(Expression condition, Block thenBranch, Block elseBranch)
			{
				this.Condition = condition;
				this.ThenBranch = thenBranch;
				if (elseBranch != null)
					this.ElseBranch = .Ok(elseBranch);
			}

			public override StmtKind GetKind() => .If(this);
		}

		public class For : Stmt, IScope
		{
			public readonly AstNode.Stmt Initialization ~ delete _;
			public readonly AstNode.Expression Condition ~ delete _;
			public readonly AstNode.Expression Updation ~ delete _;
			public readonly AstNode.Stmt Body ~ delete _;

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(AstNode.Stmt init, AstNode.Expression condition, AstNode.Expression update, AstNode.Stmt body)
			{
				this.Initialization = init;
				this.Condition = condition;
				this.Updation = update;
				this.Body = body;
			}

			public override StmtKind GetKind() => .For(this);
		}

		public class While : Stmt, IScope
		{
			public readonly AstNode.Expression Condition ~ delete _;
			public readonly AstNode.Stmt Body ~ delete _;

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(AstNode.Expression condition, AstNode.Stmt body)
			{
				this.Condition = condition;
				this.Body = body;
			}

			public override StmtKind GetKind() => .While(this);
		}

		public class ExpressionStmt : Stmt
		{
			public readonly Expression InnerExpr ~ delete _;

			public this(Expression expr)
			{
				this.InnerExpr = expr;
			}

			public override StmtKind GetKind() => .Expression(this);
		}

		public class BasicDirective : Stmt
		{
			public readonly Token Token;
			public readonly Token Name;

			public this(Token token, Token name)
			{
				this.Token = token;
				this.Name = name;
			}

			public override StmtKind GetKind() => .BasicDirective(this);
		}
	}

	/// Expression nodes.
	public abstract class Expression : AstNode
	{
		public abstract ExpressionKind GetKind();

		public class Binary : Expression
		{
			public readonly Expression Left ~ delete _;
			public readonly Token Op;
			public readonly Expression Right ~ delete _;
			public readonly bool WasCompounded = false;

			public this(Expression left, Token op, Expression right, bool wasCompounded)
			{
				this.Left = left;
				this.Op = op;
				this.Right = right;
				this.WasCompounded = wasCompounded;
			}

			public override ExpressionKind GetKind() => .Binary(this);
		}

		public class Variable : Expression
		{
			public readonly Token Name;

			public this(Token name)
			{
				this.Name = name;
			}

			public override ExpressionKind GetKind() => .Variable(this);
		}

		public class Call : Expression
		{
			public readonly Expression.Variable Callee ~ delete _;
			public readonly List<Expression> Arguments ~ DeleteContainerAndItems!(_);

			/// Open '(' token
			public readonly Token Open;
			/// Close ')' token
			public readonly Token Close;

			public this(Expression.Variable callee, List<Expression> arguments, Token open, Token close)
			{
				this.Callee = callee;
				this.Arguments = arguments;
				this.Open = open;
				this.Close = close;
			}

			public override ExpressionKind GetKind() => .Call(this);
		}

		public class Logical : Expression
		{
			public readonly Expression Left;
			public readonly Token Op;
			public readonly Expression Right;
			
			public this(Expression left, Token op, Expression right)
			{
				this.Left = left;
				this.Op = op;
				this.Right = right;
			}

			public override ExpressionKind GetKind() => .Logical(this);
		}

		public class Literal : Expression
		{
			public readonly Token Token;
			public readonly Variant? Variant ~ if (HasValue) _.Value.Dispose();

			public readonly Variant Value => Variant.Value;
			public readonly bool HasValue => Variant.HasValue;

			/// Used in the code generator, so it's on the creator to say what this is, so we don't need a big switch statement or whatever.
			public readonly String ValueString = new .() ~ delete _;

			public this(Token token, Variant? value, StringView valueStr)
			{
				this.Token = token;
				this.Variant = value;
				this.ValueString.Append(valueStr);
			}

			public ZenType GetLiteralType()
			{
				BasicKind kind = .Invalid;
				Token basic_lit = Token;

				Runtime.Assert(HasValue);

				switch (Value.VariantType)
				{
				case typeof(int):
					kind = .UntypedInteger; break;
				case typeof(float):
					kind = .UntypedFloat; break;
				case typeof(String), typeof(StringView):
					kind = .UntypedString; break;
				default:
					let a  = 0;
				}

				/*
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
				*/

				return .Basic(BasicType.FromKind(kind));
			}

			public override ExpressionKind GetKind() => .Literal(this);
		}

		public class Unary : Expression
		{
			public readonly Token Operator;
			public readonly Expression Right ~ delete _;

			public this(Token @operator, Expression right)
			{
				this.Operator = @operator;
				this.Right = right;
			}

			public override ExpressionKind GetKind() => .Unary(this);
		}

		public class Get : Expression
		{
			public readonly Expression Object ~ delete _;
			public readonly Token Name;

			// @TEMP @HACK
			// Just to get pointers working for now
			public bool IsPointer;

			public this(Expression object, Token name)
			{
				this.Object = object;
				this.Name = name;
			}

			public override ExpressionKind GetKind() => .Get(this);
		}

		public class Set : Expression
		{
			public readonly Expression Object ~ delete _;
			public readonly Token Name;
			public readonly Expression Value;

			public this(Expression object, Token name, Expression value)
			{
				this.Object = object;
				this.Name = name;
				this.Value = value;
			}

			public override ExpressionKind GetKind() => .Set(this);
		}

		public class This : Expression
		{
			public readonly Token Keyword;

			public this(Token keyword)
			{
				this.Keyword = keyword;
			}

			public override ExpressionKind GetKind() => .This(this);
		}

		public class Grouping : Expression
		{
			public readonly Expression Expression ~ delete _;

			public this(Expression expression)
			{
				this.Expression = expression;
			}

			public override ExpressionKind GetKind() => .Grouping(this);
		}

		public class Assign : Expression
		{
			public readonly Expression Assignee ~ delete _;
			public readonly Expression Value ~ delete _;
			public readonly Token Op;

			public this(Expression assignee, Expression value, Token op)
			{
				this.Assignee = assignee;
				this.Value = value;
				this.Op = op;
			}

			public override ExpressionKind GetKind() => .Assign(this);
		}

		public class QualifiedName : Expression
		{
			public readonly Token Left;
			public readonly Token Separator;
			public readonly Expression Right ~ delete _;

			public this(Token left, Token separator, Expression right)
			{
				this.Left = left;
				this.Separator = separator;
				this.Right = right;
			}

			public override ExpressionKind GetKind() => .QualifiedName(this);
		}

		public class NamedType : Expression
		{
			public enum Kind
			{
				case Simple(Token name);
				case Qualified(QualifiedName name);
				case Pointer(NamedType innerType);
				case Array(NamedType innerType, Literal countExpr);
			}

			public readonly Kind Kind;

			// @FIX @HACK
			/// For pointer and array kinds, we'll store the actual type the binder assigns here so the memory isn't lost.
			/// I want to think there's a better way of doing this, but I'm really tired right now.
			public ZenType StoredType;

			public this(Kind kind)
			{
				this.Kind = kind;
			}

			public ~this()
			{
				if (this.Kind case .Qualified(let q))
				{
					delete q;
				}
				if (this.Kind case .Pointer(let innerP))
				{
					delete innerP;
				}
				if (this.Kind case .Array(let innerArr, let countExpr))
				{
					delete innerArr;
					delete countExpr;
				}
			}

			public override ExpressionKind GetKind() => .NamedType(this);
		}

		public class Cast : Expression
		{
			public readonly Expression Value ~ delete _;
			public readonly NamedType TargetType ~ delete _;
			public readonly Token CastKeyword;

			public this(Expression value, NamedType targetType, Token keyword)
			{
				this.Value = value;
				this.TargetType = targetType;
				this.CastKeyword = keyword;
			}

			public override ExpressionKind GetKind() => .Cast(this);
		}

		public class Index : Expression
		{
			public readonly Expression Array ~ delete _;
			public readonly Expression Index ~ delete _;
			public readonly Token LeftBracket;
			public readonly Token RightBracket;

			public this(Expression array, Expression index, Token left, Token right)
			{
				this.Array = array;
				this.Index = index;
				this.LeftBracket = left;
				this.RightBracket = right;
			}

			public override ExpressionKind GetKind() => .Index(this);
		}
	}
}

/// Expressions aren't stored by themselves, unless they use an ExpressionStmt node.
public typealias Ast = List<AstNode.Stmt>;