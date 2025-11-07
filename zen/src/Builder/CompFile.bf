using System;
using System.Collections;

namespace Zen;

class CompFile
{
	public readonly String Path = new .() ~ delete _;

	public readonly String Name = new .() ~ delete _;
	public readonly String Text ~ delete _;
	public readonly List<StringView> Lines = new .() ~ delete _;

	public readonly List<Token> Tokens ~ delete _;
	public readonly Ast Ast ~ DeleteContainerAndItems!(_);

	public readonly PreprocessingResult PreprocessingResult ~ delete _;

	public this(String path, String name, String text, List<Token> tokens, Ast ast, PreprocessingResult ppResult)
	{
		this.Path.Set(path);
		this.Name.Set(name);
		this.Text = text;

		this.Tokens = tokens;
		this.Ast = ast;

		this.PreprocessingResult = ppResult;

		let split = text.Split('\n');
		for (let line in split)
		{
			this.Lines.Add(line);
		}
	}
}
