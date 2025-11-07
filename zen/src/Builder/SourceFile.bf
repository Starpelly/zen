using System;
using System.IO;
using System.Collections;

namespace Zen;

typealias SourceFileID = uint8;

class SourceFile
{
	public readonly SourceFileID ID;

	public readonly String Path ~ delete _;
	public readonly String Name ~ delete _;
	public readonly String Content ~ delete _;
	public readonly StringView[] Lines ~ delete _;

	public this(SourceFileID id, String path)
	{
		this.ID = id;
		this.Path = new .(path);
		this.Name = System.IO.Path.GetFileName(path, .. new .());
		this.Content = File.ReadAllText(path, .. new .());

		let split = Content.Split('\n');
		let lines = scope List<StringView>();
		for (let line in split)
		{
			lines.Add(line);
		}

		this.Lines = new .[lines.Count];
		lines.CopyTo(this.Lines);
	}
}