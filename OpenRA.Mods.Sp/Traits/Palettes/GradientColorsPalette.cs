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

using System.Linq;
using OpenRA.Graphics;
using OpenRA.Primitives;
using OpenRA.Traits;

namespace OpenRA.Mods.SP.Traits
{
	[TraitLocation(SystemActors.World | SystemActors.EditorWorld)]
	[Desc("Add this to the World actor definition.")]
	public class GradientColorsPaletteInfo : TraitInfo, ILobbyCustomRulesIgnore
	{
		[PaletteDefinition]
		[Desc("The name of the resulting palette")]
		public readonly string Name = "resources";

		[FieldLoader.Require]
		[Desc("Start color for gradient")]
		public readonly Color StartColor;

		[FieldLoader.Require]
		[Desc("End color for gradient.")]
		public readonly Color EndColor;

		[Desc("Index set to be fully transparent/invisible.")]
		public readonly int TransparentIndex = 0;

		[Desc("Allow palette modifiers to change the palette.")]
		public readonly bool AllowModifiers = true;

		public override object Create(ActorInitializer init) { return new GradientColorsPalette(this); }
	}

	public class GradientColorsPalette : ILoadsPalettes
	{
		readonly GradientColorsPaletteInfo info;

		public GradientColorsPalette(GradientColorsPaletteInfo info)
		{
			this.info = info;
		}

		public void LoadPalettes(WorldRenderer wr)
		{
			var da = (info.EndColor.A - info.StartColor.A) / 254f;
			var dr = (info.EndColor.R - info.StartColor.R) / 254f;
			var dg = (info.EndColor.G - info.StartColor.G) / 254f;
			var db = (info.EndColor.B - info.StartColor.B) / 254f;
			var d = 0;
			wr.AddPalette(info.Name, new ImmutablePalette(Enumerable.Range(0, Palette.Size).
				Select(i => (i == info.TransparentIndex) ? 0 : Color.FromArgb(info.StartColor.A + (int)(++d * da), info.StartColor.R + (int)(d * dr), info.StartColor.G + (int)(d * dg), info.StartColor.B + (int)(d * db)).ToArgb())), info.AllowModifiers);
		}
	}
}
