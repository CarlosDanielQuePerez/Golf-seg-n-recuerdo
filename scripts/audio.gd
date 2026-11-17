extends Node
## Sonido y música. (Autoload "Sfx")

const SFX := ["hit", "bounce", "boing", "splash", "bubbles", "chomp", "growl", "poof",
	"sizzle", "explosion", "whoosh", "hop", "squeak", "warp", "fall", "cup", "fanfare",
	"sad", "click", "hover", "boost", "rumble", "cheer", "fuse", "tick", "pickup", "spring", "magnet", "portal", "bigboom", "muffled"]

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var current_track := ""
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_bus("Music")
	_make_bus("SFX")
	for n in SFX:
		var s = load("res://assets/sfx/%s.wav" % n)
		if s:
			sounds[n] = s
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)
	music_a = AudioStreamPlayer.new()
	music_b = AudioStreamPlayer.new()
	for m in [music_a, music_b]:
		m.bus = "Music"
		m.volume_db = -80
		add_child(m)
	set_volumes(Game.settings.music, Game.settings.sfx)


func _make_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


var fuse_player: AudioStreamPlayer


## Sonido continuo de la mecha encendida.
func fuse(on: bool, pitch := 1.0) -> void:
	if fuse_player == null:
		fuse_player = AudioStreamPlayer.new()
		fuse_player.bus = "SFX"
		fuse_player.volume_db = -10.0
		add_child(fuse_player)
		var s = sounds.get("fuse")
		if s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
		fuse_player.stream = s
	fuse_player.pitch_scale = pitch
	if on and not fuse_player.playing:
		fuse_player.play()
	elif not on and fuse_player.playing:
		fuse_player.stop()


func set_volumes(music: float, sfx: float) -> void:
	var mi := AudioServer.get_bus_index("Music")
	var si := AudioServer.get_bus_index("SFX")
	if mi >= 0:
		AudioServer.set_bus_volume_db(mi, linear_to_db(maxf(music, 0.0001)))
	if si >= 0:
		AudioServer.set_bus_volume_db(si, linear_to_db(maxf(sfx, 0.0001)))


func play(sound: String, pitch_var := 0.08, volume_db := 0.0, pitch := 1.0) -> void:
	if not sounds.has(sound):
		return
	var p: AudioStreamPlayer = null
	for pl in players:
		if not pl.playing:
			p = pl
			break
	if p == null:
		p = players[randi() % players.size()]
	p.stream = sounds[sound]
	p.pitch_scale = maxf(0.1, pitch + randf_range(-pitch_var, pitch_var))
	p.volume_db = volume_db
	p.play()


func music(track: String) -> void:
	if track == current_track:
		return
	current_track = track
	var stream = load("res://assets/music/%s.wav" % track)
	if stream == null:
		return
	if stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	# crossfade entre los dos reproductores
	var old := music_a
	var new := music_b
	if music_b.playing and music_b.volume_db > music_a.volume_db:
		old = music_b
		new = music_a
	new.stream = stream
	new.volume_db = -40
	new.play()
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(new, "volume_db", 0.0, 1.0)
	_music_tween.tween_property(old, "volume_db", -60.0, 1.0)
	_music_tween.chain().tween_callback(old.stop)


func music_pitch(p: float) -> void:
	music_a.pitch_scale = p
	music_b.pitch_scale = p
