// CHaracter Info Toolbox - sniff tracker brick
//
// KoLmafia keeps *every* active monster-tracking effect ("sniff") in one
// preference, trackedMonsters, as colon-joined <monster>:<method>:<turn>
// triples - not just Transcendent Olfaction. This brick surfaces all of them;
// chit_effectInfo.ash still shows On the Trail inline with the other effects.

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
		case "Nosy Nose": return "Nosy Nose";
		case "McHugeLarge Slash": return "McHugeLarge Slash";
		case "Baseball Diamond": return "Baseball";
		case "Offer Latte to Opponent": return "Latte";
		case "Perceived Sphere": return "Perceived Sphere";
		case "Get a Good Whiff of This Guy": return "Good Whiff";
		case "Show Your Boring Familiar Pictures": return "Boring Pictures";
		case "motif": return "Motif";
	}
	return method;
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
	result.brickStart('Sniffs', 'sniffs');

	if(sniffs.count() == 0) {
		result.tagStart('tr');
		result.tagStart('td', attrmap { 'class': 'info' });
		result.append('No monsters sniffed.');
		result.tagFinish('td');
		result.tagFinish('tr');
	} else {
		foreach i, s in sniffs {
			result.tagStart('tr');
			result.tagStart('td', attrmap {
				'class': 'info',
				'title': s.method + ' - set on turn ' + s.setTurn,
			});
			result.append('<b>');
			result.append(s.monster);
			result.append('</b> &mdash; ');
			result.append(sniffLabel(s.method));
			result.tagFinish('td');
			result.tagFinish('tr');
		}
	}

	result.brickFinish();

	chitTools["sniffs"] = (sniffs.count() == 0 ? "No monsters sniffed" : "Sniffed monsters") + "|trail.png";
}
