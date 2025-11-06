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
		// @TODO
		// reportError(previous(), "An empty block cannot be used as an expression");

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
				let range = SourceRange(expr.Range.Start, value.Range.End);
				expr = new Expression.Assign(expr, value, equals, range);
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

		while (match(.Or)) // ||
		{
			let op = previous();
			let right = getExprAnd();
			let range = SourceRange(expr.Range.Start, right.Range.End);
			expr = new Expression.Logical(expr, op, right, range);
		}

		return expr;
	}

	private Expression getExprAnd()
	{
		var expr = getExprEquality();

		while (match(.And)) // &&
		{
			let op = previous();
			let right = getExprEquality();
			let range = SourceRange(expr.Range.Start, right.Range.End);
			expr = new Expression.Logical(expr, op, right, range);
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
			let range = SourceRange(op.SourceRange.Start, right.Range.End);
			return new Expression.Unary(op, right, range);
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

			let callValue = getExprCall();

			// I never realized how out of order some of these ranges are lol
			let range = SourceRange(castToken.Value.SourceRange.Start, callValue.Range.End);
			return new AstNode.Expression.Cast(callValue, castType, castToken.Value, range);
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

				let range = SourceRange(left.SourceRange.Start, right.Range.End);
				expr = new Expression.QualifiedName(left, separator, right, range);
			}
			else if (match(.Dot))
			{
				let name = consume(.Identifier, "Expected property name after '.'.");
				let range = SourceRange(expr.Range.Start, name.SourceRange.End);
				expr = new Expression.Get(expr, name, range);
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

		let range = SourceRange(callee.Range.Start, close.SourceRange.End);
		return new Expression.Call(callee, arguments, open, close, range);
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

				let range = SourceRange(lbrack.SourceRange.Start, rbrack.SourceRange.End);
				expr = new Expression.Index(expr, index, lbrack, rbrack, range);
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

		if (match(.Number_Int, .Number_Float, .String))
		{
			let token = previous();

			Variant value = ?;
			switch (token.Kind)
			{
			case .Number_Int:
				value = Variant.Create<int>(int.Parse(token.Lexeme));
				break;
			case .Number_Float:
				value = Variant.Create<float>(float.Parse(token.Lexeme));
				break;
			case .String:
				value = Variant.Create<StringView>(token.Lexeme);
				break;
			default:
				Runtime.FatalError("Variant token case not handled.");
			}

			let range = token.SourceRange; // Literals just use the token directly so this is fine
			returnValue!(new Expression.Literal(token, value, token.Lexeme, range));
		}

		if (match(.This))
		{
			// @TODO
			// I don't remember what this does lol
			let range = previous().SourceRange;
			returnValue!(new Expression.This(previous(), range));
		}

		if (match(.Identifier))
		{
			let token = previous();
			let range = token.SourceRange;
			returnValue!(new Expression.Variable(token, range));
		}

		if (match(.LeftParen))
		{
			let lparen = previous();
			let expr = getExpression();
			let rparen = consume(.RightParen, "Expected ')' after expression.");

			let range = SourceRange(lparen.SourceRange.Start, rparen.SourceRange.End);
			returnValue!(new Expression.Grouping(expr, range));
		}

		if (check(.LeftBrace))
		{
			returnValue!(getExprCompositeLiteral());
		}

		reportError(peek(), "Expected an expression.");
		advance();
		return null;
	}

	private Expression.CompositeLiteral getExprCompositeLiteral()
	{
		let lbrace = consume(.LeftBrace, "Expected '{'");
		let elements = new List<Expression>();

		if (!check(.RightBrace))
		{
			repeat
			{
				elements.Add(getExpression());
			} while(match(.Comma));
		}

		let rbrace = consume(.RightBrace, "Expected '}'");

		let range = SourceRange(lbrace.SourceRange.Start, rbrace.SourceRange.End);
		return new .(elements, lbrace, rbrace, range);
	}

	private Expression parseLeftAssociativeBinaryOparation(function Expression(Self this) higherPrecedence, params TokenKind[] tokenTypes)
	{
		var expr = higherPrecedence(this);

		while (match(params tokenTypes))
		{
			let op = previous();
			let right = higherPrecedence(this);

			let range = SourceRange(expr.Range.Start, right.Range.End);
			expr = new Expression.Binary(expr, op, right, false, range);
		}

		return expr;
	}
}