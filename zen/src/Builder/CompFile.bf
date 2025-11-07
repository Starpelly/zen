using System;
using System.Collections;

namespace Zen;

class CompFile
{
	public readonly SourceFile Source;

	public readonly List<Token> Tokens ~ delete _;
	public readonly Ast Ast ~ DeleteContainerAndItems!(_);

	public readonly PreprocessingResult PreprocessingResult ~ delete _;

	public this(SourceFile file, List<Token> tokens, Ast ast, PreprocessingResult ppResult)
	{
		this.Source = file;

		this.Tokens = tokens;
		this.Ast = ast;

		this.PreprocessingResult = ppResult;
	}
}
