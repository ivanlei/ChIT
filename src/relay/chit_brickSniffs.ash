// CHaracter Info Toolbox - sniff tracker brick
//
// KoLmafia's TrackManager keeps every active monster tracker in the
// trackedMonsters preference and every phylum tracker in trackedPhyla, each as
// colon-joined <target>:<method>:<turn> triples. This brick surfaces all of
// them, styled like an Effects row (icon + name + grey target + budget).
//
// Per-method metadata (labels, daily-cast caps, turn durations) mirrors
// TrackManager.Tracker plus KoLmafia's dailylimits.txt.

record sniff_entry {
	string target;   // monster name, or phylum for a trackedPhyla row
	string method;
	int setTurn;
	boolean phylum;
};

record sniff_meta {
	string label;
	string castPref;   // "" == no daily cast cap
	int castCap;
	int turnDuration;  // 0 == no per-cast turn limit
};

sniff_meta sniffMeta(string method) {
	switch(method) {
		case "Transcendent Olfaction":         return new sniff_meta("On the Trail", "_olfactionsUsed", 3, 0);
		case "Nosy Nose":
		case "Get a Good Whiff of This Guy":   return new sniff_meta("Good Whiff", "", 0, 0);
		case "Gallapagosian Mating Call":      return new sniff_meta("Mating Call", "", 0, 0);
		case "Offer Latte to Opponent":        return new sniff_meta("Latte", "_latteCopyUsed", 1, 30);
		case "Be Superficially interested":    return new sniff_meta("Superficial", "", 0, 80);
		case "Staff of the Cream of the Cream": return new sniff_meta("Cream Jiggle", "", 0, 0);
		case "Make Friends":                   return new sniff_meta("Make Friends", "", 0, 0);
		case "Curse of Stench":                return new sniff_meta("Curse of Stench", "", 0, 0);
		case "Long Con":                       return new sniff_meta("Long Con", "_longConUsed", 5, 0);
		case "Perceive Soul":                  return new sniff_meta("Perceive Soul", "", 0, 30);
		case "Motif":                          return new sniff_meta("Motif", "", 0, 0);
		case "Monkey Point":                   return new sniff_meta("Monkey Point", "", 0, 0);
		case "prank Crimbo card":              return new sniff_meta("Prank Card", "", 0, 100);
		case "trick coin":                     return new sniff_meta("Trick Coin", "", 0, 100);
		case "Hunt":                           return new sniff_meta("Hunt", "", 0, 0);
		case "McHugeLarge Slash":              return new sniff_meta("McHugeLarge Slash", "_mcHugeLargeSlashUses", 3, 0);
		case "Meat Cute":                      return new sniff_meta("Meat Cute", "_meatCuteUsed", 5, 0);
		case "Try to Remember":                return new sniff_meta("Try to Remember", "", 0, 0);
		case "Left %n Kick":                   return new sniff_meta("Left Zoot Kick", "", 0, 0);
		case "Right %n Kick":                  return new sniff_meta("Right Zoot Kick", "", 0, 0);
		case "Baseball Diamond":
		case "Some Cheddar":                   return new sniff_meta("Some Cheddar", "_baseballInnings", 3, 0);
		case "Red-Nosed Snapper":              return new sniff_meta("Red Snapper", "", 0, 0);
		case "A Beastly Odor":                 return new sniff_meta("Beastly Odor", "", 0, 0);
		case "Ew, The Humanity":               return new sniff_meta("Ew, The Humanity", "", 0, 0);
	}
	return new sniff_meta(method, "", 0, 0);
}

// Icon (itemimages/*.gif): the matching skill / item / effect image, with a
// couple of hand-picks and the Olfaction snout as the generic fallback.
string sniffImage(string method) {
	switch(method) {
		case "Baseball Diamond":
		case "Some Cheddar": return "bdiamond.gif";
	}
	skill sk = to_skill(method);
	if(sk != $skill[none] && sk.image != "") return sk.image;
	item it = to_item(method);
	if(it != $item[none] && it.image != "") return it.image;
	effect ef = to_effect(method);
	if(ef != $effect[none] && ef.image != "") return ef.image;
	familiar fa = to_familiar(method);
	if(fa != $familiar[none] && fa.image != "") return fa.image;
	return "snout.gif";
}

void parseTracked(string raw, boolean isPhylum, sniff_entry[int] out, boolean[string] seen) {
	if(raw == "") return;
	string[int] f = split_string(raw, ":");
	int n = f.count();
	int i = 0;
	while(i + 2 < n) {
		if(f[i] != "" && f[i + 1] != "") {
			out[out.count()] = new sniff_entry(f[i], f[i + 1], f[i + 2].to_int(), isPhylum);
			seen[f[i + 1]] = true;
		}
		i += 3;
	}
}

sniff_entry[int] activeSniffs() {
	sniff_entry[int] out;
	boolean[string] seen;

	parseTracked(get_property("trackedMonsters"), false, out, seen);
	parseTracked(get_property("trackedPhyla"), true, out, seen);

	// On the Trail survives rollover; show it even if the pref entry is missing.
	if(have_effect($effect[On the Trail]) > 0 && !(seen contains "Transcendent Olfaction")) {
		string olf = get_property("olfactedMonster");
		if(olf != "")
			out[out.count()] = new sniff_entry(olf, "Transcendent Olfaction", my_turncount(), false);
	}

	return out;
}

// Right-hand cell: turns left for the turn-limited trackers, else casts left /
// daily cap, else infinity.
string sniffBudgetCell(sniff_entry s) {
	sniff_meta m = sniffMeta(s.method);

	if(m.turnDuration > 0) {
		int left = (s.setTurn + m.turnDuration) - my_turncount();
		if(left < 0) left = 0;
		return '<td class="right" title="expires turn ' + (s.setTurn + m.turnDuration) + '">' + left + 't</td>';
	}
	if(m.castCap > 0) {
		int used = get_property(m.castPref).to_int();
		int left = m.castCap - used;
		if(left < 0) left = 0;
		return '<td class="right" title="' + used + ' of ' + m.castCap + ' cast today">' + left + '/' + m.castCap + '</td>';
	}
	return '<td class="right infinity" title="no daily limit">&infin;</td>';
}

void bakeSniffs() {
	sniff_entry[int] sniffs = activeSniffs();

	buffer result;
	result.brickStart('Sniffs', 'sniffs', '3'); // icon + info + budget

	if(sniffs.count() == 0) {
		result.append('<tr><td class="info" colspan="3">No monsters sniffed.</td></tr>');
	} else {
		foreach i, s in sniffs {
			result.append('<tr class="effect" title="');
			result.append(s.method + ' &mdash; set on turn ' + s.setTurn);
			result.append('"><td class="icon"><img src="');
			result.append(itemimage(sniffImage(s.method)));
			result.append('"></td><td class="info">');
			result.append(sniffMeta(s.method).label);
			result.append('<br><span class="efmods">');
			result.append(s.phylum ? s.target + ' (phylum)' : s.target);
			result.append('</span></td>');
			result.append(sniffBudgetCell(s));
			result.append('</tr>');
		}
	}

	result.brickFinish();

	chitTools["sniffs"] = (sniffs.count() == 0 ? "No monsters sniffed" : "Sniffed monsters") + "|sniffs.gif";
}
