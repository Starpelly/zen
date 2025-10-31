using System;
using System.Collections;

namespace Zen;

class Scope
{
	public Result<Scope> Parent = .Err;
	public readonly List<Scope> Children = new .() ~ DeleteContainerAndItems!(_);
	public readonly Dictionary<StringView, Entity> Entities = new .() ~ DeleteDictionaryAndValues!(_);

	public readonly String Name = new .() ~ delete _;

	public this(String name, Scope parent)
	{
		Name.Set(name);

		if (parent != null)
		{
			this.Parent = .Ok(parent);
			parent.Children.Add(this);
		}
	}

	public Result<Entity> Lookup(StringView name)
	{
		if (Entities.TryGetValue(name, let entity))
			return entity;

		// Look upward the scope chain
		if (Parent case .Ok(let parent))
			return parent.Lookup(name);

		return .Err;
	}

	public Result<Entity> QualifiedLookup(params StringView[] path)
	{
		Entity current = this.Lookup(path[0]);
		if (current == null) return .Err;

		for (int i = 1; i < path.Count; i++)
		{
			if (current.Type != .Enum)
				return .Err;
			let typename = current as Entity.TypeName;
			if (let newScope = typename.Decl as AstNode.Stmt.IScope)
			{
				current = newScope.Scope.Lookup(path[i]);
			}
			if (current == null)
				return .Err;
		}

		return current;
	}
}