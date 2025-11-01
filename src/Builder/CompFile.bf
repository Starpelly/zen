using System;
using System.Collections;

namespace Zen;

class CompFile
{
	public readonly String Path = new .() ~ delete _;

	public readonly String Name = new .() ~ delete _;
	public readonly String Text ~ delete _;
	public readonly List<StringView> Lines = new .() ~ delete _;

	public readonly Tokenizer Tokenizer ~ delete _;
	public readonly Parser Parser ~ delete _;

	public readonly List<Token> Tokens;
	public readonly Ast Ast;

	public this(String path, String name, String text, Tokenizer tokenizer, Parser parser, List<Token> tokens, Ast ast)
	{
		this.Path.Set(path);
		this.Name.Set(name);
		this.Text = text;

		this.Tokenizer = tokenizer;
		this.Parser = parser;

		this.Tokens = tokens;
		this.Ast = ast;

		let split = text.Split('\n');
		for (let line in split)
		{
			this.Lines.Add(line);
		}
	}
}
