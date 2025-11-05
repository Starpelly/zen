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

public enum TokenKind : uint8
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
	case Ampersand;			// &
	case VerticalBar;		// |

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

	case And;	// &&
	case Or;	// ||

	case Identifier;
	case Comment;
	case Char;
	case String;
	case Number_Int;
	case Number_Float;

	case EOF = 255;

	[RegisterKeyword("if")]
	case If = 128;

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

	[RegisterKeyword("cast")]
	case Cast;

	[RegisterKeyword("assert")]
	case Assert;

	[RegisterKeyword("struct")]
	case Struct;

	[RegisterKeyword("enum")]
	case Enum;

	[RegisterKeyword("this")]
	case This;

	[RegisterKeyword("const")]
	case Const;
	
	[RegisterKeyword("extern")]
	case Extern;

	[RegisterKeyword("namespace")]
	case Namespace;

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