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

	public bool TryDeclare(StringView name, Entity entity)
	{
		if (Entities.ContainsKey(name))
			return false;
		Entities.Add(name, entity);
		// entity.Scope = this;
		return true;
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
}