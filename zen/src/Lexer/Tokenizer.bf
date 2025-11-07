using System;
using System.Collections;

namespace Zen;

class Tokenizer
{
	[Comptime, OnCompile(.TypeInit)]
	private static void Process()
	{
		let t = scope String();
		t.Append("private static readonly Dictionary<StringView, TokenKind> s_keywordsMap = new .()");
		t.Append("\n{");

		for (let field in Enum.GetEnumerator<TokenKind>())
		{
			if (field.value.GetKeyword() case .Ok(let keyword))
			{
				t.Append("\n\t");
				t.Append(scope $"""
					("{keyword.Lexeme}", .{field.value}),
					""");
			}
		}

		t.Append("\n} ~ delete _;");

		Compiler.EmitTypeBody(typeof(Self), t);
	}

	private readonly List<Token> m_tokens = new .() ~ delete _;

	private int m_start = 0;
	private int m_current = 0;
	private int m_line = 0;
	private int m_column = 0;

	private readonly SourceFileID m_file;

	private readonly StringView m_source;

	public this(StringView source, SourceFileID file)
	{
		this.m_source = source;
		this.m_file = file;
	}

	public List<Token> Run()
	{
		while (!isAtEnd())
		{
			// We are at the beginning of the next lexeme.
			m_start = m_current;
			scanNextToken();
		}

		addToken(.EOF, "");
		return m_tokens;
	}

	private void scanNextToken(params char8[] ignore)
	{
		let c = peek();
		advance();

		for (let char in ignore)
		{
			if (c == char)
				return;
		}

		switch (c)
		{
		case '(' : addToken(.LeftParen); break;
		case ')' : addToken(.RightParen); break;
		case '{' : addToken(.LeftBrace); break;
		case '}' : addToken(.RightBrace); break;
		case '[':  addToken(.LeftBracket); break;
		case ']':  addToken(.RightBracket); break;
		case ',' : addToken(.Comma); break;
		case '.' : addToken(.Dot); break;
		case ';' : addToken(.Semicolon); break;
		case '?' : addToken(.Question); break;
		case '&' : addToken(match('&', true) ? .And : .Ampersand); break;
		case '|' : addToken(match('|', true) ? .Or : .Ampersand); break;
		case '+' : addToken(match('=', true) ? .PlusEqual : .Plus); break;
		case '-' : addToken(match('=', true) ? .MinusEqual : .Minus); break;
		case '*' : addToken(match('=', true) ? .StarEqual : .Star); break;
		case '%' : addToken(match('=', true) ? .ModulusEqual : .Modulus); break;
		case '!' : addToken(match('=', true) ? .BangEqual : .Bang); break;
		case '=' : addToken(match('=', true) ? .EqualEqual : .Equal); break;
		case '<' : addToken(match('=', true) ? .LessEqual : .Less); break;
		case '>' : addToken(match('=', true) ? .GreaterEqual : .Greater); break;
		case '#' :
			if (isDigit(peek()))
			{
				// @ERROR
				// Unexpected character error.
			}
			else if (isAlpha(peek()))
			{
				scanIdentifier(true);
			}
			else
			{
				// @ERROR
				// Unexpected character error.
			}
			break;
		case '/' :
			if (match('/', true))
			{
				// A comment goes until the end of the line.
				while (peek() != '\n' && !isAtEnd()) advance();
			}
			else if (match('*', true))
			{
				int depth = 1;

				// Walks over a multi-line comment, it increments the line number each time a new line break is found and ignores
				// every sequence of characters contained in the comment. The common execution of the scanner takes place
				// once the '*/' characters are found.
				while (!isAtEnd())
				{
					let cc = peek();

					if (cc == '\n')
					{
						increaseLine();
						advance();
						continue;
					}

					// New nested block comment
					if (cc == '/' && peekNext() == '*')
					{
						advance(); // consume '/'
						advance(); // consume '*'
						depth++;
						continue;
					}

					// Closing a block comment level
					if (cc == '*' && peekNext() == '/')
					{
						advance(); // consume '*'
						advance(); // consume '/'
						depth--;
						if (depth == 0) return; // Finished the whole comment
						continue;
					}

					// Any other char inside the comment
					advance();
				}

				// @ERROR
				// Unterminated block comment
			}
			else if (match('=', true))
			{
				addToken(.ForwardSlashEqual);
			}
			else
			{
				addToken(.ForwardSlash);
			}
			break;
			case ':':
			if (match(':', true))
			{
				addToken(.DoubleColon);
			}
			else
			{
				addToken(.Colon);
			}
			break;

		case ' ':
		case '\r':
			// Ignore white-space.
			break;
		case '\t':
			// Ignore white-space.
			// m_column += 3;
			break;

		case '\n':
			increaseLine();
			break;

		case '"':
			scanString();
			break;

		default:
			if (isDigit(c))
			{
				scanNumber();
			}
			else if (isAlpha(c))
			{
				scanIdentifier(false);
			}
			else
			{
				// @ERROR
				// Unexpected character error.
			}
			break;
		}
	}

	private bool isAtEnd()
	{
		return m_current >= m_source.Length;
	}

	private StringView substring(int start, int end)
	{
		return m_source.Substring(start, end - start);
	}

	private void addToken(TokenKind type)
	{
		m_tokens.Add(.(type, substring(m_start, m_current), m_line, m_column - (m_current - m_start), m_current, m_file));
		// addToken(type/*, getValue()*/);
	}

	private void addToken(TokenKind type, StringView lexeme)
	{
		m_tokens.Add(.(type, lexeme, m_line, m_column - (m_current - m_start), m_current, m_file));
	}

	private void increaseLine()
	{
		m_line++;
		m_column = 0;
	}

	private bool isAlpha(char8 c)
	{
		return c.IsLetter || c == '_';
	}

	private bool isAlphaNumeric(char8 c)
	{
		return isAlpha(c) || isDigit(c);
	}

	private bool isDigit(char8 c)
	{
		return c.IsDigit;
	}

	/// Moves the character in the text forward by 'count'.
	private void advance(int count = 1)
	{
		m_current += count;
		m_column += count;
	}

	private char8 previous(int backwards = 1)
	{
		return m_source[m_current - backwards];
	}

	/// Returns the current character in the text.
	private char8 peek()
	{
		if (isAtEnd()) return '\0';
		return m_source[m_current];
	}

	/// Returns the next character in the text.
	private char8 peekNext(int forwards = 1)
	{
		if (m_current + forwards >= m_source.Length) return '\0';
		return m_source[m_current + forwards];
	}

	private bool match(char8 expected, bool advance)
	{
		if (isAtEnd()) return false;
		if (m_source[m_current] != expected) return false;

		if (advance)
		{
			advance();
		}
		return true;
	}

	private void scanString()
	{
		let isMultiline = peek() == '"' && peekNext() == '"';

		if (isMultiline)
		{
			// Consume the initial `"""`.
			scanNextToken('"');
			scanNextToken('"');
			scanNextToken('"');

			// Scan until the closing `"""` or the end of input.
			while (!(peek() == '"' && peekNext() == '"' && peekNext(2) == '"') && !isAtEnd())
			{
			    if (peek() == '\n') increaseLine();
			    advance();
			}

			// If we reached the end without finding `"""`.
			if (isAtEnd())
			{
				// Lexer error: Unterminated multi-line string.
				return;
			}

			// Consume the closing `"""`.
			scanNextToken('"');
			scanNextToken('"');
			scanNextToken('"');
		}
		else
		{
			while (peek() != '"' && !isAtEnd())
			{
				if (peek() == '\n') increaseLine();
				advance();
			}

			if (isAtEnd())
			{
				// Un-terminated string.
				// Lexer error here.
				return;
			}

			// Closing ".
			advance();
		}

		// Trim the surrounding quotes.
		// let offset = (isMultiline) ? 3 : 1;
		// let value = substring(m_start + offset, m_current - offset);
		addToken(.String/*, Variant.Create<StringView>(value)*/);
	}

	private void scanNumber()
	{
		mixin peekWhileIsDigit()
		{
			while (isDigit(peek())) advance();
		}

		/*
		bool isNegative = false;

		if (m_tokens.Back.Kind == .Minus)
		{
			m_tokens.PopBack();
			// m_tokens.Remove(m_tokens.Back);
		}
		*/

		peekWhileIsDigit!();

		var type = TokenKind.Number_Int;

		// Look for a fractional part.
		if (peek() == '.' && isDigit(peekNext()))
		{
			// Consume the "."
			advance();

			peekWhileIsDigit!();

			type = .Number_Float;
		}

		// let substring = substring(m_start, m_current);

		switch (type)
		{
		case .Number_Int:
			// let literal = int.Parse(substring);
			addToken(.Number_Int/*, Variant.Create<int>(literal)*/);
			break;
		case .Number_Float:
			// let literal = float.Parse(substring);
			addToken(.Number_Float/*, Variant.Create<double>(literal)*/);
			break;
		default:
		}
	}

	private void scanIdentifier(bool isDirective)
	{
		while (isAlphaNumeric(peek()))
		{
			advance();
		}
		// Check if the identifer is a reserved keyword.
		let text = substring(m_start, m_current);

		if (s_keywordsMap.TryGetValue(text, let type))
		{
			addToken(type);
		}
		else
		{
			if (isDirective)
				addToken(.Directive);
			else
				addToken(.Identifier);
		}
	}
}