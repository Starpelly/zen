using System;
using System.Collections;

namespace Zen;

public class ErrorManager
{
	private struct CodeError
	{
		public readonly StringView Message = "";
		public readonly int Column;
		public readonly int Length;

		public this(int col, int length)
		{
			this.Column = col;
			this.Length = length;
		}
	}

	private class CodeWriter
	{
		public Dictionary<int, CodeError> Errors { get; } ~ delete _;
		private ConsoleColor m_codeColor;

		public this(Dictionary<int, CodeError> errors, ConsoleColor codeColor)
		{
			this.Errors = errors;
			this.m_codeColor = codeColor;
		}

		public void AppendLine(int line, StringView lineText)
		{
			let lineNumStr = (line + 1).ToString(.. scope .());

			Console.ForegroundColor = m_codeColor;
			Console.WriteLine(lineWithNumberBar(lineNumStr, lineText, .. scope .()));

			if (Errors.TryGetValue(line, let error))
			{
				Console.ForegroundColor = .Red;
				defer { Console.ForegroundColor = m_codeColor; }

				let arrowLine = scope String(error.Column + error.Length);
				for (let i < error.Column)
				{
					let char = lineText[i];
					switch (char)
					{
					case '\t':
						arrowLine.Append('\t');
						break;
					default:
						arrowLine.Append(' ');
						break;
					}
				}
				for (let i < error.Length)
				{
					arrowLine.Append('^');
				}
				let pad = scope String()..PadLeft(lineNumStr.Length);
				Console.WriteLine(lineWithNumberBar(pad, arrowLine, .. scope .()));
			}
		}

		private void lineWithNumberBar(StringView number, StringView text, String outString)
		{
			outString.Append(scope $"{number} | {text}");
		}
	}

	private ConsoleColor m_CodeColor;

	public this(ConsoleColor codeColor)
	{
		this.m_CodeColor = codeColor;
	}

	public void WriteError(CompFile compiledFile, CompilerError error)
	{
		Console.ForegroundColor = .Red;
		defer { Console.ForegroundColor = m_CodeColor; }

		Console.Write(scope $"ERROR: ");
		Console.WriteLine(scope $"{error.Message}");

		Console.ForegroundColor = .Cyan;

		Console.WriteLine(scope $"{compiledFile.Name}:{error.FirstToken.Line + 1}:{error.FirstToken.Column + 1}");
		// Console.WriteLine();

		Console.ForegroundColor = m_CodeColor;

		// @FIX
		// This needs to support multiple lines in the future...
		let errors = new Dictionary<int, CodeError>();
		let errorLine = error.FirstToken.Line;
		let errorColumn = error.FirstToken.Column;
		let errorLength = error.FirstToken.Lexeme.Length;
		errors.Add(errorLine, .(errorColumn, errorLength));

		// Number line thing on the left, idk it looks cool!
		let codeLine = scope CodeWriter(errors, m_CodeColor);
		codeLine.AppendLine(error.FirstToken.Line, compiledFile.Lines[error.FirstToken.Line]);
	}
}