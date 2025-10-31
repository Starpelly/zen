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

enum AstNodeKind
{
	case Invalid;

	case Expression;
	case Variable;
	case Function;
	case Return;
	case Print;
	case While;
	case If;
}

enum ExpressionKind
{
	case Binary;
	case Variable;
	case Call;
	case Logical;
	case Literal;
	case Unary;
	case Get;
	case Set;
	case This;
	case Grouping;
	case Assign;
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

		public class Return : Stmt
		{
			public readonly Token Token;
			public readonly Expression Value ~ delete _;

			public this(Token token, Expression value)
			{
				this.Token = token;
				this.Value = value;
			}
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
			public readonly Token Type;
			public readonly Block Body ~ delete _;
			public List<AstNode.Stmt.VariableDeclaration> Parameters ~ DeleteContainerAndItems!(_);

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(FunctionKind kind, Token name, Token type, Block body, List<AstNode.Stmt.VariableDeclaration> parameters)
			{
				this.Kind = kind;
				this.Name = name;
				this.Type = type;
				this.Body = body;
				this.Parameters = parameters;
			}
		}

		public class StructDeclaration : Stmt, IScope
		{
			public readonly Token Name;
			public readonly List<VariableDeclaration> Fields ~ DeleteContainerAndItems!(_);

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(Token name, List<VariableDeclaration> fields)
			{
				this.Name = name;
				this.Fields = fields;
			}
		}

		public class If : Stmt, IScope
		{
			public readonly Expression Condition ~ delete _;
			public readonly AstNode.Stmt ThenBranch ~ delete _;
			public readonly Result<AstNode.Stmt> ElseBranch ~ if (ElseBranch case .Ok) delete _.Value;

			public Scope Scope { get => m_scope; set => m_scope = value; }
			private Scope m_scope;

			public this(Expression condition, AstNode.Stmt thenBranch, AstNode.Stmt elseBranch)
			{
				this.Condition = condition;
				this.ThenBranch = thenBranch;
				if (elseBranch != null)
					this.ElseBranch = .Ok(elseBranch);
			}
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
		}

		public class VariableDeclaration : Stmt
		{
			public readonly DeclarationKind Kind;
			public readonly Token Name;
			public readonly Token Type;
			public readonly Expression Initializer ~ if (_ != null) delete _;
			
			public this(DeclarationKind kind, Token name, Token type, Expression init)
			{
				this.Kind = kind;
				this.Name = name;
				this.Type = type;
				this.Initializer = init;
			}
		}

		public class ConstantDeclaration : Stmt
		{
			public readonly Token Name;
			public readonly Token Type;
			public readonly Expression Initializer ~ delete _;

			public this(Token name, Token type, Expression init)
			{
				this.Name = name;
				this.Type = type;
				this.Initializer = init;
			}
		}

		public class ExpressionStmt : Stmt
		{
			public readonly Expression InnerExpr ~ delete _;

			public this(Expression expr)
			{
				this.InnerExpr = expr;
			}
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
		}
	}

	/// Expression nodes.
	public abstract class Expression : AstNode
	{
		public ZenType Type;

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
		}

		public class Variable : Expression
		{
			public readonly Token Name;

			public this(Token name)
			{
				this.Name = name;
			}
		}

		public class Call : Expression
		{
			public readonly Expression.Variable Callee ~ delete _;
			public readonly List<Expression> Arguments ~ DeleteContainerAndItems!(_);

			public this(Expression.Variable callee, List<Expression> arguments)
			{
				this.Callee = callee;
				this.Arguments = arguments;
			}
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
		}

		public class Literal : Expression
		{
			//public readonly DataType Type ~ delete _;
			public readonly Token Token;
			public readonly Variant? Variant ~ if (HasValue) _.Value.Dispose();

			public readonly Variant Value => Variant.Value;
			public readonly bool HasValue => Variant.HasValue;

			public this(/*DataType type, */Token token, Variant? value)
			{
				//this.Type = type;
				this.Token = token;
				this.Variant = value;
			}
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
		}

		public class Get : Expression
		{
			public readonly Expression Object ~ delete _;
			public readonly Token Name;

			public this(Expression object, Token name)
			{
				this.Object = object;
				this.Name = name;
			}
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
		}

		public class This : Expression
		{
			public readonly Token Keyword;

			public this(Token keyword)
			{
				this.Keyword = keyword;
			}
		}

		public class Grouping : Expression
		{
			public readonly Expression Expression ~ delete _;

			public this(Expression expression)
			{
				this.Expression = expression;
			}
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
		}
	}
}

/// Expressions aren't stored by themselves, unless they use an ExpressionStmt node.
public typealias Ast = List<AstNode.Stmt>;