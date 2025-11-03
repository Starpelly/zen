using System;
using System.Collections;
using System.Diagnostics;

namespace Zen;

class Scope
{
	public readonly Result<Scope> Parent = .Err;
	public readonly Result<Entity.Namespace> NamespaceParent = .Err;

	public readonly List<Scope> Children = new .() ~ DeleteContainerAndItems!(_);

	public readonly Dictionary<StringView, Entity> EntityMap = new .() ~ delete _;
	public readonly Dictionary<AstNode.Stmt, Entity> NodeEntityMap = new .() ~ delete _;

	private readonly List<Entity> m_entities = new .() ~ DeleteContainerAndItems!(_);

	public readonly String Name = new .() ~ delete _;


	public this(String name, Scope parent, Entity.Namespace namespaceParent)
	{
		Name.Set(name);

		if (parent != null)
		{
			this.Parent = .Ok(parent);
			parent.Children.Add(this);
		}
		if (namespaceParent != null)
		{
			this.NamespaceParent = .Ok(namespaceParent);
		}
	}

	public Result<Entity> LookupName(StringView name)
	{
		if (EntityMap.TryGetValue(name, let entity))
			return entity;

		// Look upward the scope chain
		if (Parent case .Ok(let parent))
			return parent.LookupName(name);

		return .Err;
	}

	public Result<T> LookupName<T>(StringView name) where T : Entity
	{
		if (EntityMap.TryGetValue(name, let entity))
		{
			if (entity is T)
				return entity as T;
		}

		// Look upward the scope chain
		if (Parent case .Ok(let parent))
			return parent.LookupName<T>(name);

		return .Err;
	}

	public Result<Entity> LookupStmt(AstNode.Stmt stmt)
	{
		if (NodeEntityMap.TryGetValue(stmt, let entity))
			return entity;

		// Look upward the scope chain
		if (Parent case .Ok(let parent))
			return parent.LookupStmt(stmt);

		return .Err;
	}

	public Result<T> LookupStmtAs<T>(AstNode.Stmt stmt) where T : Entity
	{
		if (NodeEntityMap.TryGetValue(stmt, let entity))
		{
			Runtime.Assert(entity.GetType() == typeof(T));
			return entity as T;
		}

		// Look upward the scope chain
		if (Parent case .Ok(let parent))
			return parent.LookupStmtAs<T>(stmt);

		return .Err;
	}

	public void DeclareWithName(Entity entity, StringView name)
	{
		m_entities.Add(entity);
		EntityMap.Add(name, entity);
	}

	public void DeclareWithAstNode(Entity entity, StringView name, AstNode.Stmt stmt)
	{
		m_entities.Add(entity);
		EntityMap.Add(name, entity);
		NodeEntityMap.Add(stmt, entity);
	}
}