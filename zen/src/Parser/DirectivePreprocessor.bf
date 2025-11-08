using System;
using System.Collections;
using System.Diagnostics;

namespace Zen;

class PreprocessingResult
{
	public class FileLoad
	{
		/// Used to search relatively from the origin file.
		public readonly SourceFileID Origin;
		public readonly String Path = new .() ~ delete _;
		public readonly Token PathToken;

		public this(SourceFileID origin, StringView path, Token pathToken)
		{
			this.Origin = origin;
			this.Path.Set(path);
			this.PathToken = pathToken;
		}
	}

	public readonly List<FileLoad> FilesToLoad = new .() ~ DeleteContainerAndItems!(_);
}

public enum DirectiveKind
{
	Load,
	C,
	If,
	Else,
	EndIf,
	Unknown
}

public class Directive
{
	public readonly DirectiveKind Kind;
	public readonly SourceRange Range;
	public readonly List<Token> Arguments ~ delete _;
	public readonly String Payload;
}

class DirectivePreprocessor : Visitor
{
	private List<Token> m_inTokens;
	private int m_current = 0;

	public this(List<Token> tokens)
	{
		this.m_inTokens = tokens;
	}

	public Result<void> Process(SourceFile srcFile, List<Token> outTokens, PreprocessingResult result)
	{
		Debug.Assert(outTokens.IsEmpty);

		for (let i < m_inTokens.Count)
		{
			if (match(.Directive))
			{
				let name = previous();
				switch (name.Lexeme)
				{
				case "#load":
					var pathToken = consume(.String, "Expected a string as a file path");
					consume(.Semicolon, "Expected ';'");

					// Trim the surrounding quotes
					bool isMultiline = false;
					let offset = (isMultiline) ? 3 : 1;
					let trimmedPath = pathToken.Lexeme.Substring(offset, pathToken.Lexeme.Length - 1 - offset);
					
					result.FilesToLoad.Add(new .(pathToken.File, trimmedPath, pathToken));
					break;
				case "#c":
					let lbrace = consume(.LeftBrace, "Expected '{'");
					int braceDepth = 0;

					while (true)
					{
						if (check(.LeftBrace))
						{
							braceDepth++;
						}
						if (check(.RightBrace))
						{
							if (--braceDepth <= 0)
								break;
						}

						advance();
						// outTokens.Add(next());
					}

					let rbrace = consume(.RightBrace, "Expected '}'");

					let codeSrcRange = SourceRange(lbrace.SourceRange.End, rbrace.SourceRange.Start);
					let code = srcFile.Content.Substring(codeSrcRange.Start.Offset, codeSrcRange.End.Offset - codeSrcRange.Start.Offset - 1);

					outTokens.Add(Token(.C_Code, code, codeSrcRange, srcFile.ID));

					// This semicolon IS actually required for the parser to validate the expression it creates.
					// Yeah, we could've added it automatically, but then we would've needed to check if there was a semicolon, and that's a whole can of worms.
					// It's just more consistent like this tbh.
					outTokens.Add(consume(.Semicolon, "Expected ';'"));
					break;
				default:
					reportError(name, "Unknown directive type");
					break;
				}
			}
			else
			{
				outTokens.Add(next());
			}
		}

		return HadErrors ? .Err : .Ok;
	}

	private Token consume(TokenKind kind, String message)
	{
		if (check(kind))
		{
			advance();
			return previous();
		}

		reportError(previous(), message);
		return peek();
	}

	private bool match(params TokenKind[] types)
	{
		for (let type in types)
		{
			if (check(type))
			{
				advance();
				return true;
			}
		}
		return false;
	}

	/// Checks to see if the current token is the passed-in type.
	private bool check(TokenKind kind)
	{
		if (isAtEnd()) return false;
		return peek().Kind == kind;
	}

	private bool isAtEnd()
	{
		return peek().Kind == .EOF;
	}

	private void advance()
	{
		if (!isAtEnd()) m_current++;
	}

	private void retreat()
	{
		m_current--;
	}

	private Token peek()
	{
		return m_inTokens[m_current];
	}

	private Token previous()
	{
		return m_inTokens[m_current - 1];
	}

	private Token past(int count)
	{
		return m_inTokens[m_current - count];
	}

	private Token next()
	{
		if (isAtEnd()) return peek();
		return m_inTokens[m_current++];
	}
}