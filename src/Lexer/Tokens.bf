using System;

namespace Zen;

[AttributeUsage(.StaticField, .ReflectAttribute)]
public struct RegisterKeywordAttribute : Attribute
{
	public String Lexeme;

	public this(String lexeme)
	{
		this.Lexeme = lexeme;
	}
}

public enum TokenKind
{
	case LeftParen;			// (
	case RightParen;		// )
	case LeftBrace;			// {
	case RightBrace;		// }
	case LeftBracket;		// [
	case RightBracket;		// ]

	case Dot;				// .
	case Comma;				// ,
	case Colon;				// :
	case Semicolon;			// ;
	case ForwardSlash;		// /
	case BackwardSlash;		// \
	case Star;				// *
	case Bang;				// !
	case Equal;				// =
	case Greater;			// >
	case Less;				// <
	case Minus;				// -
	case Plus;				// +
	case Modulus;			// %
	case Question;			// ?
	case Hash;				// #

	case PlusEqual;			// +=
	case MinusEqual;		// -=
	case StarEqual;			// *=
	case ForwardSlashEqual;	// /=
	case ModulusEqual;		// %=
	case DoubleColon;		// ::

	case EqualEqual;		// ==
	case BangEqual;			// !=
	case LessEqual;			// <=
	case GreaterEqual;		// >=

	case Identifier;
	case Comment;
	case Char;
	case String;
	case Number_Int;
	case Number_Float;

	case EOF;

	[RegisterKeyword("if")]
	case If;

	[RegisterKeyword("else")]
	case Else;

	[RegisterKeyword("for")]
	case For;

	[RegisterKeyword("fun")]
	case Function;

	[RegisterKeyword("while")]
	case While;

	[RegisterKeyword("return")]
	case Return;

	[RegisterKeyword("var")]
	case Var;

	[RegisterKeyword("let")]
	case Let;

	[RegisterKeyword("auto")]
	case Auto;

	[RegisterKeyword("defer")]
	case Defer;

	[RegisterKeyword("type")]
	case Type;

	[RegisterKeyword("cast")]
	case Cast;

	[RegisterKeyword("assert")]
	case Assert;

	[RegisterKeyword("struct")]
	case Struct;

	[RegisterKeyword("enum")]
	case Enum;

	[RegisterKeyword("and")]
	case And;

	[RegisterKeyword("or")]
	case Or;

	[RegisterKeyword("this")]
	case This;

	[RegisterKeyword("const")]
	case Const;
	
	[RegisterKeyword("extern")]
	case Extern;

	public Result<RegisterKeywordAttribute> GetKeyword()
	{
		var memInfo = typeof(Self).GetField(this.ToString(.. scope .())).Value;
		var attr = memInfo.GetCustomAttribute<RegisterKeywordAttribute>();

		return attr;
	}
}

struct Token
{
	public readonly TokenKind Kind;
	public readonly StringView Lexeme;

	public readonly int Line;
	public readonly int Column;

	public readonly Guid File;

	public this(TokenKind type, StringView lexeme, int line, int col, Guid file)
	{
		this.Kind = type;
		this.Lexeme = lexeme;

		this.Line = line;
		this.Column = col;

		this.File = file;
	}
}