// CHaracter Info Toolbox - sniff tracker brick
//
// KoLmafia keeps *every* active monster-tracking effect ("sniff") in one
// preference, trackedMonsters, as colon-joined <monster>:<method>:<turn>
// triples - not just Transcendent Olfaction. This brick surfaces all of them,
// styled like an effect row in the Effects brick (icon + name + grey monster).

record sniff_entry {
	string monster;
	string method;
	int setTurn;
};

// A shorter label for a trackedMonsters method string. Unknown methods fall
// through to the raw name (which mafia already writes readably).
string sniffLabel(string method) {
	switch(method) {
		case "Transcendent Olfaction": return "On the Trail";
		case "Gallapagosian Mating Call": return "Mating Call";
		case "Long Con": return "Long Con";
		case "Nosy Nose":
		case "Get a Good Whiff of This Guy": return "Good Whiff";
		case "McHugeLarge Slash": return "McHugeLarge Slash";
		case "Baseball Diamond":
		case "Some Cheddar": return "Baseball";
		case "Offer Latte to Opponent": return "Latte";
		case "Perceived Sphere": return "Perceived Sphere";
		case "Show Your Boring Familiar Pictures": return "Boring Pictures";
		case "motif": return "Motif";
	}
	return method;
}

// Icon (itemimages/*.gif) for a method: the matching skill's icon where there
// is one, a hand-picked image for the non-skill trackers, else the Olfaction
// snout as a generic "sniff" glyph.
string sniffImage(string method) {
	switch(method) {
		case "Baseball Diamond":
		case "Some Cheddar": return "bdiamond.gif";
	}
	skill s = to_skill(method);
	if(s != $skill[none] && s.image != "")
		return s.image;
	return "snout.gif";
}

sniff_entry[int] activeSniffs() {
	sniff_entry[int] out;
	boolean[string] methodsSeen;

	string raw = get_property("trackedMonsters");
	if(raw != "") {
		string[int] f = split_string(raw, ":");
		int n = f.count();
		int i = 0;
		while(i + 2 < n) {
			string mon = f[i];
			string method = f[i + 1];
			if(mon != "" && method != "") {
				out[out.count()] = new sniff_entry(mon, method, f[i + 2].to_int());
				methodsSeen[method] = true;
			}
			i += 3;
		}
	}

	// On the Trail survives rollover; show it even if the trackedMonsters entry
	// isn't there for some reason.
	if(have_effect($effect[On the Trail]) > 0 && !(methodsSeen contains "Transcendent Olfaction")) {
		string olf = get_property("olfactedMonster");
		if(olf != "")
			out[out.count()] = new sniff_entry(olf, "Transcendent Olfaction", my_turncount());
	}

	return out;
}

void bakeSniffs() {
	sniff_entry[int] sniffs = activeSniffs();

	buffer result;
	result.brickStart('Sniffs', 'sniffs', '2'); // 2 columns: icon + info

	if(sniffs.count() == 0) {
		result.append('<tr><td class="info">No monsters sniffed.</td></tr>');
	} else {
		foreach i, s in sniffs {
			result.append('<tr class="effect" title="');
			result.append(s.method + ' &mdash; set on turn ' + s.setTurn);
			result.append('"><td class="icon"><img src="');
			result.append(itemimage(sniffImage(s.method)));
			result.append('"></td><td class="info">');
			result.append(sniffLabel(s.method));
			result.append('<br><span class="efmods">');
			result.append(s.monster);
			result.append('</span></td></tr>');
		}
	}

	result.brickFinish();

	chitTools["sniffs"] = (sniffs.count() == 0 ? "No monsters sniffed" : "Sniffed monsters") + "|trail.png";
}
