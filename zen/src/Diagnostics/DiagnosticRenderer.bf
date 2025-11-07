using System;
using System.Collections;

namespace Zen;

public class DiagnosticRenderer
{
	private ConsoleColor m_CodeColor;

	public this(ConsoleColor codeColor)
	{
		this.m_CodeColor = codeColor;
	}

	public void WriteError(Dictionary<Guid, CompFile> fileIDs, Diagnostic diagnostic)
	{
		Console.ForegroundColor = .Red;
		defer { Console.ForegroundColor = m_CodeColor; }

		Console.Write(scope $"ERROR: ");
		Console.WriteLine(scope $"{diagnostic.Message}");

		for (let span in diagnostic.Spans)
		{
			let file = fileIDs[span.Range.Start.File];
			let line = file.Lines[span.Range.Start.Line];

			let lineNumStr = (span.Range.Start.Line + 1).ToString(.. scope .());

			Console.ForegroundColor = .Cyan;
			Console.WriteLine(scope $" --> {file.Name}:{span.Range.Start.Line + 1}:{span.Range.Start.Column + 1}");

			Console.ForegroundColor = m_CodeColor;
			Console.WriteLine(writeStringWithNumberBar(lineNumStr, line, .. scope .()));

			Console.ForegroundColor = .Red;
			defer { Console.ForegroundColor = m_CodeColor; }

			/*
			let space = scope String(' ', span.Range.Start.Column);
			let arrow = scope String('^', span.Range.End.Offset - span.Range.Start.Offset);
			Console.WriteLine(scope $"{space} {arrow}");
			*/

			let arrowLine = scope String();
			for (let i < span.Range.Start.Column)
			{
				// I hate that I have to do this lol....
				// Think about what it could've been:
				// 		let space = scope String(' ', span.Range.Start.Column);
				// beautiful...
				let char = line[i];
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
			arrowLine.Append('^', span.Range.End.Offset - span.Range.Start.Offset);
			let pad = scope String()..PadLeft(lineNumStr.Length);
			Console.WriteLine(writeStringWithNumberBar(pad, arrowLine, .. scope .()));
		}

		void writeStringWithNumberBar(StringView number, StringView text, String outString)
		{
			outString.Append(scope $"{number} | {text}");
		}
	}
}

// Old stuff
/*
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
*/