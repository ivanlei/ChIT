// CHaracter Info Toolbox - wandering-monster / copier brick
//
// Skills and items that queue a specific monster to fight again - either as a
// forced wandering encounter (Recall Facts: Monster Habitats, Be Gregarious,
// Digitize, romantic arrow, Enamorang, Club 'Em Into Next Week) or as a copy
// you spend later (fax, Spooky Putty, Rain-Doh, cameras, VHS tape, Chest Mimic
// eggs, ...). One row per source that currently has a monster stored, styled
// like an Effects row: the monster (and casts left today) in grey, and forced
// fights left / turns until it wanders / copy state on the right.

record wander_src {
	string label;
	string monsterPref;   // pref holding the stored monster name
	string countPref;     // forced-fights-left pref ("" = none)
	string turnPref;      // total_turns_played() when the wanderer becomes due ("" = none)
	string castPref;      // daily-uses pref ("" = no fixed cap)
	int castCap;          // daily cast cap; 0 with a castPref means "show N used"
	string image;         // itemimages/*.gif
	boolean copy;         // true = a copy item you spend, false = forced wanderer
};

wander_src[int] wanderSources() {
	wander_src[int] s;
	// --- forced wandering encounters ---
	s[s.count()] = new wander_src("Monster Habitats", "_monsterHabitatsMonster", "_monsterHabitatsFightsLeft", "", "_monsterHabitatsRecalled", 3, "map.gif", false);
	s[s.count()] = new wander_src("Be Gregarious", "beGregariousMonster", "beGregariousFightsLeft", "", "", 0, "happy.gif", false);
	s[s.count()] = new wander_src("Digitize", "_sourceTerminalDigitizeMonster", "", "", "_sourceTerminalDigitizeUses", 0, "watch.gif", false);
	s[s.count()] = new wander_src("Romantic Arrow", "romanticTarget", "_romanticFightsLeft", "", "_badlyRomanticArrows", 1, "obtuseangel.gif", false);
	s[s.count()] = new wander_src("Enamorang", "enamorangMonster", "", "enamorangMonsterTurn", "_enamorangs", 0, "loveboomerang.gif", false);
	s[s.count()] = new wander_src("Club 'Em Into Next Week", "clubEmNextWeekMonster", "", "clubEmNextWeekMonsterTurn", "_clubEmNextWeekUsed", 5, "leg_club2.gif", false);
	// --- copies you spend later ---
	s[s.count()] = new wander_src("Fax", "photocopyMonster", "", "", "", 0, "photocopy.gif", true);
	s[s.count()] = new wander_src("Spooky Putty", "spookyPuttyMonster", "", "", "", 0, "sputtycopy.gif", true);
	s[s.count()] = new wander_src("Rain-Doh", "rainDohMonster", "", "", "", 0, "raindohbox.gif", true);
	s[s.count()] = new wander_src("4-D Camera", "cameraMonster", "", "", "", 0, "camera.gif", true);
	s[s.count()] = new wander_src("Crappy Camera", "crappyCameraMonster", "", "", "", 0, "camera.gif", true);
	s[s.count()] = new wander_src("Print Screen", "screencappedMonster", "", "", "", 0, "printscreen.gif", true);
	s[s.count()] = new wander_src("Spooky VHS Tape", "spookyVHSTapeMonster", "", "spookyVHSTapeMonsterTurn", "", 0, "2002vhs.gif", true);
	s[s.count()] = new wander_src("Ice Sculpture", "iceSculptureMonster", "", "", "", 0, "icesculpt2.gif", true);
	s[s.count()] = new wander_src("Wax Monster", "waxMonster", "", "", "", 0, "waxlips.gif", true);
	s[s.count()] = new wander_src("Envyfish Egg", "envyfishMonster", "", "", "", 0, "roe.gif", true);
	return s;
}

// mimicEggMonsters is a comma-joined list of <monsterId>:<eggs> pairs - the
// Chest Mimic eggs you're holding. Returns monster-name -> egg count.
int[string] mimicEggMonsters() {
	int[string] out;
	string raw = get_property("mimicEggMonsters");
	if(raw == "") return out;
	foreach i, pair in split_string(raw, "\\s*,\\s*") {
		string[int] p = split_string(pair, ":");
		if(p.count() < 1) continue;
		monster m = to_monster(p[0].to_int());
		if(m == $monster[none]) continue;
		out[m.name] = p.count() > 1 ? p[1].to_int() : 1;
	}
	return out;
}

// grey sub-line: the monster, plus casts left today when the source has a cap.
string wanderSub(wander_src src, string mon) {
	if(src.castPref == "") return mon;
	int used = get_property(src.castPref).to_int();
	if(src.castCap > 0) {
		int left = src.castCap - used;
		if(left < 0) left = 0;
		return mon + ' &middot; ' + left + ' left today';
	}
	if(used > 0)
		return mon + ' &middot; used ' + used + 'x';
	return mon;
}

// right cell: forced fights left, else turns until it wanders, else copy state.
string wanderBudgetCell(wander_src src) {
	if(src.countPref != "") {
		int n = get_property(src.countPref).to_int();
		if(n > 0)
			return '<td class="right" title="' + n + ' forced fight' + (n == 1 ? '' : 's') + ' left">' + n + 'x</td>';
	}
	if(src.turnPref != "") {
		int due = get_property(src.turnPref).to_int();
		if(due > 0) {
			int t = due - total_turns_played();
			if(t <= 0)
				return '<td class="right" title="ready to wander in now">due</td>';
			return '<td class="right" title="wanders in about ' + t + ' turn' + (t == 1 ? '' : 's') + '">' + t + 't</td>';
		}
	}
	if(src.copy)
		return '<td class="right" title="copy available to fight">copy</td>';
	return '<td class="right"></td>';
}

string wanderRow(string label, string sub, string image, string budgetCell) {
	buffer b;
	b.append('<tr class="effect"><td class="icon"><img src="');
	b.append(itemimage(image));
	b.append('"></td><td class="info">');
	b.append(label);
	b.append('<br><span class="efmods">');
	b.append(sub);
	b.append('</span></td>');
	b.append(budgetCell);
	b.append('</tr>');
	return b.to_string();
}

void bakeWanderers() {
	buffer result;
	result.brickStart('Wandering Monsters', 'wanderers', '3');

	int rows = 0;
	foreach i, src in wanderSources() {
		string mon = get_property(src.monsterPref);
		if(mon == "") continue;
		result.append(wanderRow(src.label, wanderSub(src, mon), src.image, wanderBudgetCell(src)));
		rows += 1;
	}
	foreach mon, eggs in mimicEggMonsters() {
		result.append(wanderRow("Mimic Egg", mon, "mimicegg.gif",
			'<td class="right" title="hatch this monster from one of your mimic eggs">' + eggs + 'x</td>'));
		rows += 1;
	}

	if(rows == 0)
		result.append('<tr><td class="info" colspan="3">Nothing copied or queued.</td></tr>');

	result.brickFinish();

	chitTools["wanderers"] = (rows == 0 ? "No copied monsters" : "Copied / queued monsters") + "|wanderers.gif";
}
