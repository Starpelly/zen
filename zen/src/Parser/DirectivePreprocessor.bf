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

class DirectivePreprocessor : Visitor
{
	public Result<void> Process(List<Token> inTokens, List<Token> outTokens, PreprocessingResult result)
	{
		Debug.Assert(outTokens.IsEmpty);

		var i = 0;
		while (i < inTokens.Count)
		{
			let token = inTokens[i];
			if (token.Kind == .Directive)
			{
				let name = token.Lexeme;
				// Console.WriteLine(name);
				switch (name)
				{
				case "#load":
					var pathToken = inTokens[++i];
					if (inTokens[++i].Kind != .Semicolon)
					{
						reportError(inTokens[i - 1], "Expected ';'");
					}

					// Trim the surrounding quotes
					bool isMultiline = false;
					let offset = (isMultiline) ? 3 : 1;
					let trimmedPath = pathToken.Lexeme.Substring(offset, pathToken.Lexeme.Length - 1 - offset);
					
					result.FilesToLoad.Add(new .(pathToken.File, trimmedPath, pathToken));
					break;
				case "#c":
					// var a = 0;
					break;
				default:
					reportError(token, "Unknown directive type");
					break;
				}
			}
			else
			{
				outTokens.Add(token);
			}

			i++;
		}

		return HadErrors ? .Err : .Ok;
	}
}