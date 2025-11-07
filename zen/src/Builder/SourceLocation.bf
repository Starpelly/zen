using System;

namespace Zen;

public struct SourceLocation
{
	public readonly SourceFileID File;

	public readonly int Line;
	public readonly int Column;
	/// Absolute position in the file
	public readonly int Offset;

	public this(SourceFileID file, int line, int col, int offset)
	{
		this.File = file;
		this.Line = line;
		this.Column = col;
		this.Offset = offset;
	}
}

public struct SourceRange
{
	public readonly SourceLocation Start;
	public readonly SourceLocation End;

	public this(SourceLocation start, SourceLocation end)
	{
		this.Start = start;
		this.End = end;
	}
}