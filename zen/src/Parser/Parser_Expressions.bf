using System;
using System.Collections;

namespace Zen;
using static Zen.AstNode;

extension Parser
{
	private AstNode.Stmt.ExpressionStmt getExpressionStmt()
	{
		let expr = getExpression();
		consume(.Semicolon, "Expected ';' after value.");

		return new .(expr);
	}

	private AstNode.Expression getExpression()
	{
		return getExprAssignment();
	}

	private AstNode.Expression getExprAssignment()
	{
		var expr = getExprOr();

		if (match(.Equal, .PlusEqual, .MinusEqual, .StarEqual, .ForwardSlashEqual, .ModulusEqual))
		{
			let equals = previous();
			var value = getExprAssignment();

			/*
			// Syntax sugar compound assignments
			if (equals.Type != .Equal)
			{
				let compoundOp = getCompoundOperator(equals.Type, equals);
				let binary = new Expression.Binary(expr, compoundOp, value, true);
				value = binary;
			}
			*/

			/*
			if (let varExpr = expr as Expression.Variable)
			{
				expr = new Expression.Assign(varExpr, value, equals);
			}
			else if (let getExpr = expr as Expression.Get)
			{
				expr = new Expression.Assign(getExpr, value, equals);
			}
			*/

			// Only Variable Get, and Index are valid targets
			if (expr is Expression.Variable || expr is Expression.Get || expr is Expression.Index)
			{
				expr = new Expression.Assign(expr, value, equals);
			}
			else
			{
				reportError(equals, "Invalid assignment target.");
				delete expr;
			}
		}

		return expr;
	}

	private Expression getExprOr()
	{
		var expr = getExprAnd();

		while (match(.Or))
		{
			let op = previous();
			let right = getExprAnd();
			expr = new Expression.Logical(expr, op, right);
		}

		return expr;
	}

	private Expression getExprAnd()
	{
		var expr = getExprEquality();

		while (match(.And))
		{
			let op = previous();
			let right = getExprEquality();
			expr = new Expression.Logical(expr, op, right);
		}

		return expr;
	}

	private Expression getExprEquality()
	{
		return parseLeftAssociativeBinaryOparation(
			=> getExprComparison,
			.BangEqual, .EqualEqual);
	}

	private Expression getExprComparison()
	{
		return parseLeftAssociativeBinaryOparation(
			=> getExprAddition,
			.Greater, .GreaterEqual, .Less, .LessEqual);
	}

	private Expression getExprAddition()
	{
		return parseLeftAssociativeBinaryOparation(
				=> getExprMultiplication,
				.Minus, .Plus);
	}

	private Expression getExprMultiplication()
	{
		return parseLeftAssociativeBinaryOparation(
			=> getExprUnary,
			.ForwardSlash, .Star, .Modulus);
	}

	private Expression getExprUnary()
	{
		if (match(.Bang, .Minus, .Ampersand))
		{
			let op = previous();
			let right = getExprUnary();
			return new Expression.Unary(op, right);
		}

		bool isCasting = false;
		Token? castToken = ?;
		Expression.NamedType castType = ?;

		if (match(.Cast))
		{
			isCasting = true;
			castToken = previous();

			consume(.LeftParen, "Expected '('");
			castType = consumeType();
			consume(.RightParen, "Expected ')'");

			return new AstNode.Expression.Cast(getExprCall(), castType, castToken.Value);
		}

		return getExprCall();
	}

	private Expression getExprCall()
	{
		var expr = getExprPostfix();

		/*
		NamespaceList namespaces = null;
		mixin createNamespaces()
		{
			if (namespaces == null)
			{
				namespaces = new .();
			}
		}
		*/

		while (true)
		{
			if (match(.LeftParen))
			{
				expr = finishCallExpr((Expression.Variable)expr);
			}
			else if (match(.DoubleColon))
			{
				// @HACK
				// This feels kinda hacky...
				delete expr;
				retreat();
				retreat();

				let left = consume(.Identifier, "Expected identifier after '::'");
				let separator = consume(.DoubleColon, "Expected '::'");
				let right = getExprCall();

				expr = new Expression.QualifiedName(left, separator, right);
			}
			else if (match(.Dot))
			{
				let name = consume(.Identifier, "Expected property name after '.'.");
				expr = new Expression.Get(expr, name);
			}
			else
			{
				// Do nothing & break out
				break;
			}
		}

		return expr;
	}

	private Expression finishCallExpr(Expression.Variable callee)
	{
		let open = previous();
		let arguments = new List<Expression>();
		if (!check(.RightParen))
		{
			repeat
			{
				arguments.Add(getExpression());
			}
			while (match(.Comma));
		}

		let close = consume(.RightParen, "Expected ')' after arguments.");

		return new Expression.Call(callee, arguments, open, close);
	}

	private Expression getExprPostfix()
	{
		var expr = getExprPrimary();

		while (true)
		{
			if (match(.LeftBracket))
			{
				let lbrack = previous();
				let index = getExpression();
				let rbrack = consume(.RightBracket, "Expected ']' after index expression");
				expr = new Expression.Index(expr, index, lbrack, rbrack);
			}
			else
			{
				break;
			}
		}

		return expr;
	}

	private Expression getExprPrimary()
	{
		mixin returnValue(Expression returnExpr)
		{
			return returnExpr;
		}

		mixin returnLiteral(Token prevToken, Variant? value, StringView valueStr)
		{
			returnValue!(new Expression.Literal(prevToken, value, valueStr));
		}

		if (match(.Number_Int, .Number_Float, .String))
		{
			Variant value = ?;
			switch (previous().Kind)
			{
			case .Number_Int:
				value = Variant.Create<int>(int.Parse(previous().Lexeme));
				break;
			case .Number_Float:
				value = Variant.Create<float>(float.Parse(previous().Lexeme));
				break;
			case .String:
				value = Variant.Create<StringView>(previous().Lexeme);
				break;
			default:
				Runtime.FatalError("Variant token case not handled.");
			}

			returnLiteral!(previous(), value, previous().Lexeme);
		}

		if (match(.This))
		{
			returnValue!(new Expression.This(previous()));
		}

		if (match(.Identifier))
		{
			returnValue!(new Expression.Variable(previous()));
		}

		if (match(.LeftParen))
		{
			let expr = getExpression();
			consume(.RightParen, "Expected ')' after expression.");
			returnValue!(new Expression.Grouping(expr));
		}

		reportError(peek(), "Expected expression.");
		advance();
		return null;
	}

	private Expression parseLeftAssociativeBinaryOparation(function Expression(Self this) higherPrecedence, params TokenKind[] tokenTypes)
	{
		var expr = higherPrecedence(this);

		while (match(params tokenTypes))
		{
			let op = previous();
			let right = higherPrecedence(this);
			expr = new Expression.Binary(expr, op, right, false);
		}

		return expr;
	}
}