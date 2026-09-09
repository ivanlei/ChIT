// CHaracter Info Toolbox - summon & copy brick
//
// Inventory copies you actively use to jump straight into a fight: fax, Spooky
// Putty, Rain-Doh, 4-D / crappy cameras, print screen button, ice sculpture,
// wax monster, envyfish egg, and Chest Mimic eggs. One row per copy you're
// currently holding, styled like an Effects row. (Monsters that turn up on
// their own as wanderers are in the separate Wandering Monsters brick.)
//
// Shares monsterQueueRow() with chit_brickWanderers.ash (imported first).

record copy_src {
	string label;
	string monsterPref;   // pref holding the copied monster name
	string madePref;      // copies-made-today counter ("" = none)
	int madeCap;          // daily copy cap for madePref (0 = none)
	string image;         // itemimages/*.gif
};

copy_src[int] copySources() {
	copy_src[int] s;
	s[s.count()] = new copy_src("Fax", "photocopyMonster", "", 0, "photocopy.gif");
	s[s.count()] = new copy_src("Spooky Putty", "spookyPuttyMonster", "spookyPuttyCopiesMade", 5, "sputtycopy.gif");
	s[s.count()] = new copy_src("Rain-Doh", "rainDohMonster", "_raindohCopiesMade", 5, "raindohbox.gif");
	s[s.count()] = new copy_src("4-D Camera", "cameraMonster", "", 0, "camera.gif");
	s[s.count()] = new copy_src("Crappy Camera", "crappyCameraMonster", "", 0, "camera.gif");
	s[s.count()] = new copy_src("Print Screen", "screencappedMonster", "", 0, "printscreen.gif");
	s[s.count()] = new copy_src("Ice Sculpture", "iceSculptureMonster", "", 0, "icesculpt2.gif");
	s[s.count()] = new copy_src("Wax Monster", "waxMonster", "", 0, "waxlips.gif");
	s[s.count()] = new copy_src("Envyfish Egg", "envyfishMonster", "", 0, "roe.gif");
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

string copySub(copy_src src, string mon) {
	if(src.madePref == "" || src.madeCap == 0) return mon;
	return mon + ' &middot; ' + get_property(src.madePref).to_int() + '/' + src.madeCap + ' made';
}

void bakeSummonCopy() {
	buffer result;
	result.brickStart('Summon &amp; Copy', 'summoncopy', '3');

	int rows = 0;
	foreach i, src in copySources() {
		string mon = get_property(src.monsterPref);
		if(mon == "") continue;
		result.append(monsterQueueRow(src.label, copySub(src, mon), src.image,
			'<td class="right" title="copy ready to fight">copy</td>'));
		rows += 1;
	}
	foreach mon, eggs in mimicEggMonsters() {
		result.append(monsterQueueRow("Mimic Egg", mon, "mimicegg.gif",
			'<td class="right" title="hatch this monster from one of your mimic eggs">' + eggs + 'x</td>'));
		rows += 1;
	}

	if(rows == 0)
		result.append('<tr><td class="info" colspan="3">No copies in hand.</td></tr>');

	result.brickFinish();

	chitTools["summoncopy"] = (rows == 0 ? "No monster copies" : "Monster copies in hand") + "|summoncopy.gif";
}
