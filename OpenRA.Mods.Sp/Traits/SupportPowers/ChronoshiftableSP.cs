#region Copyright & License Information
/*
 * Copyright (c) The OpenRA Developers and Contributors
 * This file is part of OpenRA, which is free software. It is made
 * available to you under the terms of the GNU General Public License
 * as published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version. For more
 * information, see COPYING.
 */
#endregion

using System.Collections.Generic;
using OpenRA.Mods.Common.Traits;
using OpenRA.Mods.SP.Activities;
using OpenRA.Primitives;
using OpenRA.Traits;

namespace OpenRA.Mods.SP.Traits
{
	[Desc("Can be teleported via Chronoshift power.")]
	public class ChronoshiftableSPInfo : ConditionalTraitInfo
	{
		[Desc("Types of damage that this trait causes when teleported to following terrain while unit cannot stand on it.")]
		public readonly Dictionary<HashSet<string>, BitSet<DamageType>> TerrainsAndDamageTypes = default;

		[Desc("Max distance when destination is unavaliable for allies")]
		public readonly int MaxSearchCellDistance = 5;

		public override object Create(ActorInitializer init) { return new ChronoshiftableSP(this); }
	}

	public class ChronoshiftableSP : ConditionalTrait<ChronoshiftableSPInfo>, ITick, ISync
	{
		IPositionable iPositionable;

		public ChronoshiftableSP(ChronoshiftableSPInfo info)
			: base(info)
		{
		}

		void ITick.Tick(Actor self)
		{
			if (IsTraitDisabled)
				return;
		}

		protected override void Created(Actor self)
		{
			iPositionable = self.OccupiesSpace as IPositionable;
			base.Created(self);
		}

		// Can't be used in synced code, except with ignoreVis.
		public virtual bool CanChronoshiftTo(Actor self, CPos targetLocation)
		{
			// TODO: Allow enemy units to be chronoshifted into bad terrain to kill them
			return !IsTraitDisabled && iPositionable != null && iPositionable.CanEnterCell(targetLocation);
		}

		public virtual bool Teleport(Actor self, CPos targetLocation, List<CPos> teleportCells, Actor chronoProvider)
		{
			if (IsTraitDisabled)
				return false;

			self.QueueActivity(false, new ChronoTeleportSP(chronoProvider, targetLocation, teleportCells, Info.MaxSearchCellDistance, true, Info.TerrainsAndDamageTypes));
			return true;
		}
	}
}
