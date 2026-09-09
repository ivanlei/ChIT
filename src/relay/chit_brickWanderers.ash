// CHaracter Info Toolbox - wandering-monster / copier brick
//
// Skills and items that queue a specific monster to fight again - either as a
// forced wandering encounter (Recall Facts: Monster Habitats, Be Gregarious,
// Digitize, romantic arrow, Enamorang, Club 'Em Into Next Week) or as a copy
// you spend later (fax, Spooky Putty, Rain-Doh, cameras, VHS tape, ...). One
// row per source that currently has a monster stored, styled like an Effects
// row with the monster in grey and its remaining fights / return turn / copy
// state on the right.

record wander_src {
	string label;
	string monsterPref;   // pref holding the stored monster name
	string countPref;     // fights-left pref ("" = none)
	string turnPref;      // my_turncount() when it returns ("" = none)
	string image;         // itemimages/*.gif
	boolean copy;         // true == a copy item you spend, false == forced wanderer
};

wander_src[int] wanderSources() {
	wander_src[int] s;
	// --- forced wandering encounters ---
	s[s.count()] = new wander_src("Monster Habitats", "_monsterHabitatsMonster", "_monsterHabitatsFightsLeft", "", "map.gif", false);
	s[s.count()] = new wander_src("Be Gregarious", "beGregariousMonster", "beGregariousFightsLeft", "", "happy.gif", false);
	s[s.count()] = new wander_src("Digitize", "_sourceTerminalDigitizeMonster", "", "", "watch.gif", false);
	s[s.count()] = new wander_src("Romantic Arrow", "romanticTarget", "_romanticFightsLeft", "", "obtuseangel.gif", false);
	s[s.count()] = new wander_src("Enamorang", "enamorangMonster", "", "enamorangMonsterTurn", "loveboomerang.gif", false);
	s[s.count()] = new wander_src("Club 'Em Into Next Week", "clubEmNextWeekMonster", "", "clubEmNextWeekMonsterTurn", "leg_club2.gif", false);
	// --- copies you spend later ---
	s[s.count()] = new wander_src("Fax", "photocopyMonster", "", "", "photocopy.gif", true);
	s[s.count()] = new wander_src("Spooky Putty", "spookyPuttyMonster", "", "", "sputtycopy.gif", true);
	s[s.count()] = new wander_src("Rain-Doh", "rainDohMonster", "", "", "raindohbox.gif", true);
	s[s.count()] = new wander_src("4-D Camera", "cameraMonster", "", "", "camera.gif", true);
	s[s.count()] = new wander_src("Crappy Camera", "crappyCameraMonster", "", "", "camera.gif", true);
	s[s.count()] = new wander_src("Print Screen", "screencappedMonster", "", "", "printscreen.gif", true);
	s[s.count()] = new wander_src("Spooky VHS Tape", "spookyVHSTapeMonster", "", "spookyVHSTapeMonsterTurn", "2002vhs.gif", true);
	s[s.count()] = new wander_src("Ice Sculpture", "iceSculptureMonster", "", "", "icesculpt2.gif", true);
	s[s.count()] = new wander_src("Wax Monster", "waxMonster", "", "", "waxlips.gif", true);
	s[s.count()] = new wander_src("Envyfish Egg", "envyfishMonster", "", "", "roe.gif", true);
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

string wanderRow(string label, string mon, string image, string budgetCell) {
	buffer b;
	b.append('<tr class="effect"><td class="icon"><img src="');
	b.append(itemimage(image));
	b.append('"></td><td class="info">');
	b.append(label);
	b.append('<br><span class="efmods">');
	b.append(mon);
	b.append('</span></td>');
	b.append(budgetCell);
	b.append('</tr>');
	return b.to_string();
}

string wanderBudgetCell(wander_src src) {
	if(src.countPref != "") {
		int n = get_property(src.countPref).to_int();
		if(n > 0)
			return '<td class="right" title="' + n + ' forced fight' + (n == 1 ? '' : 's') + ' left">' + n + 'x</td>';
	}
	if(src.turnPref != "") {
		int back = get_property(src.turnPref).to_int();
		if(back >= 0) {
			int t = back - my_turncount();
			if(t <= 0)
				return '<td class="right" title="due now">now</td>';
			return '<td class="right" title="returns turn ' + back + '">' + t + 't</td>';
		}
	}
	if(src.copy)
		return '<td class="right" title="copy available to fight">copy</td>';
	return '<td class="right"></td>';
}

void bakeWanderers() {
	buffer result;
	result.brickStart('Wandering Monsters', 'wanderers', '3');

	int rows = 0;
	foreach i, src in wanderSources() {
		string mon = get_property(src.monsterPref);
		if(mon == "") continue;
		result.append(wanderRow(src.label, mon, src.image, wanderBudgetCell(src)));
		rows += 1;
	}
	foreach mon, eggs in mimicEggMonsters() {
		result.append(wanderRow("Mimic Egg", mon, "mimicegg.gif",
			'<td class="right" title="Chest Mimic eggs held">' + eggs + ' egg' + (eggs == 1 ? '' : 's') + '</td>'));
		rows += 1;
	}

	if(rows == 0)
		result.append('<tr><td class="info" colspan="3">Nothing copied or queued.</td></tr>');

	result.brickFinish();

	chitTools["wanderers"] = (rows == 0 ? "No copied monsters" : "Copied / queued monsters") + "|wanderers.gif";
}
