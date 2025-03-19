extends Label

var tick = 0;
var num_ticks = 5;

func _ready() -> void:
	Signals.players_ready.connect(start);
	$timer.connect("timeout", count);

func start() -> void:
	if $timer.is_stopped():
		self.tick = 0;
		text = "Starting in " + str(self.num_ticks) + "...";
		$timer.start();

func count() -> void:
	self.tick += 1;
	if self.tick == self.num_ticks:
		text = "";
		$timer.stop();
	else:
		text = "Starting in " + str(self.num_ticks - self.tick) + "...";
