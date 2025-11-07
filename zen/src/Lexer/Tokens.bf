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

	// Used for preprocessors exclusively now
	// case Hash;				// #

	case And;	// &&
	case Or;	// ||

	case Identifier;
	case Directive;
	case Comment;
	case Char;
	case String;
	case Number_Int;
	case Number_Float;

	// Created from the pre-processor.
	case C_Code;

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

	public readonly SourceRange SourceRange;
	public readonly SourceFileID File;

	public this(TokenKind kind)
	{
		this.Kind = kind;
		this.Lexeme = String.Empty;
		this.SourceRange = default;
		this.File = default;
	}

	public this(TokenKind kind, StringView lexeme, int line, int col, int offset, SourceFileID file)
	{
		this.Kind = kind;
		this.Lexeme = lexeme;

		// In case you're worried, \n prevents tokens from being "multi-lined", so this is ok.
		let start = SourceLocation(file, line, col, offset);
		let end = SourceLocation(file, line, col + lexeme.Length, offset + lexeme.Length);
		this.SourceRange = .(start, end);

		this.File = file;
	}

	public this(TokenKind kind, StringView lexeme, SourceRange range, SourceFileID file)
	{
		this.Kind = kind;
		this.Lexeme = lexeme;
		this.SourceRange = range;
		this.File = file;
	}
}