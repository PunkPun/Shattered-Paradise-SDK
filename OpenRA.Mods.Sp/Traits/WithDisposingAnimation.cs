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

using OpenRA.Mods.Common.Effects;
using OpenRA.Mods.Common.Traits;
using OpenRA.Traits;

namespace OpenRA.Mods.SP.Traits.Render
{
	[Desc("This actor has a death animation.")]
	public class WithDisposingAnimationInfo : ConditionalTraitInfo
	{
		[FieldLoader.Require]
		[Desc("Image to display.")]
		public readonly string Image = null;

		[SequenceReference(prefix: true)]
		[Desc("Sequence prefix to play when this actor is killed by a warhead.")]
		public readonly string DisposingSequence = "die";

		[PaletteReference(nameof(IsPlayerPalette))]
		[Desc("The palette used for `DeathSequence`.")]
		public readonly string Palette = "effect";

		[Desc("Custom death animation palette is a player palette BaseName")]
		public readonly bool IsPlayerPalette = false;

		[Desc("Delay the spawn of the death animation by this many ticks.")]
		public readonly int Delay = 0;

		public override object Create(ActorInitializer init) { return new WithDisposingAnimation(init.Self, this); }
	}

	public class WithDisposingAnimation : ConditionalTrait<WithDisposingAnimationInfo>, INotifyActorDisposing
	{
		public WithDisposingAnimation(Actor self, WithDisposingAnimationInfo info)
			: base(info) {	}

		void INotifyActorDisposing.Disposing(Actor self)
		{
			if (IsTraitDisabled)
				return;

			var palette = Info.Palette;
			if (Info.IsPlayerPalette)
				palette += self.Owner.InternalName;

			var sequence = Info.DisposingSequence;
			var pos = self.CenterPosition;
			var image = Info.Image;
			var delay = Info.Delay;

			self.World.AddFrameEndTask(w => w.Add(new SpriteEffect(pos, w, image, sequence, palette, delay: delay)));
		}
	}
}
